#!/usr/bin/env python3
"""Shared local/CI checks. No publishing, auto-fixes or cached advisory answers."""
import argparse
from datetime import date, datetime, timezone
import json
import re
import shlex
import subprocess
import sys
import tempfile
from pathlib import Path
import urllib.error
import urllib.request

ROOT = Path(__file__).resolve().parents[1]
EXAMPLES = ('deltasync_example', 'local_batch_example',
            'field_query_example', 'field_decoder_example', 'selective_observation_example')
EXCEPTIONS = ROOT / '.github/advisory-exceptions.json'
OSV = 'https://api.osv.dev/v1/querybatch'


class AdvisoryError(Exception):
    """Unexcepted advisory: exit 1; transport/response/config errors use exit 2."""


def run(command, cwd=ROOT, *, capture=False):
    print(f'[{Path(cwd).relative_to(ROOT)}] {shlex.join(command)}', flush=True)
    result = subprocess.run(command, cwd=cwd, check=True, text=True,
                            stdout=subprocess.PIPE if capture else None)
    return result.stdout if capture else ''


def post_json(payload):
    request = urllib.request.Request(
        OSV, data=json.dumps(payload).encode(),
        headers={'Content-Type': 'application/json', 'User-Agent': 'DeltaSync-CI/1'})
    with urllib.request.urlopen(request, timeout=30) as response:
        if response.status != 200:
            raise ValueError(f'Advisory service HTTP {response.status}')
        return json.load(response)


def hosted_packages(dependencies):
    if not isinstance(dependencies, dict):
        raise ValueError('Invalid resolved dependency graph')
    packages = dependencies.get('packages')
    if not isinstance(packages, list) or not packages:
        raise ValueError('Missing resolved dependency graph')
    hosted = {}
    for package in packages:
        if not isinstance(package, dict):
            raise ValueError('Invalid resolved package')
        source = package.get('source')
        if source in ('root', 'path', 'sdk'):
            continue
        if source != 'hosted':
            raise ValueError(f'Unsupported dependency source: {source}')
        name, version = package.get('name'), package.get('version')
        if not isinstance(name, str) or not re.fullmatch(r'[_a-z][_a-z0-9]*', name):
            raise ValueError('Invalid hosted package name')
        if not isinstance(version, str) or not re.fullmatch(r'\d+\.\d+\.\d+(?:[-+][\w.-]+)*', version):
            raise ValueError(f'Invalid resolved version: {name}')
        if name in hosted and hosted[name] != version:
            raise ValueError(f'Conflicting resolved versions: {name}')
        hosted[name] = version
    return sorted(hosted.items())


def advisory_findings(packages, post=post_json):
    findings = set()
    for offset in range(0, len(packages), 100):
        active = [(name, version, None) for name, version in packages[offset:offset+100]]
        seen = set()
        while active:
            queries = []
            for name, version, token in active:
                query = {'package': {'ecosystem': 'Pub', 'name': name}, 'version': version}
                if token:
                    query['page_token'] = token
                queries.append(query)
            payload = post({'queries': queries})
            if isinstance(payload, dict) and 'error' in payload:
                raise ValueError('Advisory service returned an error')
            results = payload.get('results') if isinstance(payload, dict) else None
            if not isinstance(results, list) or len(results) != len(active):
                raise ValueError('Incomplete advisory response')
            following = []
            for (name, version, _), result in zip(active, results):
                if not isinstance(result, dict) or set(result) - {'vulns', 'next_page_token'}:
                    raise ValueError('Invalid advisory result')
                vulns = result.get('vulns', [])
                if not isinstance(vulns, list):
                    raise ValueError('Invalid advisory list')
                for vulnerability in vulns:
                    identifier = vulnerability.get('id') if isinstance(vulnerability, dict) else None
                    if not isinstance(identifier, str) or not identifier.strip():
                        raise ValueError('Invalid advisory identifier')
                    findings.add((name, version, identifier))
                token = result.get('next_page_token')
                if token is not None:
                    marker = (name, version, token)
                    if not isinstance(token, str) or not token or marker in seen or len(seen) >= 100:
                        raise ValueError('Invalid/repeated advisory page token')
                    seen.add(marker)
                    following.append(marker)
            active = following
    return findings


def allowed_findings(exceptions, today):
    if not isinstance(exceptions, list):
        raise ValueError('Advisory exceptions must be a list')
    allowed = set()
    for entry in exceptions:
        required = {'package', 'version', 'id', 'reason', 'expires'}
        if not isinstance(entry, dict) or set(entry) != required:
            raise ValueError('Exception requires package/version/id/reason/expires')
        if any(not isinstance(entry[key], str) or not entry[key].strip() for key in required):
            raise ValueError('Blank advisory exception field')
        if date.fromisoformat(entry['expires']) < today:
            raise ValueError(f"Expired advisory exception: {entry['id']}")
        key = (entry['package'], entry['version'], entry['id'])
        if key in allowed:
            raise ValueError('Duplicate advisory exception')
        allowed.add(key)
    return allowed


