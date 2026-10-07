"""Adapters FAKE de teste: aceitação não prova push real."""
import json
import os
from pathlib import Path
import sqlite3
import subprocess
import sys
import tempfile
import threading
import unittest

from core import Envelope, Store, TransientFailure, PermanentFailure
from cli import open_private


def fixture(**changes):
    data = dict(version=1, event_id='event-1', dedupe_key='key-1', source='producer',
                destination='inbox', category='operational', severity='info', title='Aviso',
                safe_summary='Resumo permitido pelo produtor', created_at_ms=100,
                expires_at_ms=10000, sensitivity='private')
    data.update(changes)
    return data


class CoreTests(unittest.TestCase):
    def setUp(self):
        self.assertEqual(os.environ.get('TMPDIR'), '/home/miguel/.hermes/cache/scratch')
        self.temp = tempfile.TemporaryDirectory()
        self.path = Path(self.temp.name) / 'offline.db'
        self.time = 100
        self.store = Store(self.path, lambda: self.time, retry_ms=10, cap_ms=15)

    def tearDown(self):
        self.store.close()
        self.temp.cleanup()

    def row(self):
        return self.store.db.execute('SELECT * FROM outbox').fetchone()

    def test_envelope_security(self):
        bad = [dict(version=True), dict(version=2), dict(created_at_ms=True),
               dict(created_at_ms=-1), dict(expires_at_ms=99), dict(event_id=''),
               dict(event_id='a'*257), dict(title='a'*161), dict(safe_summary='a'*1001),
               dict(source='x\n'), dict(conversation_id='x\x00'), dict(severity='urgent'),
               dict(sensitivity='secret'), dict(created_at_ms=2**63)]
        for rich in ('actions', 'urls', 'prompt', 'reasoning', 'tool_args', 'tool_results', 'schema'):
            bad.append({rich: 'forbidden'})
        for change in bad:
            with self.subTest(change=change), self.assertRaises(ValueError):
                Envelope.parse(fixture(**change))
        for invalid in ([], {}, None):
            with self.assertRaises(ValueError):
                Envelope.parse(invalid)
        event = Envelope.parse(fixture(event_id=' ID ', expires_at_ms=None))
        self.assertEqual(event.event_id, ' ID ')
        with self.assertRaises(Exception):
            event.event_id = 'changed'

    def test_dedupe_conflict_namespace(self):
        original, inserted = self.store.ingest(fixture())
        self.assertTrue(inserted)
        self.assertEqual(self.store.ingest(fixture())[0], original)
        self.assertEqual(self.store.ingest(fixture(event_id='another')),(original, False))
        for change in (dict(title='changed'), dict(event_id='another', title='changed'),
                       dict(source='other')):
            with self.assertRaises(ValueError):
                self.store.ingest(fixture(**change))
        self.store.ingest(fixture(event_id='second', source='other'))
        self.assertEqual(len(self.store.list_inbox()), 2)
        self.assertEqual(self.store.db.execute('SELECT count(*) FROM audit').fetchone()[0], 2)

    def test_rollback_all(self):
        self.store.db.execute("CREATE TRIGGER break_insert BEFORE INSERT ON outbox BEGIN SELECT RAISE(ABORT,'test'); END")
        with self.assertRaises(sqlite3.IntegrityError):
            self.store.ingest(fixture())
        for table in ('events', 'inbox', 'outbox', 'audit'):
            self.assertEqual(self.store.db.execute('SELECT count(*) FROM '+table).fetchone()[0], 0)

    def test_restart_and_crash_before_send(self):
        self.store.ingest(fixture())
        first = self.store.claim(10)
        self.store.close()
        self.store = Store(self.path, lambda: self.time)
        self.assertIsNone(self.store.claim())
        self.time = 110
        second = self.store.claim()
        self.assertEqual(second.event_id, first.event_id)
        self.assertNotEqual(second.token, first.token)
        self.assertFalse(self.store.finish(first, 'accepted'))
        self.assertEqual(self.row()['attempts'], 2)

    def test_fake_adapter_outbox_before_send_crash_after(self):
        self.store.ingest(fixture())
        seen = []
        test = self
        class TestAdapter:
            def send(self, dto):
                test.assertFalse(test.store.db.in_transaction)
                test.assertEqual(test.row()['state'], 'leased')
                test.assertEqual(len(test.store.list_inbox()), 1)
                test.assertEqual(set(dto.__dict__), {'event_id','category','severity','message'})
                test.assertEqual(dto.message, 'Há um novo aviso')
                seen.append(dto.event_id)
        first = self.store.claim(10)
        TestAdapter().send(first.notice)  # crash após send, antes de persistir accepted
        self.store.close()
        self.store = Store(self.path, lambda: self.time)
        self.time = 110
        self.assertTrue(self.store.send_claim(self.store.claim(), TestAdapter()))
        self.assertEqual(seen, ['event-1', 'event-1'])
        self.assertIsNone(self.store.list_inbox()[0]['ack_ms'])

    def test_expiry_boundary_and_end_of_lease(self):
        self.store.ingest(fixture(expires_at_ms=110))
        claim = self.store.claim(50)
        self.time = 110
        self.assertFalse(self.store.finish(claim, 'accepted'))
        self.assertEqual(self.row()['state'], 'expired')
        self.assertIsNone(self.store.claim())

    def test_expiry_before_send(self):
        self.store.ingest(fixture(expires_at_ms=100))
        self.assertIsNone(self.store.claim())
        self.assertEqual(self.row()['attempts'], 0)

    def test_retry_cap_max_attempts(self):
        self.store.ingest(fixture())
        for attempt, delay in ((1,10),(2,15),(3,0)):
            claim = self.store.claim()
            self.assertTrue(self.store.finish(claim, 'transient'))
            self.assertEqual(self.row()['attempts'], attempt)
            self.assertEqual(self.row()['next_ms'], self.time + delay)
            self.assertIsNone(self.store.claim())
            self.time += delay
        self.assertEqual(self.row()['state'], 'failed')

    def test_failure_types(self):
        for failure, state in ((TransientFailure,'pending'),(PermanentFailure,'failed')):
            with self.subTest(failure=failure):
                identifier = failure.__name__
                self.store.ingest(fixture(event_id=identifier, dedupe_key=identifier))
                class TestFailureAdapter:
                    def send(self, dto):
                        raise failure('private exception must not persist')
                claim = self.store.claim()
                self.assertTrue(self.store.send_claim(claim, TestFailureAdapter()))
                row = self.store.db.execute('SELECT state FROM outbox WHERE event_id=?',(identifier,)).fetchone()
                self.assertEqual(row[0], state)
                self.assertNotIn('private exception', str(self.store.db.execute('SELECT * FROM audit').fetchall()))

    def test_concurrent_connections_fencing(self):
        self.store.ingest(fixture())
        barrier = threading.Barrier(2)
        results = []
        errors = []
        def worker():
            other = Store(self.path, lambda: self.time)
            try:
                barrier.wait()
                results.append(other.claim(10))
            except Exception as exc:
                errors.append(type(exc).__name__)
            finally:
                other.close()
        threads = [threading.Thread(target=worker) for _ in range(2)]
        for thread in threads: thread.start()
        for thread in threads: thread.join()
        self.assertEqual(errors, [])
        claims = [claim for claim in results if claim is not None]
        self.assertEqual(len(claims), 1)
        self.time = 110
        newer = self.store.claim()
        self.assertFalse(self.store.finish(claims[0], 'accepted'))
        self.assertTrue(self.store.finish(newer, 'accepted'))

    def test_read_ack_audit_immutable(self):
        self.store.ingest(fixture())
        self.time = 105
        self.assertTrue(self.store.mark('event-1', 'read'))
        self.assertFalse(self.store.mark('event-1', 'read'))
        self.assertIsNone(self.store.list_inbox()[0]['ack_ms'])
        self.time = 106
        self.assertTrue(self.store.mark('event-1', 'ack'))
        self.assertEqual(self.store.list_inbox()[0]['read_ms'], 105)
        self.assertEqual(self.store.list_inbox()[0]['ack_ms'], 106)
        self.assertEqual(self.row()['state'], 'pending')
        for table in ('audit','events'):
            with self.assertRaises(sqlite3.IntegrityError):
                self.store.db.execute('DELETE FROM '+table)
        self.assertEqual(self.store.db.execute('SELECT count(*) FROM audit').fetchone()[0], 3)

    def test_exhausted_crashed_claim(self):
        self.store.ingest(fixture())
        for _ in range(3):
            self.assertIsNotNone(self.store.claim(1))
            self.time += 1
        self.assertIsNone(self.store.claim())
        self.assertEqual(self.row()['state'], 'failed')

    def test_expiry_during_send_and_lease_boundary(self):
        self.store.ingest(fixture(expires_at_ms=110))
        test = self
        class TestSlowAdapter:
            def send(self, dto):
                test.time = 110
        self.assertFalse(self.store.send_claim(self.store.claim(10), TestSlowAdapter()))
        self.assertEqual(self.row()['state'], 'expired')
        self.store.ingest(fixture(event_id='second', dedupe_key='second', expires_at_ms=None))
        claim = self.store.claim(10)
        self.time = 120
        self.assertFalse(self.store.finish(claim, 'accepted'))
        self.assertIsNotNone(self.store.claim())

    def test_cli_offline_commands(self):
        path = Path(self.temp.name) / 'commands.db'
        cli = Path(__file__).with_name('cli.py')
        def run(command, payload=None):
            result = subprocess.run([sys.executable, str(cli), '--db', str(path), *command],
                                    input=payload, text=True, capture_output=True)
            self.assertEqual(result.returncode, 0, result.stdout)
            return json.loads(result.stdout)
        self.assertTrue(run(['ingest'], json.dumps(fixture()))['inserted'])
        self.assertEqual(run(['status'])['transport'], 'REAL AUSENTE')
        self.assertEqual(len(run(['list'])), 1)
        self.assertTrue(run(['read', 'event-1'])['changed'])
        self.assertTrue(run(['ack', 'event-1'])['changed'])
        self.assertEqual(run(['expire'])['expired'], 1)
        rejected = subprocess.run([sys.executable, str(cli), '--db', str(path), 'ingest'],
                                 input='{"version":1,"version":1}', text=True, capture_output=True)
        self.assertEqual(rejected.returncode, 2)

    def test_private_cli_path(self):
        private = Path(self.temp.name) / 'cli.db'
        store = open_private(private)
        store.close()
        self.assertEqual(private.stat().st_mode & 0o777, 0o600)
        store = open_private(private)
        store.close()
        link = Path(self.temp.name) / 'link.db'
        link.symlink_to(private)
        with self.assertRaises(OSError): open_private(link)
        with self.assertRaises(ValueError): open_private(self.path)
        with self.assertRaises(ValueError): open_private('/tmp/foreign.db')
        private.chmod(0o644)
        with self.assertRaises(ValueError): open_private(private)


if __name__ == '__main__':
    unittest.main()
