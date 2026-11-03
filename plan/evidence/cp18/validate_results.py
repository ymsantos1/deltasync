"""Independent Decimal calculation from raw Stopwatch integers for B timings."""
import csv
from decimal import Decimal
import json
import math
from pathlib import Path
import sys

root, output = map(Path, sys.argv[1:])
values = {}
for attempt in json.loads((root/'campaign/campaign.json').read_text()):
    if attempt['warmup']:
        continue
    phases = json.loads((root/'campaign'/attempt['directory']/'results.json').read_text())
    for phase in phases:
        if phase['step'] not in ('receive', 'idle'):
            continue
        duration = next(p['elapsedUs'] for p in phase['report']['phases'] if p['name']=='sync')
        metric = 'b_sync_ms' if phase['step']=='receive' else 'b_idle_ms'
        values[(metric, attempt['strategy'], attempt['slot'])] = Decimal(duration)/1000
count = 0
for row in csv.DictReader((output/'summary.csv').open()):
    if row['metric'] not in ('b_sync_ms', 'b_idle_ms'):
        continue
    data = sorted(values[(row['metric'], row['strategy'], i)] for i in range(1,7))
    for field, expected in [('minimum',data[0]),('maximum',data[-1]),('median',(data[2]+data[3])/2)]:
        if not math.isclose(float(row[field]), float(expected), abs_tol=1e-9):
            raise ValueError(f'{field} differs: {row}')
    count += 1
paired = 0
for row in csv.DictReader((output/'paired.csv').open()):
    if row['metric'] not in ('b_sync_ms','b_idle_ms'):
        continue
    a=values[(row['metric'],'snapshot',int(row['slot']))]
    b=values[(row['metric'],'incremental',int(row['slot']))]
    if not math.isclose(float(row['difference']),float(b-a),abs_tol=1e-9):
        raise ValueError('Paired duration differs')
    if not math.isclose(float(row['reduction_percent']),float(100*(a-b)/a),abs_tol=1e-9):
        raise ValueError('Paired percent differs')
    paired += 1
if (count,paired)!=(4,12):
    raise ValueError('Incomplete validation')
print(json.dumps({'timingGroupsChecked':count,'pairedTimingComparisonsChecked':paired}))
