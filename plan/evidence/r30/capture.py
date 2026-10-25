#!/usr/bin/env python3
"""Capture historical source/API/data provenance without changing product code.

The historical fixture is generated only with an explicit --freeze flag. Future
checks read it; regeneration is never part of normal regression validation.
"""

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


HISTORICAL = "1e969182e8e172a8858a48ecf83a1feb2c21a455"
PACKAGES = [
    "deltasync", "deltasync_core", "deltasync_storage", "deltasync_transport",
    "deltasync_sync", "deltasync_storage_sqflite", "deltasync_storage_testing",
]
ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent


def run(*arguments):
    return subprocess.check_output(arguments, cwd=ROOT, text=True)


def files(root):
    result = {}
    for package in PACKAGES:
        base = root if package == "deltasync" else root / "packages" / package
        for path in sorted((base / "lib").rglob("*.dart")):
            result[path.relative_to(root).as_posix()] = hashlib.sha256(
                path.read_bytes()).hexdigest()
    return result


def check_consumers(sdk, paths):
    results = []
    for label, directory, consumer in [
        ("historical", Path(paths["historicalSourceDirectory"]), paths["historicalConsumer"]),
        ("current", ROOT, paths["currentConsumer"]),
    ]:
        command = [sdk, "test", consumer, "--reporter", "expanded"]
        environment = dict(os.environ, R30_EXPECT_SOURCE=str(directory))
        result = subprocess.run(command, cwd=directory, env=environment,
                                stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                text=True)
        log = Path(paths["historicalSourceDirectory"]) / f"{label}-consumer.log"
        log.write_text(result.stdout)
        if result.returncode:
            raise RuntimeError(f"{label} consumer failed: {log}\n{result.stdout}")
        passed = re.findall(r"\+(\d+): All tests passed!", result.stdout)
        if not passed:
            raise RuntimeError(f"Missing successful test summary in {log}")
        results.append({"source": label, "command": command,
                        "workingDirectory": str(directory), "tests": int(passed[-1]),
                        "exitCode": result.returncode, "log": str(log),
                        "output": result.stdout})
    return results


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dart", default="dart",
                        help="Dart command from PATH (default: dart)")
    parser.add_argument("--freeze", action="store_true",
                        help="Create absent immutable historical JSON and API inventory")
    parser.add_argument("--report", type=Path)
    parser.add_argument("--prepare-only", action="store_true",
                        help="Prepare historical source and consumers, without rewriting records")
    parser.add_argument("--test-consumers", action="store_true",
                        help="Compile and exercise both source trees, including SQLite")
    arguments = parser.parse_args()
    if not arguments.prepare_only and arguments.report is None:
        parser.error("--report is required unless --prepare-only is selected")
    if arguments.prepare_only and arguments.freeze:
        parser.error("--prepare-only cannot be combined with --freeze")
    protected = {
        (HERE / name).resolve() for name in (
            "fixture_1_0_0.json", "api_1_0_0.json",
            "fixture.dart.txt", "consumer_test.dart.txt",
        )
    }
    if arguments.report is not None and arguments.report.resolve() in protected:
        parser.error("--report cannot overwrite frozen data, API or source fixtures")
    sdk = arguments.dart
    sdk_version = subprocess.run([str(sdk), "--version"], check=True,
                                 capture_output=True, text=True)
    sdk_text = (sdk_version.stdout + sdk_version.stderr).strip()
    version = re.search(r"Dart SDK version: (\d+)\.(\d+)\.(\d+)", sdk_text)
    if version is None:
        raise RuntimeError(f"Unrecognized Dart SDK version: {sdk_text}")
    minimum_consumer_executed = (
        version.groups()[:2] == ("3", "12") and arguments.test_consumers)
    temporary = Path(tempfile.mkdtemp(prefix="deltasync-r30-source-"))
    archive = subprocess.check_output(
        ["git", "archive", HISTORICAL, "pubspec.yaml", "lib", "packages"], cwd=ROOT)
    with tarfile.open(fileobj=io.BytesIO(archive)) as contents:
        contents.extractall(temporary, filter="data")

    resolution = subprocess.check_output(
        [sdk, "pub", "get", "--offline"], cwd=temporary, text=True)
    historical_config = temporary / ".dart_tool" / "package_config.json"
    consumer_directory = Path(tempfile.mkdtemp(prefix="deltasync-r30-consumer-"))
    historical_assets = temporary / "plan" / "evidence" / "r30"
    historical_assets.mkdir(parents=True)
    for filename in ("fixture.dart", "consumer_test.dart"):
        content = (HERE / (filename + ".txt")).read_bytes()
        (consumer_directory / filename).write_bytes(content)
        (historical_assets / filename).write_bytes(content)
    paths = {
        "historicalSourceDirectory": str(temporary),
        "historicalPackageConfig": str(historical_config),
        "historicalConsumer": str(historical_assets / "consumer_test.dart"),
        "currentConsumer": str(consumer_directory / "consumer_test.dart"),
        "generator": str(historical_assets / "fixture.dart"),
    }
    if arguments.prepare_only:
        (historical_assets / "fixture_1_0_0.json").write_bytes(
            (HERE / "fixture_1_0_0.json").read_bytes())
        if arguments.test_consumers:
            paths["consumerChecks"] = check_consumers(sdk, paths)
        print(json.dumps(paths))
        return
    config_file = ROOT / ".dart_tool" / "package_config.json"
    config = json.loads(config_file.read_text())

    historical_sources = files(temporary)
    current_sources = files(ROOT)
    if historical_sources != current_sources:
        raise RuntimeError("Product lib sources differ: review before freezing baseline")
    metadata = {}
    for name in PACKAGES:
        prefix = Path() if name == "deltasync" else Path("packages") / name
        metadata[name] = {}
        for label, base in [("historical", temporary), ("current", ROOT)]:
            manifest = (base / prefix / "pubspec.yaml").read_text()
            metadata[name][label] = {
                "version": re.search(r"^version: (.+)$", manifest, re.M)[1],
                "sdk": re.search(r"^  sdk: (.+)$", manifest, re.M)[1],
            }

    inventory_file = HERE / "api_1_0_0.json"
    fixture_file = HERE / "fixture_1_0_0.json"
    current_inventory = json.loads(run(
        str(sdk), f"--packages={config_file}",
        str(HERE / "api_inventory.dart"), str(ROOT)))
    historical_inventory = json.loads(run(
        str(sdk), f"--packages={config_file}",
        str(HERE / "api_inventory.dart"), str(temporary)))
    if current_inventory != historical_inventory:
        raise RuntimeError("Historical and current public declarations differ")

    if arguments.freeze:
        if inventory_file.exists() or fixture_file.exists():
            raise RuntimeError("Frozen files already exist; do not overwrite baseline")
        inventory_file.write_text(json.dumps(historical_inventory, indent=2,
                                             ensure_ascii=False) + "\n")
        run(str(sdk), f"--packages={historical_config}",
            paths["generator"], str(fixture_file))
    if json.loads(inventory_file.read_text()) != historical_inventory:
        raise RuntimeError("Frozen API inventory does not match pinned source")

    # Check determinism against the old writer, never the evolving writer.
    regenerated = temporary / "regenerated.json"
    run(str(sdk), f"--packages={historical_config}",
        paths["generator"], str(regenerated))
    if regenerated.read_bytes() != fixture_file.read_bytes():
        raise RuntimeError("Historical fixture regeneration is not deterministic")

    (historical_assets / "fixture_1_0_0.json").write_bytes(fixture_file.read_bytes())
    report = {
        "historicalRevision": HISTORICAL,
        "currentRevision": run("git", "rev-parse", "HEAD").strip(),
        "sdk": sdk_text,
        **paths,
        "dartCommand": sdk,
        "historicalResolution": resolution,
        "packageMetadata": metadata,
        "allLibSourcesIdentical": True,
        "libSha256": historical_sources,
        "publicDeclaredSymbols": {name: len(symbols)
                                  for name, symbols in historical_inventory.items()},
        "analyzerToolPackage": next(
            package["rootUri"] for package in config["packages"]
            if package["name"] == "analyzer"),
        "fixtureSha256": hashlib.sha256(fixture_file.read_bytes()).hexdigest(),
        "apiInventorySha256": hashlib.sha256(inventory_file.read_bytes()).hexdigest(),
        "consumerSourceSha256": hashlib.sha256(
            (HERE / "consumer_test.dart.txt").read_bytes()).hexdigest(),
        "generatorSourceSha256": hashlib.sha256(
            (HERE / "fixture.dart.txt").read_bytes()).hexdigest(),
        "fixtureGeneratorUsesHistoricalPackageConfig": True,
        "futureRegressionsMustReadFrozenFixture": True,
        "minimumSdkExecution": {
            "version": "3.12.x", "definedIn": "README.md#matriz-de-sdk",
            "scope": "consumer checks; seven-package matrix recorded separately",
            "executed": minimum_consumer_executed,
            "reason": "See sdk and consumerChecks; no claim for an unexecuted SDK",
        },
    }
    if arguments.test_consumers:
        report["consumerChecks"] = check_consumers(sdk, paths)
    arguments.report.write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps({"report": str(arguments.report), **paths}))


if __name__ == "__main__":
    main()
