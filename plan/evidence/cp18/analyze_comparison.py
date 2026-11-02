"""Audit the new paired comparison and generate reproducible metrics/tables."""
import csv
import hashlib
import json
from pathlib import Path
import statistics
import sys


def describe(values):
    values = sorted(values)
    return dict(n=len(values), median=statistics.median(values),
                minimum=values[0], maximum=values[-1])


def reduction(snapshot, incremental):
    return 100 * (snapshot - incremental) / snapshot if snapshot else None


def write_csv(path, rows):
    with path.open('w', newline='') as stream:
        writer = csv.DictWriter(stream, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)


def analyze(root, output):
    campaign = root/'campaign'
    attempts = json.loads((campaign/'campaign.json').read_text())
    if len(attempts) != 14 or any(a['status'] != 'passed' for a in attempts):
        raise ValueError('Campaign incomplete; do not select only successful trials')
    if json.loads((campaign/'cleanup.json').read_text())['errors']:
        raise ValueError('Cleanup not complete')
    initial = json.loads((root/'inputs/hub-state.json').read_text())['snapshot']['lww']
    metrics, routes, times = [], [], []
    edits = {}
    for attempt in attempts:
        directory = campaign/attempt['directory']
        before = json.loads((directory/'initial-hub-state.json').read_text())
        if before['snapshot']['lww'] != initial or before['pending']:
            raise ValueError('Initial states differ')
        state = json.loads((directory/'device-state.json').read_text())
        if any(state['before'][r]['thermalStatus'] != state['after'][r]['thermalStatus']
               or not state['before'][r]['usbPowered'] or state['before'][r]['batteryPercent'] < 40
               for r in ('A', 'B')):
            raise ValueError('Device conditions differ')
        phases = json.loads((directory/'results.json').read_text())
        if [(p['role'], p['step']) for p in phases] != [
                ('A', 'bootstrap'), ('B', 'bootstrap'), ('A', 'edit'),
                ('B', 'receive'), ('B', 'idle')]:
            raise ValueError('Trial phase sequence differs')
        measured = {p['step']: p for p in phases if p['measured']}
        final = json.loads((directory/'final-hub-state.json').read_text())
        a = json.loads((directory/'A-edit/public-inspection.json').read_text())
        b = json.loads((directory/'B-receive/public-inspection.json').read_text())
        idle = json.loads((directory/'B-idle/public-inspection.json').read_text())
        if not (a['lww'] == b['lww'] == idle['lww'] == final['snapshot']['lww']):
            raise ValueError('Final LWW states differ')
        if len(a['lww']) != 1000 or any(x['pending'] for x in (a, b, idle, final)):
            raise ValueError('Keys or pending differ')
        changed = [k for k in initial if initial[k] != a['lww'][k]]
        if len(changed) != 1:
            raise ValueError('Expected precisely one changed winner')
        value = measured['edit']['report']['expectedLocalEdit']
        if len(value.encode()) != 64 or a['lww'][changed[0]]['winner']['value'] != {'text': value}:
            raise ValueError('Unexpected winner/value')
        edits.setdefault(attempt['slot'], set()).add(value)
        base = dict(slot=attempt['slot'], warmup=attempt['warmup'], strategy=attempt['strategy'],
                    order=' then '.join(attempt['order']), directory=attempt['directory'])
        for phase in phases:
            report = phase['report']
            if not report['passed'] or report['pendingBeforeEdit'] or report['pendingAfter']:
                raise ValueError('Client report failed')
            if report['pendingAfterEdit'] != (1 if phase['step'] == 'edit' else 0):
                raise ValueError('Unexpected new pending count')
            for event in phase['routes']:
                capture = event['captureId']
                response = (directory/f'http-{capture}-response.json').read_bytes()
                request = directory/f'http-{capture}-request.json'
                if len(response) != event['rxBodyBytes'] or event['status'] != 200:
                    raise ValueError('Response bytes/status mismatch')
                if event['txBodyBytes'] and len(request.read_bytes()) != event['txBodyBytes']:
                    raise ValueError('Request byte mismatch')
                expected = 1000 if attempt['strategy'] == 'snapshot' or phase['step'] == 'bootstrap' else (
                    1 if phase['step'] == 'receive' else 0)
                if event['route'] == '/sync/pull':
                    if len(json.loads(response)['delta']['delta']['changes']) != expected:
                        raise ValueError('Unexpected remote change count')
                if event['route'] == '/sync/push':
                    if len(json.loads(request.read_bytes())['delta']['delta']['changes']) != 1:
                        raise ValueError('Push is not a single change')
                if event['route'] == '/sync/ack':
                    if len(json.loads(request.read_bytes())['changeIds']) != expected:
                        raise ValueError('Unexpected ACK count')
                routes.append(dict(base, role=phase['role'], step=phase['step'],
                                   measured=phase['measured'], **event))
            for timer in report['phases']:
                times.append(dict(base, role=phase['role'], step=phase['step'],
                                  measured=phase['measured'], stage=timer['name'],
                                  elapsed_ms=timer['elapsedUs']/1000,
                                  cpu_ms=timer['countersAfter']['cpuMs']-timer['countersBefore']['cpuMs']))
        def body_sum(events):
            return sum(e['txBodyBytes'] + e['rxBodyBytes'] for e in events)
        def sync(step):
            return next(p['elapsedUs']/1000 for p in measured[step]['report']['phases'] if p['name']=='sync')
        edit_routes, receive_routes, idle_routes = [measured[k]['routes'] for k in ('edit', 'receive', 'idle')]
        cycle_routes = edit_routes + receive_routes
        metrics.append(dict(base,
            a_push_request_bytes=sum(e['txBodyBytes'] for e in edit_routes if e['route']=='/sync/push'),
            b_pull_response_bytes=sum(e['rxBodyBytes'] for e in receive_routes if e['route']=='/sync/pull'),
            b_ack_request_bytes=sum(e['txBodyBytes'] for e in receive_routes if e['route']=='/sync/ack'),
            cycle_ack_request_bytes=sum(e['txBodyBytes'] for e in cycle_routes if e['route']=='/sync/ack'),
            cycle_total_body_bytes=body_sum(cycle_routes),
            cycle_distribution_body_bytes=body_sum([e for e in cycle_routes if e['route']!='/sync/push']),
            b_idle_body_bytes=body_sum(idle_routes),
            all_measured_body_bytes=body_sum(cycle_routes+idle_routes),
            b_received_changes=next(e['pullChangeCount'] for e in receive_routes if e['route']=='/sync/pull'),
            b_idle_changes=next(e['pullChangeCount'] for e in idle_routes if e['route']=='/sync/pull'),
            a_sync_ms=sync('edit'), b_sync_ms=sync('receive'), b_idle_ms=sync('idle'),
            sum_a_b_sync_ms=sync('edit')+sync('receive')))
    if any(len(values) != 1 for values in edits.values()):
        raise ValueError('Paired edited texts differ')
    for slot in range(7):
        rows = [r for r in metrics if r['slot'] == slot]
        if len(rows) != 2 or {r['strategy'] for r in rows} != {'snapshot', 'incremental'}:
            raise ValueError('Paired slots incomplete')
        # Thermal status must also match across protocols inside each pair.
        conditions = [json.loads((campaign/r['directory']/'device-state.json').read_text()) for r in rows]
        if any(conditions[0]['before'][r]['thermalStatus'] != conditions[1]['before'][r]['thermalStatus'] for r in ('A','B')):
            raise ValueError('Pair thermal condition changed')
    names = list(metrics[0])[5:]
    main = [r for r in metrics if not r['warmup']]
    summary, paired = [], []
    for name in names:
        for strategy in ('snapshot', 'incremental'):
            summary.append(dict(metric=name, strategy=strategy,
                                **describe([r[name] for r in main if r['strategy']==strategy])))
        for slot in range(1, 7):
            a = next(r for r in main if r['slot']==slot and r['strategy']=='snapshot')
            b = next(r for r in main if r['slot']==slot and r['strategy']=='incremental')
            paired.append(dict(metric=name, slot=slot, order=a['order'], snapshot=a[name],
                               incremental=b[name], difference=b[name]-a[name], reduction_percent=reduction(a[name], b[name])))
    output.mkdir(parents=True, exist_ok=False)
    for file, rows in [('runs.csv', metrics), ('routes.csv', routes), ('timings.csv', times),
                       ('summary.csv', summary), ('paired.csv', paired)]:
        write_csv(output/file, rows)
    labels = [('b_pull_response_bytes','Bytes recebidos por B no pull'),
              ('b_ack_request_bytes','Bytes de ACK de B'),
              ('cycle_ack_request_bytes','Bytes de ACK de A+B'),
              ('cycle_total_body_bytes','Total de corpos HTTP do ciclo A+B'),
              ('cycle_distribution_body_bytes','Distribuição remota do ciclo A+B'),
              ('b_sync_ms','Sync de B (ms)'), ('b_idle_body_bytes','Consulta sem novidades de B (bytes)'),
              ('b_idle_ms','Consulta sem novidades de B (ms)')]
    lines=['# Comparação observada CP-18', '',
           'Seis pares válidos; aquecimentos e bootstrap excluídos. Tempos: mediana [mínimo; máximo]. '
           'Redução: mediana de 100×(snapshot−incremental)/snapshot calculada dentro de cada par. '
           'Redução negativa indica aumento observado. Sem inferência de significância.', '',
           '| Métrica | Snapshot | Incremental | Redução pareada % |', '| --- | ---: | ---: | ---: |']
    for name, label in labels:
        cells=[]
        for strategy in ('snapshot','incremental'):
            row=next(r for r in summary if r['metric']==name and r['strategy']==strategy)
            cells.append(f"{row['median']:.3f} [{row['minimum']:.3f}; {row['maximum']:.3f}]")
        percent=statistics.median(r['reduction_percent'] for r in paired if r['metric']==name)
        lines.append(f'| {label} | {cells[0]} | {cells[1]} | {percent:.3f} |')
    lines += ['| Convergência nos ensaios físicos | 6/6 | 6/6 | — |', '',
              'Ciclo A+B inclui A/editar/sync e B/receber/sync; a consulta sem novidades é separada. '
              'Distribuição remota exclui request/response de /sync/push, incluindo pulls e ACKs de A+B. '
              'Não são bytes tarifados. A soma de durações A+B não é tempo de relógio do ciclo completo.']
    (output/'table.md').write_text('\n'.join(lines)+'\n')
    audit=dict(validPairs=6, validStrategies=12, warmupStrategies=2,
               measuredReports=36, bootstrapReports=28, physicalConvergence='all paired strategies',
               sourceHash=hashlib.sha256((root/'frozen-inputs.json').read_bytes()).hexdigest())
    (output/'audit.json').write_text(json.dumps(audit,indent=2)+'\n')
    print(json.dumps(audit))


if __name__=='__main__':
    analyze(Path(sys.argv[1]).resolve(), Path(sys.argv[2]).resolve())