def check_advisories(dependencies, exceptions, *, post=post_json, today=None):
    packages = hosted_packages(dependencies)
    allowed = allowed_findings(exceptions, today or datetime.now(timezone.utc).date())
    findings = advisory_findings(packages, post)
    if allowed - findings:
        raise ValueError(f'Unused advisory exceptions: {sorted(allowed - findings)}')
    report = {'hostedPackages': len(packages), 'findings': [
        {'package': name, 'version': version, 'id': identifier, 'excepted': item in allowed}
        for item in sorted(findings) for name, version, identifier in [item]]}
    print(json.dumps(report, sort_keys=True), flush=True)
    if findings - allowed:
        raise AdvisoryError('Unexcepted dependency advisory; inspect the reported IDs')
    return report


def scan(dart, cwd):
    dependencies = json.loads(run([dart, 'pub', 'deps', '--json'], cwd, capture=True))
    # No stored report or pub cache is accepted as the current advisory answer.
    check_advisories(dependencies, json.loads(EXCEPTIONS.read_text()))


def workspace_packages(dart):
    workspace = json.loads(run([dart, 'pub', 'workspace', 'list', '--json'], capture=True))
    if not isinstance(workspace, dict):
        raise ValueError('Invalid Dart workspace response')
    packages = workspace.get('packages')
    if not isinstance(packages, list) or not packages:
        raise ValueError('Missing Dart workspace package list')
    if any(not isinstance(package, dict) or not isinstance(package.get('path'), str)
           or not package['path'].strip() for package in packages):
        raise ValueError('Invalid workspace package path')
    paths = [Path(package['path']).resolve() for package in packages]
    if ROOT not in paths or len(paths) != len(set(paths)):
        raise ValueError('Invalid/duplicate workspace paths')
    if any(not path.is_relative_to(ROOT) or not (path / 'pubspec.yaml').is_file() for path in paths):
        raise ValueError('Workspace package outside checkout or missing manifest')
    return paths


def dart_job(dart):
    run([dart, '--version'])
    run([dart, 'pub', 'get'])  # Always resolve; an advisory warning can still exit 0.
    scan(dart, ROOT)
    for cwd in workspace_packages(dart):
        run([dart, 'format', '--output=none', '--set-exit-if-changed', 'lib', 'test'], cwd)
        run([dart, 'analyze'], cwd)
        run([dart, 'test', '--reporter', 'expanded'], cwd)
    for name in EXAMPLES:
        run([dart, 'run', f'example/{name}.dart'])
    with tempfile.TemporaryDirectory(prefix='deltasync-ci-offline-') as directory:
        for stage in ('reset', 'offline', 'reconnect'):
            run([dart, 'run', 'example/offline_reconciliation.dart', stage, directory])
        run([dart, 'run', 'example/commit_status_example.dart', str(Path(directory) / 'status')])
    run([dart, 'test', 'example/support/peer_link_test.dart', '--reporter', 'expanded'])


def flutter_job(dart, flutter):
    cwd = ROOT / 'example/flutter_mobile'
    run([flutter, '--version'])
    run([flutter, 'pub', 'get', '--enforce-lockfile'], cwd)
    scan(dart, cwd)
    run([dart, 'format', '--output=none', '--set-exit-if-changed', 'lib', 'test'], cwd)
    run([flutter, 'analyze'], cwd)
    run([flutter, 'test', '--reporter', 'expanded'], cwd)
    for target in ('lib/main.dart', 'lib/main_eight.dart'):
        run([flutter, 'build', 'apk', '--debug', '--target', target], cwd)


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('job', choices=('dart', 'flutter', 'policy'))
    parser.add_argument('--dart', default='dart')
    parser.add_argument('--flutter', default='flutter')
    args = parser.parse_args(argv)
    try:
        if args.job == 'dart':
            dart_job(args.dart)
        elif args.job == 'flutter':
            flutter_job(args.dart, args.flutter)
        else:
            run([sys.executable, '-B', '-m', 'unittest', 'discover', '-s', 'scripts/tests', '-v'])
            run([sys.executable, 'scripts/check_plan.py'])
            run(['git', 'diff', '--check'])
            run(['git', 'diff', '--check', 'HEAD^', 'HEAD'])
    except subprocess.CalledProcessError as error:
        return error.returncode if error.returncode > 0 else 2
    except AdvisoryError as error:
        print(str(error), file=sys.stderr)
        return 1
    except (ValueError, KeyError, OSError, urllib.error.URLError) as error:
        print(f'CI check unavailable/invalid: {error}', file=sys.stderr)
        return 2
    return 0


if __name__ == '__main__':
    sys.exit(main())
