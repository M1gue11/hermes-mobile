"""Fundamento offline. Nenhum transporte real ou scheduler."""
import json
import sqlite3
import time
import unicodedata
import uuid
from contextlib import contextmanager
from dataclasses import dataclass
from typing import Protocol

MAX_TIME = 2**63 - 1
REQUIRED = {'version', 'event_id', 'dedupe_key', 'source', 'destination', 'category',
            'severity', 'title', 'safe_summary', 'created_at_ms', 'sensitivity'}
OPTIONAL = {'expires_at_ms', 'conversation_id'}


def integer(value, low=0, high=MAX_TIME):
    if type(value) is not int or not low <= value <= high:
        raise ValueError('inteiro fora do limite')
    return value


def string(value, limit):
    if not isinstance(value, str) or not value.strip() or len(value) > limit:
        raise ValueError('string inválida')
    if any(unicodedata.category(c).startswith('C') for c in value):
        raise ValueError('caractere de controle proibido')
    return value


@dataclass(frozen=True)
class Envelope:
    version: int
    event_id: str
    dedupe_key: str
    source: str
    destination: str
    category: str
    severity: str
    title: str
    safe_summary: str
    created_at_ms: int
    sensitivity: str
    expires_at_ms: int | None = None
    conversation_id: str | None = None

    @classmethod
    def parse(cls, data):
        if type(data) is not dict or not REQUIRED <= data.keys() or data.keys() - REQUIRED - OPTIONAL:
            raise ValueError('schema inválido: campo ausente ou desconhecido')
        integer(data['version'], 1, 1)
        for key in ('event_id', 'dedupe_key', 'source', 'destination', 'category'):
            string(data[key], 256)
        string(data['title'], 160)
        string(data['safe_summary'], 1000)
        if data['severity'] not in ('info', 'success', 'warning', 'error'):
            raise ValueError('severity inválida')
        if data['sensitivity'] not in ('public', 'private'):
            raise ValueError('sensitivity inválida')
        integer(data['created_at_ms'])
        expiry = data.get('expires_at_ms')
        if expiry is not None:
            integer(expiry, data['created_at_ms'])
        if data.get('conversation_id') is not None:
            string(data['conversation_id'], 256)
        return cls(**data)

    def canonical(self):
        return json.dumps(self.__dict__, sort_keys=True, ensure_ascii=True, separators=(',', ':'))


@dataclass(frozen=True)
class PushDTO:
    event_id: str
    category: str
    severity: str
    message: str = 'Há um novo aviso'


class Adapter(Protocol):
    # Implementação remota futura DEVE deduplicar event_id; accepted != delivered.
    def send(self, notice: PushDTO) -> None: ...


class TransientFailure(Exception):
    pass


class PermanentFailure(Exception):
    pass


@dataclass(frozen=True)
class Claim:
    event_id: str
    token: str
    notice: PushDTO


