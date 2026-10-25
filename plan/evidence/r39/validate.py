#!/usr/bin/env python3
"""Prove R-39 source migration, frozen data preservation and SQLite rollback.

Uses the frozen R-30 sources/data without regenerating either. Materializes an
independent path consumer in /tmp; every Dart invocation uses the selected PATH.
"""

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
R30 = HERE.parent / "r30"
PACKAGES = ["deltasync_core", "deltasync_sync", "deltasync_storage",
            "deltasync_storage_sqflite", "deltasync_storage_testing",
            "deltasync_transport"]


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def run(command, cwd, *, expected=0, environment=None):
    result = subprocess.run(command, cwd=cwd, env=environment, text=True,
                            stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    record = {"command": list(map(str, command)), "cwd": str(cwd),
              "exitCode": result.returncode, "output": result.stdout}
    if (expected == 0 and result.returncode != 0 or
            expected == "failure" and result.returncode == 0):
        raise RuntimeError(json.dumps(record, indent=2))
    return record


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dart", default="dart")
    parser.add_argument("--report", type=Path, required=True)
    args = parser.parse_args()
    # Reports cannot replace any source, historical evidence, or frozen fixture.
    report_path = args.report.resolve()
    if report_path.is_relative_to(ROOT) and report_path != HERE / "validation.json":
        parser.error("Use /tmp or r39/validation.json for the report")
    frozen_hashes = {str(path.relative_to(ROOT)): digest(path)
                     for path in sorted(R30.iterdir()) if path.is_file()}
    records = []
    sdk = run([args.dart, "--version"], ROOT)
    prepared = run(["python3", str(R30 / "capture.py"), "--dart", args.dart,
                    "--prepare-only"], ROOT)
    paths = json.loads(prepared["output"])
    historical = Path(paths["historicalSourceDirectory"])
    old_env = dict(os.environ, R30_EXPECT_SOURCE=str(historical))
    records.append(run([args.dart, "test", paths["historicalConsumer"],
                        "--reporter", "expanded"], historical, environment=old_env))
    require_tests(records[-1], 14)

    isolated = Path(tempfile.mkdtemp(prefix="deltasync-r39-consumer-"))
    (isolated / "test").mkdir()
    (isolated / "plan/evidence/r30").mkdir(parents=True)
    (isolated / "plan/evidence/r30/fixture_1_0_0.json").write_bytes(
        (R30 / "fixture_1_0_0.json").read_bytes())
    manifest = f"""name: r39_external_consumer
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
"""
    for package in PACKAGES:
        manifest += f"  {package}:\n    path: {ROOT}/packages/{package}\n"
    (isolated / "pubspec.yaml").write_text(manifest)
    (isolated / "test/consumer_test.dart").write_bytes(
        (HERE / "consumer_test.dart.txt").read_bytes())
    guide = (ROOT / "docs/migracao-1.0.1.md").read_text()
    snippet = re.search(r"```dart\n(Future<void> importPending[\s\S]+?)\n```", guide)
    assert snippet, "Missing migration guide example"
    (isolated / "test/import_pending.dart").write_text(
        "import 'package:deltasync/deltasync.dart';\n\n" + snippet[1] + "\n")
    (isolated / "rollback.dart").write_bytes((HERE / "rollback.dart.txt").read_bytes())
    records.append(run([args.dart, "pub", "get", "--offline"], isolated))
    config = json.loads((isolated / ".dart_tool/package_config.json").read_text())
    assert config["configVersion"] == 2
    current_env = dict(os.environ, R39_EXPECT_SOURCE=str(ROOT))
    records.append(run([args.dart, "analyze", "test", "rollback.dart"], isolated))
    records.append(run([args.dart, "test", "--reporter", "expanded"], isolated,
                       environment=current_env))
    require_tests(records[-1], 15)

    # Expected compile failure: old aliases must not become accidental shims.
    old = isolated / "old"
    old.mkdir()
    for name in ("consumer_test.dart", "fixture.dart"):
        (old / name).write_bytes((R30 / (name + ".txt")).read_bytes())
    records.append(run([args.dart, "test", str(old / "consumer_test.dart"),
                        "--reporter", "expanded"], isolated, expected="failure"))
    assert "PendingDeltaStore" in records[-1]["output"]
    probes = [
        "PendingDeltaStore? removedStore;",
        "MemoryPendingDeltaStore? removedMemoryStore;",
        "Operation? removedOperation;",
        "migrateLegacyOperation(null);",
        "r.set('key', 1);",
        "r.remove('key');",
        "e.set('key', 1);",
        "e.remove('key');",
        "Delta.crdt(const []);",
        "const Delta.empty().crdtChanges;",
        "entry.operationId;",
        "SyncEngine(replica: r, storage: e.storage, transport: e.transport, store: Object());",
    ]
    negative = isolated / "removed.dart"
    negative.write_text("import 'package:deltasync/deltasync.dart';\n"
                        "void removed(Replica r, SyncEngine e, OutboxEntry entry) {\n"
                        + "\n".join(probes) + "\n}\n")
    records.append(run([args.dart, "analyze", "--format", "machine", str(negative)],
                       isolated, expected="failure"))
    error_lines = {int(line.split('|')[4]) for line in records[-1]["output"].splitlines()
                   if line.startswith('ERROR|')}
    assert set(range(3, 3 + len(probes))) <= error_lines, records[-1]["output"]

    database = isolated / "rollback.sqlite"
    historical_tool = historical / "rollback.dart"
    historical_tool.write_bytes((HERE / "rollback.dart.txt").read_bytes())
    fixture = R30 / "fixture_1_0_0.json"
    for directory, tool, mode in ((historical, historical_tool, "seed"),
                                   (isolated, isolated / "rollback.dart", "upgrade"),
                                   (historical, historical_tool, "verify")):
        record = run([args.dart, "run", str(tool), mode, str(database), str(fixture)],
                     directory)
        assert f'"mode":"{mode}","passed":true' in record["output"]
        records.append(record)

    inventory = run([args.dart, "--packages=.dart_tool/package_config.json",
                     str(R30 / "api_inventory.dart"), str(ROOT)], ROOT)
    before = json.loads((R30 / "api_1_0_0.json").read_text())
    after = json.loads(inventory["output"])
    differences = inventory_diff(before, after)
    assert frozen_hashes == {str(path.relative_to(ROOT)): digest(path)
                             for path in sorted(R30.iterdir()) if path.is_file()}
    report = {"task": "R-39", "sdk": sdk, "isolatedConsumer": str(isolated),
              "historicalRevision": "1e969182e8e172a8858a48ecf83a1feb2c21a455",
              "historicalSource": str(historical), "records": records,
              "apiDifferences": differences, "r30UnchangedSha256": frozen_hashes,
              "limits": ["Path dependencies, not hosted release artifacts",
                         "SQLite FFI Linux subprocesses, not Android runtime",
                         "SDK 3.12.x remains for R-33/VAL-17"]}
    report_path.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n")
    print(json.dumps({"report": str(report_path), "historicalChecks": 14,
                      "migratedChecks": 15, "rollback": "seed/upgrade/verify passed",
                      "apiPackagesCompared": len(after)}))


def require_tests(record, count):
    passed = re.findall(r"\+(\d+): All tests passed!", record["output"])
    assert passed and int(passed[-1]) == count, record["output"]


def inventory_diff(before, after):
    removed = {"Operation", "migrateLegacyOperation", "PendingDeltaStore",
               "MemoryPendingDeltaStore"}
    changed = {"Delta", "Replica", "SyncEngine", "OutboxEntry", "SyncRetryPolicy"}
    differences = {}
    assert before.keys() == after.keys()
    for package in before:
        old, new = before[package], after[package]
        missing = old.keys() - new.keys()
        assert not (new.keys() - old.keys()), package
        assert missing <= removed, (package, missing)
        members = {}
        for name in old.keys() & new.keys():
            if old[name] == new[name]:
                continue
            assert name in changed, (package, name)
            assert old[name]["source"] == new[name]["source"]
            documentation = []
            if name == "SyncRetryPolicy":
                removed_doc = (" The legacy [PendingDeltaStore] /// path has no attempt "
                               "metadata; every push retries its retained delta.")
                assert old[name]["declaration"].replace(removed_doc, "") == new[name]["declaration"]
                assert old[name]["members"] == new[name]["members"]
                members[name] = {"documentationOnly": True}
                continue
            assert old[name]["declaration"] == new[name]["declaration"]
            lost = sorted(set(old[name]["members"]) - set(new[name]["members"]))
            added = sorted(set(new[name]["members"]) - set(old[name]["members"]))
            doc_pairs = {
                "OutboxEntry": ("String get entryId",
                                "/// Stable ID of the single change in this entry. String get entryId"),
                "SyncEngine": (
                    "/// Locally retained changes, including sent but unacknowledged changes. The /// deprecated store cannot remove entries even after a remote ACK. Future<Delta> pendingDelta()",
                    "/// Locally retained changes, including sent but unacknowledged changes. Future<Delta> pendingDelta()"),
            }
            if name in doc_pairs:
                old_doc, new_doc = doc_pairs[name]
                assert old_doc in lost and new_doc in added
                lost.remove(old_doc)
                added.remove(new_doc)
                documentation.append({"before": old_doc, "after": new_doc})
            patterns = {
                "Delta": r"Delta\.crdt\(|get crdtChanges",
                "Replica": r"LwwDelta<Object\?> (set|remove)\(",
                "OutboxEntry": r"String get operationId",
                "SyncEngine": r"SyncEngine\(|PendingDeltaStore\? store|ReplicaStorage\? storage|Future<LwwDelta<Object\?>> (set|remove)\(",
            }
            assert all(re.search(patterns[name], item) for item in lost), (name, lost)
            assert len(lost) == {"Delta": 2, "Replica": 2, "OutboxEntry": 1,
                                 "SyncEngine": 5}[name], (name, lost)
            if name == "SyncEngine":
                assert len(added) == 2
                assert any("required this.storage" in item for item in added)
                assert "final ReplicaStorage storage;" in added
            else:
                assert not added, (name, added)
            members[name] = {"removed": lost, "added": added,
                             "documentation": documentation}
        differences[package] = {"removedSymbols": sorted(missing), "members": members}
    assert set().union(*(set(value["removedSymbols"]) for value in differences.values())) == removed
    return differences


if __name__ == "__main__":
    main()
