"""Verify the frozen CP-16 bundle before a main-series pair."""

import hashlib
import json
from pathlib import Path
import sys
import tarfile


def sha256(stream):
    digest = hashlib.sha256()
    for block in iter(lambda: stream.read(1024 * 1024), b''):
        digest.update(block)
    return digest.hexdigest()


def check(bundle):
    bundle = Path(bundle).resolve(strict=True)
    manifest = json.loads((bundle / 'manifest.json').read_text())
    if manifest['artifactType'] != 'compass_cp16_frozen_inputs':
        raise ValueError('Unexpected artifact type')
    declared = set()
    for row in manifest['files']:
        relative = Path(row['path'])
        path = bundle / relative
        if relative.is_absolute() or '..' in relative.parts or relative in declared:
            raise ValueError(f'Unsafe or repeated path: {relative}')
        if path.is_symlink() or not path.is_file():
            raise ValueError(f'Missing or linked file: {relative}')
        with path.open('rb') as source:
            digest = sha256(source)
        if path.stat().st_size != row['bytes'] or digest != row['sha256']:
            raise ValueError(f'File changed: {relative}')
        declared.add(relative)
    actual = {path.relative_to(bundle) for path in bundle.rglob('*')
              if path.is_file() and path.name != 'manifest.json'}
    if actual != declared or len(declared) != len(manifest['files']):
        raise ValueError('Bundle inventory differs')
    builds = json.loads((bundle / 'builds.json').read_text())
    expected = {f'{role}-n{count}-{condition}'
                for role in ('alpha', 'beta') for count in (1, 1000)
                for condition in ('on', 'off')}
    if {row['label'] for row in builds} != expected or len(builds) != 8:
        raise ValueError('Build matrix incomplete')
    for row in builds:
        if (Path(row['apk']) not in declared or Path(row['config']) not in declared
                or row['apkSha256'] != next(item['sha256'] for item in manifest['files']
                                                 if item['path'] == row['apk'])
                or row['configSha256'] != next(item['sha256'] for item in manifest['files']
                                                    if item['path'] == row['config'])):
            raise ValueError(f'Build entry differs: {row["label"]}')
    sources = json.loads((bundle / 'source-inventory.json').read_text())
    with tarfile.open(bundle / 'sources.tar.gz') as archive:
        if {member.name for member in archive.getmembers()} != {row['path'] for row in sources}:
            raise ValueError('Source archive inventory differs')
        for row in sources:
            member = archive.getmember(row['path'])
            source = archive.extractfile(member)
            if source is None or member.size != row['bytes'] or sha256(source) != row['sha256']:
                raise ValueError(f'Source changed: {row["path"]}')
    for label in ('n1-passed', 'n1000-final-passed'):
        smoke = bundle / 'smoke' / label
        if json.loads((smoke / 'cleanup.json').read_text())['errors']:
            raise ValueError(f'Cleanup failed: {label}')
        results = json.loads((smoke / 'runs/results.json').read_text())
        if len(results) != 2 or {row['condition'] for row in results} != {'on', 'off'}:
            raise ValueError(f'Smoke incomplete: {label}')
    return {'files': len(declared), 'sources': len(sources), 'builds': len(builds)}


if __name__ == '__main__':
    print(json.dumps(check(sys.argv[1]), sort_keys=True))
