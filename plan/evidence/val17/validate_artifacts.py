#!/usr/bin/env python3
"""Validate prepared 1.0.1 archives with a GET-only loopback Pub registry.

No publishing. Historical fixtures stay immutable. Temporary consumers use
hosted dependencies, never source paths or dependency_overrides.
"""
import argparse
import hashlib
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import io
import json
import os
from pathlib import Path
import re
import subprocess
import tarfile
import tempfile
import threading
import urllib.error
import urllib.parse
import urllib.request

ROOT = Path(__file__).resolve().parents[3]
R30 = ROOT / 'plan/evidence/r30'


def sha(data):
    return hashlib.sha256(data).hexdigest()


def manifest(text):
    """Parse only the flat scalar/two-level shape of our exported manifests."""
    result, current = {}, None
    for line in text.splitlines():
        if not line.strip() or line.lstrip().startswith('#'):
            continue
        match = re.fullmatch(r'(\w+):(?: (.*))?', line)
        if match:
            key, value = match.groups()
            result[key] = value.strip('"\'') if value else {}
            current = result[key]
            continue
        match = re.fullmatch(r'  (\w+): (.+)', line)
        if not match or not isinstance(current, dict):
            raise ValueError(f'Unexpected exported manifest line: {line}')
        current[match[1]] = match[2].strip('"\'')
    return result


