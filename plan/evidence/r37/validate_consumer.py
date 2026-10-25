#!/usr/bin/env python3
"""Compile an external adapter before/after the required summary member."""
import argparse
import hashlib
import io
import json
import os
from pathlib import Path
import re
import subprocess
import tarfile
import tempfile

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
BEFORE = 'f2edf0f4da878dd785c1240536b4537aa081e9d4'
PACKAGES = ['deltasync_core', 'deltasync_sync', 'deltasync_storage',
            'deltasync_storage_sqflite', 'deltasync_storage_testing', 'deltasync_transport']


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--dart', default='dart')
    parser.add_argument('--report', type=Path, required=True)
    args = parser.parse_args()
    if args.report.resolve().is_relative_to(ROOT):
        parser.error('Write temporary results outside the repository')
    records = []

    def run(command, cwd, *, failure=False, env=None):
        result = subprocess.run(command, cwd=cwd, env=env, text=True,
                                stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        record = dict(command=list(map(str, command)), cwd=str(cwd),
                      exitCode=result.returncode, output=result.stdout)
        records.append(record)
        if (result.returncode == 0) == failure:
            raise RuntimeError(json.dumps(record, indent=2))
        return result.stdout

    frozen = {str(p.relative_to(ROOT)): hashlib.sha256(p.read_bytes()).hexdigest()
              for folder in ('r30', 'r39') for p in (HERE.parent / folder).iterdir()
              if p.is_file()}
    isolated = Path(tempfile.mkdtemp(prefix='deltasync-r37-consumer-'))
    (isolated / 'test').mkdir()
    manifest = f'''name: r37_external_consumer
publish_to: none
environment:
  sdk: ^3.12.0
dependencies:
  deltasync:
    path: {ROOT}
  deltasync_storage_sqflite:
    path: {ROOT}/packages/deltasync_storage_sqflite
  deltasync_storage_testing:
    path: {ROOT}/packages/deltasync_storage_testing
  sqflite_common_ffi: ^2.3.7
dev_dependencies:
  test: ^1.25.6
dependency_overrides:
'''
    for package in PACKAGES:
        manifest += f'  {package}:\n    path: {ROOT}/packages/{package}\n'
    (isolated / 'pubspec.yaml').write_text(manifest)
    source = (HERE / 'consumer_test.dart.txt').read_text()
    (isolated / 'test/consumer_test.dart').write_text(source)
    guide = (ROOT / 'docs/migracao-1.0.1.md').read_text()
    snippet = re.search(r'```dart\n(Future<void> importPending[\s\S]+?)\n```', guide)
    assert snippet
    (isolated / 'test/import_pending.dart').write_text(
        "import 'package:deltasync/deltasync.dart';\n" + snippet[1] + '\n')
    fixture_path = isolated / 'plan/evidence/r30/fixture_1_0_0.json'
    fixture_path.parent.mkdir(parents=True)
    fixture_path.write_bytes((HERE.parent / 'r30/fixture_1_0_0.json').read_bytes())
    sdk = run([args.dart, '--version'], ROOT)
    run([args.dart, 'pub', 'get', '--offline'], isolated)
    run([args.dart, 'analyze', 'test'], isolated)
    output = run([args.dart, 'test', '--reporter', 'expanded'], isolated,
                 env=dict(os.environ, R37_EXPECT_SOURCE=str(ROOT)))
    assert re.search(r'\+18: All tests passed!', output), output
    old = isolated / 'old_consumer_test.dart'
    old.write_bytes((HERE.parent / 'r39/consumer_test.dart.txt').read_bytes())
    (isolated / 'import_pending.dart').write_bytes((isolated / 'test/import_pending.dart').read_bytes())
    negative = run([args.dart, 'analyze', str(old)], isolated, failure=True)
    assert 'pendingSummary' in negative and 'non_abstract_class_inherits_abstract_member' in negative

    historical = Path(tempfile.mkdtemp(prefix='deltasync-r37-before-'))
    archive = subprocess.check_output(['git', 'archive', BEFORE, 'lib', 'packages'], cwd=ROOT)
    with tarfile.open(fileobj=io.BytesIO(archive)) as contents:
        contents.extractall(historical, filter='data')
    extractor = HERE.parent / 'r30/api_inventory.dart'
    def inventory(root):
        return json.loads(run([args.dart, '--packages=.dart_tool/package_config.json',
                               str(extractor), str(root)], ROOT))
    before, after = inventory(historical), inventory(ROOT)
    differences = {}
    for package, old_symbols in before.items():
        new_symbols = after[package]
        assert not (old_symbols.keys() - new_symbols.keys())
        added = sorted(new_symbols.keys() - old_symbols.keys())
        assert added == (['OutboxSummary'] if package in ('deltasync', 'deltasync_storage') else [])
        members = {}
        for name in old_symbols:
            old_symbol, new_symbol = old_symbols[name], new_symbols[name]
            if old_symbol == new_symbol:
                continue
            assert name in ('ReplicaStorage', 'MemoryStorage', 'SqfliteReplicaStorage', 'SyncEngine')
            assert old_symbol['source'] == new_symbol['source']
            assert old_symbol['declaration'] == new_symbol['declaration']
            lost = set(old_symbol['members']) - set(new_symbol['members'])
            gained = set(new_symbol['members']) - set(old_symbol['members'])
            assert not lost and len(gained) == 1
            assert 'Future<OutboxSummary> pendingSummary(' in next(iter(gained))
            members[name] = sorted(gained)
        differences[package] = dict(addedSymbols=added, addedMembers=members)
    assert len(differences) == 7
    for name, expected in frozen.items():
        assert hashlib.sha256((ROOT / name).read_bytes()).hexdigest() == expected
    # Inventory command output is large; preserve only its verified differences.
    for record in records:
        if str(extractor) in record['command']:
            record['output'] = 'Parsed inventory; additions verified in apiDifferences'
    report = dict(task='R-37', beforeRevision=BEFORE, sdk=sdk,
                  isolatedDirectory=str(isolated), records=records,
                  apiDifferences=differences, frozenSha256=frozen,
                  sourceSha256=hashlib.sha256(source.encode()).hexdigest(),
                  limits=['Independent path resolution, not hosted artifact validation',
                          'Dart 3.13.5 reference; no SDK 3.12.x/Android runtime'])
    args.report.write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n')
    print(json.dumps(dict(report=str(args.report), checks=18, oldAdapterRejected=True,
                          publicInventories=7)))


if __name__ == '__main__':
    main()
