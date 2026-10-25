#!/usr/bin/env python3
"""Compile selective observation consumers and inventory intentional API changes."""
import argparse
import hashlib
import io
import json
from pathlib import Path
import subprocess
import tarfile
import tempfile

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
BEFORE = 'bc65f4a2658b75141953477c6281c12eebf11f07'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--dart', default='dart')
    parser.add_argument('--report', type=Path, required=True)
    args = parser.parse_args()
    if args.report.resolve().is_relative_to(ROOT):
        parser.error('Write temporary results outside this repository')
    records = []

    def run(command, cwd, *, failure=False):
        result = subprocess.run(command, cwd=cwd, text=True, stdout=subprocess.PIPE,
                                stderr=subprocess.STDOUT)
        record = dict(command=list(map(str, command)), cwd=str(cwd),
                      exitCode=result.returncode, output=result.stdout)
        records.append(record)
        if (result.returncode == 0) == failure:
            raise RuntimeError(json.dumps(record, indent=2))
        return result.stdout

    isolated = Path(tempfile.mkdtemp(prefix='deltasync-r41-consumer-'))
    (isolated / 'test').mkdir()
    manifest = f'''name: r41_consumer
publish_to: none
environment:
  sdk: ^3.12.0
dependencies:
  deltasync:
    path: {ROOT}
dev_dependencies:
  test: ^1.25.6
dependency_overrides:
'''
    for package in ['deltasync_core', 'deltasync_sync', 'deltasync_storage', 'deltasync_transport']:
        manifest += f'  {package}:\n    path: {ROOT}/packages/{package}\n'
    (isolated / 'pubspec.yaml').write_text(manifest)
    source = (HERE / 'consumer_test.dart.txt').read_bytes()
    (isolated / 'test/consumer_test.dart').write_bytes(source)
    sdk = run([args.dart, '--version'], ROOT)
    run([args.dart, 'pub', 'get', '--offline'], isolated)
    run([args.dart, 'analyze', 'test'], isolated)
    output = run([args.dart, 'test', '--reporter', 'expanded'], isolated)
    assert '+2: All tests passed!' in output
    negative = isolated / 'old_api.dart'
    negative.write_text("import 'package:deltasync/deltasync.dart';\n"
                        "const old = SyncCommitEvent(origin: SyncCommitOrigin.local);\n"
                        "class OldEvent implements SyncCommitEvent {\n"
                        "  @override SyncCommitOrigin get origin => SyncCommitOrigin.local;\n}\n"
                        "class OldReplica extends Replica {\n"
                        "  OldReplica() : super('old');\n"
                        "  @override void mergeSnapshotJson(Map<String, Object?> json) {}\n}\n")
    output = run([args.dart, 'analyze', str(negative)], isolated, failure=True)
    assert 'missing_required_argument' in output
    assert 'const_with_non_const' in output
    assert 'non_abstract_class_inherits_abstract_member' in output
    assert 'invalid_override' in output

    historical = Path(tempfile.mkdtemp(prefix='deltasync-r41-before-'))
    archive = subprocess.check_output(['git', 'archive', BEFORE, 'lib', 'packages'], cwd=ROOT)
    with tarfile.open(fileobj=io.BytesIO(archive)) as contents:
        contents.extractall(historical, filter='data')

    def inventory(root):
        return json.loads(run([args.dart, '--packages=.dart_tool/package_config.json',
                               str(ROOT / 'scripts/api_inventory.dart'), str(root)], ROOT))

    old, new = inventory(historical), inventory(ROOT)
    differences = {}
    for package, old_symbols in old.items():
        new_symbols = new[package]
        assert not (old_symbols.keys() - new_symbols.keys())
        added = sorted(new_symbols.keys() - old_symbols.keys())
        assert not added, (package, added)
        core = package in ('deltasync', 'deltasync_core')
        sync = package in ('deltasync', 'deltasync_sync')
        changes = {}
        for name in old_symbols:
            before, after = old_symbols[name], new_symbols[name]
            if before == after:
                continue
            assert ((core and name == 'Replica') or
                    (sync and name in ('SyncEngine', 'SyncCommitEvent'))), (package, name)
            assert before['source'] == after['source'] and before['declaration'] == after['declaration']
            lost = set(before['members']) - set(after['members'])
            gained = set(after['members']) - set(before['members'])
            def only_ending(entries, signature):
                return len(entries) == 1 and next(iter(entries)).endswith(signature)
            if name == 'Replica':
                assert only_ending(lost, 'void mergeSnapshotJson(Map<String, Object?> json)'), lost
                assert only_ending(gained, 'Set<String> mergeSnapshotJson(Map<String, Object?> json)'), gained
            elif name == 'SyncEngine':
                assert not lost
                assert only_ending(gained, 'Stream<SyncCommitEvent> commitsFor(String address)'), gained
            else:
                assert lost == {'const SyncCommitEvent({required this.origin})'}, lost
                assert gained == {'SyncCommitEvent({required this.origin, required Iterable<String> addresses})',
                                  'final Set<String> addresses;'}, gained
            changes[name] = dict(removed=sorted(lost), added=sorted(gained))
        expected_names = ({'Replica'} if core else set()) | (
            {'SyncEngine', 'SyncCommitEvent'} if sync else set())
        assert set(changes) == expected_names
        differences[package] = dict(addedSymbols=added, changedMembers=changes)
    for record in records:
        if any('api_inventory.dart' in part for part in record['command']):
            record['output'] = 'Inventory parsed and compared; see apiDifferences'
    report = dict(task='R-41', beforeRevision=BEFORE, sdk=sdk,
                  isolatedDirectory=str(isolated), records=records,
                  apiDifferences=differences, sourceSha256=hashlib.sha256(source).hexdigest(),
                  limits=['Independent path dependencies, not hosted artifacts',
                          'Language 3.12; reference SDK shown above, not minimum runtime proof'])
    args.report.write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n')
    print(json.dumps(dict(report=str(args.report), checks=2, oldApiMigrationRequired=True,
                          apiPackagesCompared=7)))


if __name__ == '__main__':
    main()