def patch_files(text):
    result, path, lines = {}, None, []
    for line in text.splitlines():
        if line.startswith('diff --git '):
            if path:
                result[path] = '\n'.join(lines) + '\n'
            path, lines = None, []
        elif line.startswith('+++ b/'):
            path = line[6:]
        elif path and line.startswith('+'):
            lines.append(line[1:])
    if path:
        result[path] = '\n'.join(lines) + '\n'
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--release', required=True, type=Path)
    parser.add_argument('--report', required=True, type=Path)
    args = parser.parse_args()
    if args.report.resolve().is_relative_to(ROOT):
        parser.error('Reports belong outside the repository')
    release = args.release.resolve()
    inventory = json.loads((release/'inventory.json').read_text())
    temporary = Path(tempfile.mkdtemp(prefix='deltasync-val17-hosted-'))
    cache, consumer = temporary/'pub-cache', temporary/'consumer'
    consumer.mkdir()
    archives, specs = {}, {}
    for name, entries in inventory.items():
        raw = io.BytesIO()
        with tarfile.open(fileobj=raw, mode='w:gz') as archive:
            for relative, digest in entries.items():
                content = (release/name/relative).read_bytes()
                assert sha(content) == digest, (name, relative)
                if relative != '.pubignore':
                    info = tarfile.TarInfo(relative)
                    info.size, info.mtime, info.mode = len(content), 0, 0o644
                    archive.addfile(info, io.BytesIO(content))
        archives[name] = raw.getvalue()
        specs[name] = manifest((release/name/'pubspec.yaml').read_text())
        assert specs[name]['name'] == name and specs[name]['version'] == '1.0.1'

    requests, proxy_cache = [], {}

    class Handler(BaseHTTPRequestHandler):
        def log_message(self, *_):
            pass

        def do_POST(self):
            requests.append(dict(method='POST', path=self.path, status=405))
            self.send_error(405, 'Read-only fixture registry')

        def do_GET(self):
            route = urllib.parse.urlsplit(self.path).path
            parts = route.strip('/').split('/')
            name = parts[2] if len(parts) >= 3 and parts[:2] == ['api', 'packages'] else None
            if name in specs:
                version = dict(version='1.0.1', pubspec=specs[name],
                    archive_url=f'{base}/archives/{name}-1.0.1.tar.gz',
                    archive_sha256=sha(archives[name]), published='2026-10-25T00:00:00Z')
                if len(parts) == 3:
                    payload = dict(name=name, latest=version, versions=[version])
                elif parts[3:] == ['versions', '1.0.1']:
                    payload = version
                else:
                    self.send_error(404)
                    return
                data, kind = json.dumps(payload).encode(), 'application/json'
            elif route.startswith('/archives/'):
                name = route.removeprefix('/archives/').removesuffix('-1.0.1.tar.gz')
                if name not in archives:
                    self.send_error(404)
                    return
                data, kind = archives[name], 'application/octet-stream'
            elif route.startswith('/api/packages/'):
                try:
                    if self.path not in proxy_cache:
                        with urllib.request.urlopen('https://pub.dev'+self.path, timeout=30) as reply:
                            proxy_cache[self.path] = reply.read()
                    data, kind = proxy_cache[self.path], 'application/json'
                except (OSError, urllib.error.URLError):
                    self.send_error(502)
                    return
            else:
                self.send_error(404)
                return
            requests.append(dict(method='GET', path=self.path, status=200))
            self.send_response(200)
            self.send_header('Content-Type', kind)
            self.send_header('Content-Length', str(len(data)))
            self.end_headers()
            self.wfile.write(data)

    server = ThreadingHTTPServer(('127.0.0.1', 0), Handler)
    base = f'http://127.0.0.1:{server.server_port}'
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    environment = dict(os.environ, PUB_HOSTED_URL=base, PUB_CACHE=str(cache))
    records = []
    report = dict(task='VAL-17', release=str(release), temporary=str(temporary),
                  registry=base, records=records, requests=requests, status='running')

    def run(command, cwd, *, failure=False, extra=None):
        env = dict(environment, **(extra or {}))
        result = subprocess.run(command, cwd=cwd, env=env, text=True,
            stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        record = dict(command=list(map(str, command)), cwd=str(cwd),
                      exitCode=result.returncode, output=result.stdout)
        records.append(record)
        args.report.write_text(json.dumps(report, indent=2)+'\n')
        if (result.returncode == 0) == failure:
            raise RuntimeError(json.dumps(record))
        print(json.dumps(dict(command=record['command'], exitCode=result.returncode)), flush=True)
        return result.stdout

    try:
        files = patch_files((ROOT/'plan/evidence/r28-consumer.patch').read_text())
        for relative, text in files.items():
            if relative == 'pubspec.yaml':
                text = text.replace('^3.12.0', '^3.13.0').replace('^2.0.0', '1.0.1')
            path = consumer/relative
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(text)
        (consumer/'plan/evidence/r30').mkdir(parents=True)
        (consumer/'plan/evidence/r30/fixture_1_0_0.json').write_bytes((R30/'fixture_1_0_0.json').read_bytes())
        migrated = (ROOT/'plan/evidence/r39/consumer_test.dart.txt').read_text()
        marker = '  @override\n  Future<void> markSent('
        assert marker in migrated
        migrated = migrated.replace(marker,
            '  @override\n  Future<OutboxSummary> pendingSummary(String replicaId, {String? recipientPeerId}) =>\n'
            '      _memory.pendingSummary(replicaId, recipientPeerId: recipientPeerId);\n'
            + marker, 1)
        (consumer/'test/migrated_test.dart').write_text(migrated)
        guide = (ROOT/'docs/migracao-1.0.1.md').read_text()
        snippet = re.search(r'```dart\n(Future<void> importPending[\s\S]+?)\n```', guide)
        assert snippet
        (consumer/'test/import_pending.dart').write_text("import 'package:deltasync/deltasync.dart';\n"+snippet[1]+'\n')
        for task in ('r37','r38','r40','r41','r42'):
            (consumer/f'test/{task}_test.dart').write_bytes((ROOT/f'plan/evidence/{task}/consumer_test.dart.txt').read_bytes())
        run(['dart','pub','get'], consumer)
        config = json.loads((consumer/'.dart_tool/package_config.json').read_text())
        installed = {}
        for package in config['packages']:
            if package['name'] in inventory:
                path = Path(urllib.parse.unquote(urllib.parse.urlsplit(package['rootUri']).path))
                assert path.is_relative_to(cache) and not path.is_relative_to(ROOT)
                installed[package['name']] = str(path)
                for relative, digest in inventory[package['name']].items():
                    if relative != '.pubignore':
                        assert sha((path/relative).read_bytes()) == digest, (package['name'], relative)
        assert set(installed) == set(inventory)
        assert 'dependency_overrides' not in (consumer/'pubspec.yaml').read_text()
        provenance = dict(R39_EXPECT_SOURCE=installed['deltasync'],
                          R37_EXPECT_SOURCE=installed['deltasync'])
        run(['dart','format','test'], consumer)
        run(['dart','analyze','test'], consumer)
        run(['dart','test','--reporter','expanded'], consumer, extra=provenance)
        probes = [
            'PendingDeltaStore? removedStore;', 'MemoryPendingDeltaStore? removedMemory;',
            'Operation? removedOperation;', 'migrateLegacyOperation(null);',
            "r.set('key', 1);", "r.remove('key');", "e.set('key', 1);", "e.remove('key');",
            'Delta.crdt(const []);', 'const Delta.empty().crdtChanges;', 'entry.operationId;',
            'e.store;', 'SyncEngine(replica: r, transport: e.transport);',
            'SyncEngine(replica: r, storage: e.storage, transport: e.transport, store: Object());',
        ]
        (consumer/'removed.dart').write_text("import 'package:deltasync/deltasync.dart';\n"
            'void old(Replica r, SyncEngine e, OutboxEntry entry) {\n'+'\n'.join(probes)+'\n}\n')
        output = run(['dart','analyze','--format','machine','removed.dart'], consumer, failure=True)
        errors = {int(line.split('|')[4]) for line in output.splitlines() if line.startswith('ERROR|')}
        assert set(range(3, 3+len(probes))) <= errors
        (consumer/'event.dart').write_text("import 'package:deltasync/deltasync.dart';\n"
            'const event = SyncCommitEvent(origin: SyncCommitOrigin.local);\n'
            'class OldEvent implements SyncCommitEvent {\n'
            '@override SyncCommitOrigin get origin => SyncCommitOrigin.local;\n}\n'
            "class OldReplica extends Replica { OldReplica():super('old');\n"
            '@override void mergeSnapshotJson(Map<String,Object?> json) {}\n}\n')
        output = run(['dart','analyze','--format','machine','event.dart'], consumer, failure=True)
        for diagnostic in ('MISSING_REQUIRED_ARGUMENT','CONST_WITH_NON_CONST','NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER','INVALID_OVERRIDE'):
            assert diagnostic in output, diagnostic
        (consumer/'rollback.dart').write_bytes((ROOT/'plan/evidence/r39/rollback.dart.txt').read_bytes())
        run(['dart','pub','deps','--json'], consumer)
        for name in inventory:
            run(['dart','pub','get'], release/name)
            run(['dart','pub','publish','--dry-run'], release/name)
        report.update(status='passed', installed=installed,
            archiveSha256={name:sha(data) for name,data in archives.items()},
            noOverrides=True, negativeAliasCases=len(probes),
            consumer=str(consumer), pubCache=str(cache), uploads=0)
        assert not any(item['method'] != 'GET' for item in requests)
    except Exception as error:
        report.update(status='failed', error=str(error))
        raise
    finally:
        server.shutdown()
        server.server_close()
        args.report.write_text(json.dumps(report, indent=2)+'\n')


if __name__ == '__main__':
    main()
