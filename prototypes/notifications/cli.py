"""CLI offline; criação do arquivo somente pela ação humana explícita."""
import argparse
import json
import os
from pathlib import Path
import sqlite3
import stat

from core import Store

SCRATCH = Path('/home/miguel/.hermes/cache/scratch')


def open_private(path):
    requested = Path(path)
    if not requested.is_absolute() or '..' in requested.parts:
        raise ValueError('use caminho absoluto em scratch')
    parent = requested.parent.resolve(strict=True)
    if parent != requested.parent or not parent.is_relative_to(SCRATCH.resolve(strict=True)):
        raise ValueError('path fora de scratch ou com symlink')
    flags = os.O_RDWR | os.O_NOFOLLOW
    created = False
    try:
        fd = os.open(requested, flags | os.O_CREAT | os.O_EXCL, 0o600)
        created = True
    except FileExistsError:
        fd = os.open(requested, flags)
    try:
        info = os.fstat(fd)
        if not stat.S_ISREG(info.st_mode) or info.st_nlink != 1 or info.st_uid != os.getuid() or info.st_mode & 0o077:
            raise ValueError('arquivo deve ser privado, regular e sem hardlink')
        if not created:
            # Identificador reservado do protótipo; nunca inicializar DB alheio.
            probe = sqlite3.connect(f'{requested.as_uri()}?mode=ro', uri=True)
            try:
                if probe.execute('PRAGMA application_id').fetchone()[0] != 1313821766:
                    raise ValueError('DB não pertence ao protótipo')
            finally:
                probe.close()
        store = Store(requested)
        if created:
            store.db.execute('PRAGMA application_id=1313821766')
        return store
    finally:
        os.close(fd)


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