class Store:
    def __init__(self, path, clock=None, max_attempts=3, retry_ms=1000, cap_ms=60000):
        self.clock = clock or (lambda: time.time_ns() // 1_000_000)
        self.max_attempts = integer(max_attempts, 1, 100)
        self.retry_ms = integer(retry_ms, 1, 60000)
        self.cap_ms = integer(cap_ms, self.retry_ms, 86400000)
        self.db = sqlite3.connect(path, isolation_level=None, timeout=5)
        self.db.row_factory = sqlite3.Row
        self.db.execute('PRAGMA foreign_keys=ON')
        self.db.executescript('''
        CREATE TABLE IF NOT EXISTS events (
          event_id TEXT PRIMARY KEY, source TEXT NOT NULL, destination TEXT NOT NULL,
          dedupe_key TEXT NOT NULL, payload TEXT NOT NULL, expiry INTEGER,
          UNIQUE(source,destination,dedupe_key));
        CREATE TABLE IF NOT EXISTS inbox (
          event_id TEXT PRIMARY KEY REFERENCES events, read_ms INTEGER, ack_ms INTEGER);
        CREATE TABLE IF NOT EXISTS outbox (
          event_id TEXT PRIMARY KEY REFERENCES events, state TEXT NOT NULL,
          attempts INTEGER NOT NULL DEFAULT 0, next_ms INTEGER NOT NULL,
          token TEXT, lease_ms INTEGER);
        CREATE TABLE IF NOT EXISTS audit (
          seq INTEGER PRIMARY KEY, event_id TEXT NOT NULL REFERENCES events,
          kind TEXT NOT NULL, at_ms INTEGER NOT NULL);
        CREATE TRIGGER IF NOT EXISTS audit_no_update BEFORE UPDATE ON audit
          BEGIN SELECT RAISE(ABORT,'audit imutável'); END;
        CREATE TRIGGER IF NOT EXISTS audit_no_delete BEFORE DELETE ON audit
          BEGIN SELECT RAISE(ABORT,'audit imutável'); END;
        CREATE TRIGGER IF NOT EXISTS events_no_update BEFORE UPDATE ON events
          BEGIN SELECT RAISE(ABORT,'evento imutável'); END;
        CREATE TRIGGER IF NOT EXISTS events_no_delete BEFORE DELETE ON events
          BEGIN SELECT RAISE(ABORT,'evento imutável'); END;
        ''')

    def close(self):
        self.db.close()

    def now(self):
        return integer(self.clock())

    @contextmanager
    def transaction(self):
        self.db.execute('BEGIN IMMEDIATE')
        try:
            yield
            self.db.execute('COMMIT')
        except BaseException:
            self.db.execute('ROLLBACK')
            raise

    def audit(self, event_id, kind, now):
        self.db.execute('INSERT INTO audit(event_id,kind,at_ms) VALUES(?,?,?)',
                        (event_id, kind, now))

    def ingest(self, data):
        event = Envelope.parse(data)
        with self.transaction():
            rows = self.db.execute('''SELECT * FROM events WHERE event_id=? OR
                (source=? AND destination=? AND dedupe_key=?)''',
                (event.event_id, event.source, event.destination, event.dedupe_key)).fetchall()
            if rows:
                # Semantic replay may have another id, but every other field must match.
                for row in rows:
                    original = Envelope.parse(json.loads(row['payload']))
                    candidate = dict(event.__dict__)
                    if row['event_id'] != event.event_id:
                        candidate['event_id'] = original.event_id
                    if Envelope.parse(candidate) != original:
                        raise ValueError('conflito de identidade ou dedupe')
                if len(rows) != 1:
                    raise ValueError('conflito de identidades cruzadas')
                return original, False
            now = self.now()
            self.db.execute('INSERT INTO events VALUES(?,?,?,?,?,?)',
                            (event.event_id, event.source, event.destination,
                             event.dedupe_key, event.canonical(), event.expires_at_ms))
            self.db.execute('INSERT INTO inbox(event_id) VALUES(?)', (event.event_id,))
            self.db.execute('INSERT INTO outbox(event_id,state,next_ms) VALUES(?,?,?)',
                            (event.event_id, 'pending', now))
            self.audit(event.event_id, 'ingested', now)
            return event, True

    def _expire(self, now):
        rows = self.db.execute('''SELECT o.event_id FROM outbox o JOIN events e USING(event_id)
            WHERE e.expiry<=? AND o.state IN ('pending','leased')''', (now,)).fetchall()
        for row in rows:
            self.db.execute("UPDATE outbox SET state='expired',token=NULL,lease_ms=NULL WHERE event_id=?",
                            (row['event_id'],))
            self.audit(row['event_id'], 'expired', now)
        return len(rows)

    def expire(self):
        with self.transaction():
            return self._expire(self.now())

    def claim(self, lease_ms=30000):
        integer(lease_ms, 1, 86400000)
        with self.transaction():
            now = self.now()
            integer(now + lease_ms)
            self._expire(now)
            exhausted = self.db.execute('''SELECT event_id FROM outbox WHERE attempts>=?
                AND (state='pending' OR (state='leased' AND lease_ms<=?))''',
                (self.max_attempts, now)).fetchall()
            for row in exhausted:
                self.db.execute("UPDATE outbox SET state='failed',token=NULL,lease_ms=NULL WHERE event_id=?",
                                (row['event_id'],))
                self.audit(row['event_id'], 'exhausted', now)
            row = self.db.execute('''SELECT e.payload FROM events e JOIN outbox o USING(event_id)
                WHERE o.attempts<? AND ((o.state='pending' AND o.next_ms<=?) OR
                (o.state='leased' AND o.lease_ms<=?)) ORDER BY o.next_ms,e.event_id LIMIT 1''',
                (self.max_attempts, now, now)).fetchone()
            if row is None:
                return None
            event = Envelope.parse(json.loads(row['payload']))
            token = uuid.uuid4().hex
            self.db.execute("UPDATE outbox SET state='leased',attempts=attempts+1,token=?,lease_ms=? WHERE event_id=?",
                            (token, now + lease_ms, event.event_id))
            self.audit(event.event_id, 'claimed', now)
            return Claim(event.event_id, token, PushDTO(event.event_id, event.category, event.severity))

    def valid(self, claim):
        with self.transaction():
            now = self.now()
            self._expire(now)
            return self.db.execute('''SELECT 1 FROM outbox WHERE event_id=? AND token=?
                AND state='leased' AND lease_ms>?''', (claim.event_id, claim.token, now)).fetchone() is not None

    def finish(self, claim, outcome):
        if outcome not in ('accepted', 'transient', 'permanent'):
            raise ValueError('resultado inválido')
        with self.transaction():
            now = self.now()
            self._expire(now)
            row = self.db.execute('''SELECT attempts FROM outbox WHERE event_id=? AND token=?
                AND state='leased' AND lease_ms>?''', (claim.event_id, claim.token, now)).fetchone()
            if row is None:
                return False
            state = 'accepted' if outcome == 'accepted' else 'failed'
            delay = 0
            if outcome == 'transient' and row['attempts'] < self.max_attempts:
                state = 'pending'
                delay = min(self.cap_ms, self.retry_ms * 2**(row['attempts'] - 1))
            next_ms = min(MAX_TIME, now + delay)
            self.db.execute('''UPDATE outbox SET state=?,next_ms=?,token=NULL,lease_ms=NULL
                WHERE event_id=? AND token=? AND state='leased' ''',
                (state, next_ms, claim.event_id, claim.token))
            self.audit(claim.event_id, outcome, now)
            return True

    def send_claim(self, claim, adapter):
        if not self.valid(claim):
            return False
        # Fora de transação. Crash após send pode repetir; nenhuma exactly-once remota.
        try:
            adapter.send(claim.notice)
        except PermanentFailure:
            outcome = 'permanent'
        except TransientFailure:
            outcome = 'transient'
        except Exception:
            # Não persistir exceção bruta. Falha desconhecida fica sujeita a retry limitado.
            outcome = 'transient'
        else:
            outcome = 'accepted'
        return self.finish(claim, outcome)

    def mark(self, event_id, kind):
        if kind not in ('read', 'ack'):
            raise ValueError('operação inválida')
        with self.transaction():
            now = self.now()
            column = 'read_ms' if kind == 'read' else 'ack_ms'
            cursor = self.db.execute(f'UPDATE inbox SET {column}=? WHERE event_id=? AND {column} IS NULL',
                                     (now, event_id))
            if cursor.rowcount:
                self.audit(event_id, kind, now)
            return bool(cursor.rowcount)

    def list_inbox(self):
        return [dict(row) for row in self.db.execute('''SELECT e.payload,i.read_ms,i.ack_ms
            FROM events e JOIN inbox i USING(event_id) ORDER BY e.event_id''')]

    def status(self):
        return {'transport': 'REAL AUSENTE', 'outbox': dict(self.db.execute(
            'SELECT state,count(*) FROM outbox GROUP BY state').fetchall())}
