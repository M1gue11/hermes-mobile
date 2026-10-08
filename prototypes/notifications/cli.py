"""CLI offline; criação do arquivo somente pela ação humana explícita."""
import argparse
import ctypes
import errno
import json
import os
from pathlib import Path
import sqlite3
import stat
import tempfile

from core import Store

SCRATCH = Path('/home/miguel/.hermes/cache/scratch')


def open_private(path):
    requested = Path(path)
    if not requested.is_absolute() or '..' in requested.parts:
        raise ValueError('use caminho absoluto em scratch')
    parent = requested.parent.resolve(strict=True)
    if parent != requested.parent or not parent.is_relative_to(SCRATCH.resolve(strict=True)):
        raise ValueError('path fora de scratch ou com symlink')
    # Build privately under an unpredictable name. Publish atomically without
    # replacing anything: Linux renameat2(RENAME_NOREPLACE) rejects existing paths.
    # A crash may leave an orphan staging file; it is never adopted or deleted
    # by a later invocation. Only the complete published DB is recognized.
    if not os.path.lexists(requested):
        fd, temporary = tempfile.mkstemp(prefix='.notice-init-', dir=parent)
        staging = Path(temporary)
        try:
            _checkpoint('created')
            store = Store(staging)
            try:
                _checkpoint('schema')
                store.db.execute('PRAGMA application_id=1313821766')
                _checkpoint('identity')
            finally:
                store.close()
            os.fsync(fd)
            _checkpoint('synced')
            try:
                _publish_exclusive(staging, requested)
            except FileExistsError:
                pass  # Validate the winner; never overwrite it.
            _checkpoint('published')
        finally:
            os.close(fd)
            staging.unlink(missing_ok=True)
        directory = os.open(parent, os.O_RDONLY | os.O_DIRECTORY)
        try:
            os.fsync(directory)
            _checkpoint('directory_synced')
        finally:
            os.close(directory)
    fd = os.open(requested, os.O_RDWR | os.O_NOFOLLOW)
    try:
        info = os.fstat(fd)
        if not stat.S_ISREG(info.st_mode) or info.st_nlink != 1 or info.st_uid != os.getuid() or stat.S_IMODE(info.st_mode) != 0o600:
            raise ValueError('arquivo deve ser privado, regular e sem hardlink')
        probe = sqlite3.connect(f'{requested.as_uri()}?mode=ro', uri=True)
        try:
            if probe.execute('PRAGMA application_id').fetchone()[0] != 1313821766:
                raise ValueError('DB não pertence ao protótipo')
            # Identity alone cannot authorize repairing an incomplete schema.
            for table in ('events', 'inbox', 'outbox', 'audit'):
                probe.execute(f'SELECT * FROM {table} LIMIT 0')
        finally:
            probe.close()
        return Store(requested)
    finally:
        os.close(fd)


def _publish_exclusive(staging, requested):
    # This host-bound CLI requires Linux; fail closed if the atomic primitive
    # is unavailable. No check-then-replace fallback that can clobber a DB.
    libc = ctypes.CDLL(None, use_errno=True)
    rename = getattr(libc, 'renameat2', None)
    if rename is None:
        raise OSError(errno.ENOSYS, 'publicação exclusiva indisponível')
    rename.argtypes = [ctypes.c_int, ctypes.c_char_p, ctypes.c_int, ctypes.c_char_p, ctypes.c_uint]
    rename.restype = ctypes.c_int
    if rename(-100, os.fsencode(staging), -100, os.fsencode(requested), 1) != 0:
        code = ctypes.get_errno()
        raise OSError(code, 'publicação exclusiva rejeitada')


def _checkpoint(stage):
    """Injection seam for subprocess crash tests; no production fault switch."""


def main():
    parser = argparse.ArgumentParser(description='Offline; transporte REAL AUSENTE')
    parser.add_argument('--db', required=True)
    sub = parser.add_subparsers(dest='command', required=True)
    sub.add_parser('ingest')  # JSON via stdin; nenhum path de payload privado em logs.
    for command in ('list', 'expire', 'status'):
        sub.add_parser(command)
    for command in ('read', 'ack'):
        sub.add_parser(command).add_argument('event_id')
    args = parser.parse_args()
    store = None
    try:
        store = open_private(args.db)
        if args.command == 'ingest':
            import sys
            raw = sys.stdin.read(16385)
            if len(raw) > 16384:
                raise ValueError('JSON excede limite')
            def pairs(items):
                result = {}
                for key, value in items:
                    if key in result:
                        raise ValueError('campo duplicado')
                    result[key] = value
                return result
            event, inserted = store.ingest(json.loads(raw, object_pairs_hook=pairs))
            result = {'event_id': event.event_id, 'inserted': inserted, 'transport': 'REAL AUSENTE'}
        elif args.command == 'list':
            result = store.list_inbox()
        elif args.command in ('read', 'ack'):
            result = {'changed': store.mark(args.event_id, args.command)}
        elif args.command == 'expire':
            result = {'expired': store.expire()}
        else:
            result = store.status()
        print(json.dumps(result, ensure_ascii=True))
        return 0
    except (ValueError, OSError, sqlite3.Error):
        print('Operação local rejeitada; verifique schema e DB privado do protótipo.')
        return 2
    finally:
        if store is not None:
            store.close()


if __name__ == '__main__':
    raise SystemExit(main())
