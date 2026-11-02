"""Cross-check elapsed and paired summaries directly against integer raw durations."""
import csv
from collections import defaultdict
from decimal import Decimal
import json
import math
from pathlib import Path
import sys

bundle, output = map(Path, sys.argv[1:])
raw = defaultdict(list)
pair_values = {}
for attempt in json.loads((bundle/'execution.json').read_text()):
    if attempt['warmup'] or attempt.get('exitCode') != 0:
        continue
    directory = bundle/attempt['name']/'runs'
    for result in json.loads((directory/'results.json').read_text()):
        for phase in result['phases']:
            report = json.loads((directory/phase['reportFile']).read_text())
            for stage in report['phases']:
                key = (str(attempt['count']), result['condition'], phase['role'], phase['phase'], stage['name'])
                value = Decimal(stage['elapsedUs'])/1000
                raw[key].append(value)
                pair_values[(key[0], key[2], key[3], key[4], attempt['index'], key[1])] = value


def compare(row, values):
    ordered = sorted(values)
    size = len(ordered)
    median = (ordered[(size-1)//2] + ordered[size//2])/2
    expected = dict(minimum=ordered[0], median=median, maximum=ordered[-1], p95=ordered[-1])
    if size != 6 or int(row['n']) != 6:
        raise ValueError('Unexpected number of paired rounds')
    for key, value in expected.items():
        if not math.isclose(float(row[key]), float(value), abs_tol=1e-8):
            raise ValueError(f'Calculation differs: {row}, {key}, {value}')


checked = 0
for row in csv.DictReader((output/'summary.csv').open()):
    if row['metric'] != 'elapsed_ms':
        continue
    key = tuple(row[k] for k in ('N', 'condition', 'role', 'phase', 'stage'))
    compare(row, raw[key])
    checked += 1
paired_checked = 0
for row in csv.DictReader((output/'paired-summary.csv').open()):
    if row['metric'] != 'difference_ms':
        continue
    prefix = tuple(row[k] for k in ('N', 'role', 'phase', 'stage'))
    values = [pair_values[prefix+(index, 'on')] - pair_values[prefix+(index, 'off')]
              for index in range(1, 7)]
    compare(row, values)
    paired_checked += 1
if checked != 32 or paired_checked != 16:
    raise ValueError('Incomplete summary coverage')
print(json.dumps({'elapsedGroupsChecked': checked, 'pairedGroupsChecked': paired_checked}))
