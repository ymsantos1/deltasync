#!/usr/bin/env python3
"""Export standalone pub packages without publishing or changing the workspace."""

import argparse
import hashlib
import json
from pathlib import Path
import re
import shutil
import tempfile


ROOT = Path(__file__).resolve().parents[1]
# Dependency order; keep the storage contract suite before the SQLite adapter.
PACKAGES = (
    "deltasync_core",
    "deltasync_storage",
    "deltasync_transport",
    "deltasync_sync",
    "deltasync_storage_testing",
    "deltasync_storage_sqflite",
    "deltasync",
)
REQUIRED = ("pubspec.yaml", "README.md", "CHANGELOG.md", "LICENSE")


def standalone_manifest(source):
    """Remove only workspace configuration; retain dependency constraints."""
    lines = source.splitlines(keepends=True)
    result = []
    in_workspace = False
    for line in lines:
        if re.match(r"^workspace:\s*$", line):
            in_workspace = True
            continue
        if in_workspace:
            if not line.strip() or line.startswith((" ", "#")):
                continue
            in_workspace = False
        if line.strip() == "resolution: workspace":
            continue
        result.append(line)
    manifest = "".join(result)
    if re.search(r"^(workspace|resolution|dependency_overrides):", manifest, re.M):
        raise ValueError("Unexpected workspace/override configuration in pubspec")
    return manifest


def prepare(destination):
    destination = destination.resolve()
    if destination == ROOT or ROOT in destination.parents:
        raise ValueError("Release destination must be outside the source workspace")
    markers = [parent / ".git" for parent in (destination, *destination.parents)]
    if any(marker.is_file() or (marker / "HEAD").is_file() for marker in markers):
        raise ValueError("Release destination must be outside Git repositories")
    # Validate every input before creating output. Never replace an existing release.
    sources = {}
    for name in PACKAGES:
        source = ROOT if name == "deltasync" else ROOT / "packages" / name
        for item in (*REQUIRED, "lib"):
            if not (source / item).exists():
                raise ValueError(f"Missing {name}/{item}")
        sources[name] = source
    destination.mkdir(parents=True, exist_ok=False)
    inventory = {}
    for name, source in sources.items():
        target = destination / name
        target.mkdir()
        for item in (*REQUIRED, "lib", "analysis_options.yaml"):
            path = source / item
            if not path.exists():
                continue
            if path.is_symlink() or (
                path.is_dir() and any(p.is_symlink() for p in path.rglob("*"))
            ):
                raise ValueError(f"Refusing symlink in release input: {path}")
            if path.is_dir():
                shutil.copytree(path, target / item)
            else:
                shutil.copyfile(path, target / item)
        manifest = target / "pubspec.yaml"
        manifest.write_text(standalone_manifest(manifest.read_text()))
        if name == "deltasync":
            (target / "example").mkdir()
            shutil.copyfile(
                source / "example/deltasync_example.dart",
                target / "example/deltasync_example.dart",
            )
        (target / ".pubignore").write_text(".dart_tool/\nbuild/\ncoverage/\npubspec.lock\n")
        inventory[name] = {
            str(path.relative_to(target)): hashlib.sha256(path.read_bytes()).hexdigest()
            for path in sorted(target.rglob("*")) if path.is_file()
        }
    (destination / "inventory.json").write_text(json.dumps(inventory, indent=2) + "\n")
    return destination


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, help="New directory outside any Git repository")
    args = parser.parse_args()
    destination = args.output or (
        Path(tempfile.mkdtemp(prefix="deltasync-release-parent-")) / "release"
    )
    try:
        print(prepare(destination))
    except (ValueError, OSError) as error:
        parser.exit(1, f"Release preparation failed: {error}\n")


if __name__ == "__main__":
    main()
