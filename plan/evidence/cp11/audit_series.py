"""Audit retained CP-11 attempts without selecting timings or computing statistics."""
import json
from pathlib import Path
import sys

if sys.flags.optimize:
    raise SystemExit('Audit requires assertions')

stage = Path(sys.argv[1])
attempts = json.loads((stage / 'execution.json').read_text())
accepted = []
excluded = []
pair_ids = set()
for attempt in attempts:
    directory = stage / attempt['name']
    if attempt.get('exitCode') != 0:
        excluded.append(attempt['name'])
        continue
    intent = json.loads((directory / 'intent.json').read_text())
    assert intent['pairId'] not in pair_ids
    pair_ids.add(intent['pairId'])
    assert intent['count'] == attempt['count']
    assert intent['pairIndex'] == attempt['index']
    assert intent['smoke'] == attempt['warmup']
    assert json.loads((directory / 'cleanup.json').read_text())['errors'] == []
    results = json.loads((directory / 'runs/results.json').read_text())
    order = ['on', 'off'] if attempt['index'] % 2 else ['off', 'on']
    assert [row['condition'] for row in results] == order
    for result in results:
        assert [(row['role'], row['phase']) for row in result['phases']] == [
            ('A', 'first'), ('B', 'first'), ('A', 'second')]
        for row in result['phases']:
            report = json.loads((directory / 'runs' / row['reportFile']).read_text())
            assert report['pairId'] == intent['pairId'] and report['passed']
            assert report['distinctRecordCount'] == attempt['count']
            assert report['allOtherValuesPreserved'] and report['pendingAfter'] == 0
            assert report['deltaSequence'] == attempt['count'] + 1
            assert all(event['status'] == 200 for event in row['routes'])
            if result['condition'] == 'on':
                assert report['metrics']['maxSamples'] == 8192
                assert all(report['metrics'][key] == 0 for key in
                           ('droppedSamples', 'droppedWindows', 'collectorFailures'))
            else:
                assert report['metrics'] is None
        prefix = directory / 'runs' / f'n{attempt["count"]}-{result["condition"]}'
        hub = json.loads(Path(str(prefix) + '-hub-state.json').read_text())
        a = json.loads((Path(str(prefix) + '-A-second') / 'public-inspection.json').read_text())
        b = json.loads((Path(str(prefix) + '-B-first') / 'public-inspection.json').read_text())
        assert len(hub['snapshot']['lww']) == attempt['count']
        assert hub['snapshot']['lww'] == a['lww'] == b['lww']
        assert hub['pending'] == a['pending'] == b['pending'] == []
        state = json.loads(Path(str(prefix) + '-device-state.json').read_text())
        for role in ('A', 'B'):
            assert state['before'][role]['batteryPercent'] >= 40
            assert state['before'][role]['usbPowered']
            assert state['before'][role]['thermalStatus'] == state['after'][role]['thermalStatus']
    accepted.append(attempt)
for count in (1, 1000):
    rows = [row for row in accepted if row['count'] == count]
    assert sorted(row['index'] for row in rows) == list(range(7))
summary = {'acceptedMainPairs': 12, 'acceptedWarmupPairs': 2,
           'excludedAttempts': excluded, 'mainPhases': 72}
print(json.dumps(summary))
