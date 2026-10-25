import importlib.util
from datetime import date
import json
from pathlib import Path
import subprocess
import unittest
from unittest.mock import patch
from urllib.error import URLError

SPEC = importlib.util.spec_from_file_location('delta_ci', Path(__file__).parents[1] / 'ci.py')
ci = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(ci)
GRAPH = {'packages': [
    {'name': 'fixture', 'version': '1.0.0', 'source': 'root'},
    {'name': 'fake_package', 'version': '1.0.0', 'source': 'hosted'},
]}
FINDING = {'results': [{'vulns': [{'id': 'GHSA-fixture-only'}]}]}
EXCEPTION = {'package': 'fake_package', 'version': '1.0.0', 'id': 'GHSA-fixture-only',
             'reason': 'Fixture only; never a production dependency', 'expires': '2026-10-25'}
WORKSPACE = {'packages': [{'path': str(ci.ROOT / path)} for path in (
    '.', 'packages/deltasync_storage', 'packages/deltasync_transport')]}


class AdvisoryTests(unittest.TestCase):
    def test_underscore_prefixed_pub_package_is_scanned(self):
        graph = {'packages': [{'name': '_fe_analyzer_shared', 'version': '109.0.0', 'source': 'hosted'}]}
        queried = []
        def post(payload):
            queried.extend(payload['queries'])
            return {'results': [{}]}
        ci.check_advisories(graph, [], post=post)
        self.assertEqual(queried[0]['package']['name'], '_fe_analyzer_shared')

    def test_clean_and_known_advisory(self):
        report = ci.check_advisories(GRAPH, [], post=lambda _: {'results': [{}]})
        self.assertEqual(report['hostedPackages'], 1)
        with self.assertRaises(ci.AdvisoryError):
            ci.check_advisories(GRAPH, [], post=lambda _: FINDING)

    def test_exception_is_exact_justified_and_expires(self):
        report = ci.check_advisories(GRAPH, [EXCEPTION], post=lambda _: FINDING, today=date(2026, 10, 24))
        self.assertTrue(report['findings'][0]['excepted'])
        for changes in ({'expires': '2026-10-23'}, {'reason': ''}, {'version': '2.0.0'}):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                ci.check_advisories(GRAPH, [{**EXCEPTION, **changes}], post=lambda _: FINDING, today=date(2026, 10, 24))

    def test_network_and_invalid_response_cannot_pass(self):
        def offline(_):
            raise URLError('fixture network failure')
        with self.assertRaises(URLError):
            ci.check_advisories(GRAPH, [], post=offline)
        for payload in ({}, {'results': []}, {'results': [{'error': 'failure'}]},
                        {'error': 'failure', 'results': [{}]}, {'results': [{'message': 'failure'}]},
                        {'results': [{'vulns': 'invalid'}]}, {'results': [{'vulns': [{}]}]}):
            with self.subTest(payload=payload), self.assertRaises(ValueError):
                ci.check_advisories(GRAPH, [], post=lambda _: payload)

    def test_pagination_is_complete_and_cycle_rejected(self):
        calls = []
        def paginated(payload):
            calls.append(payload)
            if len(calls) == 1:
                return {'results': [{'next_page_token': 'next'}]}
            return FINDING
        with self.assertRaises(ci.AdvisoryError):
            ci.check_advisories(GRAPH, [], post=paginated)
        self.assertEqual(calls[1]['queries'][0]['page_token'], 'next')
        with self.assertRaises(ValueError):
            ci.check_advisories(GRAPH, [], post=lambda _: {'results': [{'next_page_token': 'same'}]})

    def test_unsupported_sources_and_bad_graph_fail(self):
        for graph in (None, {}, {'packages': []}, {'packages': [1]}, {'packages': [{'source': 'git'}]},
                      {'packages': [{'source': 'hosted', 'name': 'bad name', 'version': '1.0.0'}]}):
            with self.subTest(graph=graph), self.assertRaises(ValueError):
                ci.hosted_packages(graph)


class JobTests(unittest.TestCase):
    def test_workspace_paths_are_validated_from_dart_json(self):
        bad = (None, {'packages': []}, {'packages': [None]}, {'packages': [{'path': 42}]},
               {'packages': [{'path': '/tmp'}]},
               {'packages': [{'path': str(ci.ROOT)}, {'path': str(ci.ROOT)}]})
        for workspace in bad:
            with self.subTest(workspace=workspace), patch.object(ci, 'run', return_value=json.dumps(workspace)), self.assertRaises(ValueError):
                ci.workspace_packages('dart')

    def test_one_package_failure_stops_job_and_propagates_exit(self):
        commands = []
        def fake_run(command, cwd=ci.ROOT, **kwargs):
            commands.append((command, cwd))
            if command[1:3] == ['pub', 'deps']:
                return json.dumps(GRAPH)
            if command[1:4] == ['pub', 'workspace', 'list']:
                return json.dumps(WORKSPACE)
            if command[1:2] == ['test'] and cwd == ci.ROOT / 'packages/deltasync_storage':
                raise subprocess.CalledProcessError(9, command)
            return ''
        with patch.object(ci, 'run', side_effect=fake_run), patch.object(ci, 'check_advisories'):
            self.assertEqual(ci.main(['dart']), 9)
        self.assertFalse(any(cwd == ci.ROOT / 'packages/deltasync_transport' for _, cwd in commands))

    def test_pub_warning_exit_zero_still_fails_advisory_gate(self):
        def fake_run(command, cwd=ci.ROOT, **kwargs):
            if command[1:3] == ['pub', 'get']:
                return 'Got dependencies! Dependencies are affected by security advisories.'
            return json.dumps(GRAPH)
        with patch.object(ci, 'run', side_effect=fake_run), patch.object(ci, 'advisory_findings', return_value={('fake_package', '1.0.0', 'GHSA-fixture-only')}):
            self.assertEqual(ci.main(['dart']), 1)

    def test_network_failure_is_nonzero_even_after_successful_resolution(self):
        with patch.object(ci, 'run', return_value=json.dumps(GRAPH)), patch.object(ci, 'advisory_findings', side_effect=URLError('offline')):
            self.assertEqual(ci.main(['dart']), 2)

    def test_flutter_failure_stops_before_build_and_preserves_exit(self):
        commands = []
        def fake_run(command, cwd=ci.ROOT, **kwargs):
            commands.append(command)
            if command[1:] == ['test', '--reporter', 'expanded']:
                raise subprocess.CalledProcessError(7, command)
            return json.dumps(GRAPH)
        with patch.object(ci, 'run', side_effect=fake_run), patch.object(ci, 'check_advisories'):
            self.assertEqual(ci.main(['flutter']), 7)
        self.assertFalse(any('build' in command for command in commands))


if __name__ == '__main__':
    unittest.main()
