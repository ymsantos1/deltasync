#!/usr/bin/env python3
"""Inspect closed demo database copies; never writes to the Android device."""
import argparse
import hashlib
import json
from pathlib import Path
import sqlite3
import tarfile
import tempfile


def inspect(directory):
    states, files = {}, {}
    for label in ('before-install', 'committed-offline', 'committed-restored', 'ack', 'final-verified'):
        with tempfile.TemporaryDirectory(prefix='val17-native-inspection-') as target:
            target = Path(target)
            with tarfile.open(directory/(label+'.tar')) as archive:
                archive.extractall(target, filter='data')
            databases = target/'databases'
            files[label] = {p.name: hashlib.sha256(p.read_bytes()).hexdigest()
                            for p in databases.iterdir() if p.is_file()}
            states[label] = {}
            for path in databases.glob('shopper-*.sqlite'):
                with sqlite3.connect(path) as database:
                    snapshot = json.loads(database.execute(
                        'select payload from deltasync_snapshots').fetchone()[0])['snapshot']
                    entries = [json.loads(row[0]) for row in database.execute(
                        'select payload from deltasync_outbox order by entry_id')]
                    schema = database.execute('pragma user_version').fetchone()[0]
                states[label][path.name] = dict(snapshot=snapshot, outbox=entries, schema=schema)
    assert states['committed-offline'] == states['committed-restored']
    assert states['ack'] == states['final-verified']
    a, b = states['final-verified']['shopper-a.sqlite'], states['final-verified']['shopper-b.sqlite']
    assert not a['outbox'] and not b['outbox']
    winner = a['snapshot']['lww']['shopping/title']['winner']
    assert winner == b['snapshot']['lww']['shopping/title']['winner']
    assert winner['value'].endswith('_A_restored')
    components = a['snapshot']['gCounters']['shopping/items']['components']
    assert components == b['snapshot']['gCounters']['shopping/items']['components']
    assert sum(components.values()) == 8
    previous = states['committed-restored']['shopper-a.sqlite']
    # OutboxEntry.delta stores a versioned DeltaCodec envelope, then its batch.
    previous_ids = {entry['delta']['delta']['changes'][0]['id'] for entry in previous['outbox']}
    assert winner['id'] not in previous_ids
    assert a['snapshot']['deltaSequence'] > previous['snapshot']['deltaSequence']
    assert len(previous['outbox']) == 3
    assert len(states['committed-restored']['shopper-b.sqlite']['outbox']) == 2
    assert files['before-install']['eight-alpha.sqlite'] == files['final-verified']['eight-alpha.sqlite']
    assert all(value['schema'] == 1 and value['snapshot']['version'] == 9
               for phase in states.values() for value in phase.values())
    return dict(snapshotAndOutboxExactAfterRestart=True,
        pendingBeforeAck=dict(a=3, b=2), newEditAfterRestartHasDistinctId=True,
        latestWinner=winner, counterComponents=components, counterValue=8,
        finalOutboxesEmpty=True, finalStateExactAfterRestart=True,
        eightAlphaDatabaseUnchanged=True, schema=1, snapshotVersion=9,
        databaseFileSha256=files)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--directory', required=True, type=Path)
    parser.add_argument('--report', required=True, type=Path)
    args = parser.parse_args()
    report = inspect(args.directory)
    args.report.write_text(json.dumps(report, indent=2)+'\n')
    print(json.dumps({k:v for k,v in report.items() if k!='databaseFileSha256'}))


if __name__ == '__main__':
    main()
