"""Analyze the frozen CP-11 series, preserving pair and phase as sampling units."""
import argparse
import csv
import hashlib
import json
import math
from collections import defaultdict
from pathlib import Path
import statistics
import subprocess
import sys

INPUT_SHA = 'f31292331b17d2389313c52138c516724ea394bf11faea5fa4ef4a6205b295ac'


def stats(values):
    values = sorted(value for value in values if value is not None)
    if not values:
        return dict(n=0, minimum=None, median=None, maximum=None, p95=None)
    return dict(n=len(values), minimum=values[0], median=statistics.median(values),
                maximum=values[-1], p95=values[math.ceil(.95 * len(values)) - 1])


def delta(before, after):
    if before is None or after is None or before < 0 or after < 0:
        return None
    if after < before:
        raise ValueError('Counter decreased within a phase')
    return after - before


def paired(on, off):
    return on - off, 100 * (on - off) / off if off else None


def write_csv(path, rows):
    with path.open('w', newline='') as stream:
        writer = csv.DictWriter(stream, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)


def markdown_table(headers, rows):
    return '\n'.join(['| ' + ' | '.join(headers) + ' |',
                      '| ' + ' | '.join('---' for _ in headers) + ' |'] +
                     ['| ' + ' | '.join(str(value) for value in row) + ' |' for row in rows])


def format_value(value):
    return 'ausente' if value is None else f'{value:.3f}'


def summarize(rows, keys, metrics):
    groups = defaultdict(list)
    for row in rows:
        groups[tuple(row[key] for key in keys)].append(row)
    result = []
    for group, members in sorted(groups.items()):
        for metric, unit in metrics.items():
            value = dict(zip(keys, group))
            value.update(metric=metric, unit=unit, missing=sum(row[metric] is None for row in members),
                         **stats(row[metric] for row in members))
            result.append(value)
    return result


def analyze(bundle, output):
    data = (bundle / 'manifest.json').read_bytes()
    if hashlib.sha256(data).hexdigest() != INPUT_SHA:
        raise ValueError('Unexpected input manifest')
    manifest = json.loads(data)
    for row in manifest['files']:
        path = bundle / row['path']
        if path.stat().st_size != row['bytes'] or hashlib.sha256(path.read_bytes()).hexdigest() != row['sha256']:
            raise ValueError('Input changed: ' + row['path'])
    subprocess.run([sys.executable, str(Path(__file__).parent.parent / 'cp11/audit_series.py'),
                    str(bundle)], check=True, capture_output=True)
    attempts = json.loads((bundle / 'execution.json').read_text())
    phases, routes, timeline, excluded, warmups = [], [], [], [], []
    for attempt in attempts:
        if attempt['warmup']:
            warmups.append(attempt['name'])
            continue
        if attempt.get('exitCode') != 0:
            excluded.append(attempt['name'])
            continue
        directory = bundle / attempt['name']
        results = json.loads((directory / 'runs/results.json').read_text())
        intent = json.loads((directory / 'intent.json').read_text())
        order = 'on_first' if attempt['index'] % 2 else 'off_first'
        for condition in results:
            for phase in condition['phases']:
                report = json.loads((directory / 'runs' / phase['reportFile']).read_text())
                base = dict(N=attempt['count'], condition=condition['condition'], role=phase['role'],
                            phase=phase['phase'], pair=attempt['index'], order=order,
                            attempt=attempt['name'], pairId=intent['pairId'], report=phase['reportFile'])
                timeline.append(dict(base, hostStartUtc=phase['startedUtc'],
                                     deviceStartUtc=report['startedUtc'], deviceEndUtc=report['endedUtc']))
                for stage in report['phases']:
                    before, after = stage['countersBefore'], stage['countersAfter']
                    phases.append(dict(base, stage=stage['name'], elapsed_ms=stage['elapsedUs']/1000,
                                       cpu_ms=delta(before['cpuMs'], after['cpuMs']),
                                       pss_before_kb=before['pssKb'], pss_after_kb=after['pssKb'],
                                       uid_tx_bytes=delta(before['txBytes'], after['txBytes']),
                                       uid_rx_bytes=delta(before['rxBytes'], after['rxBytes'])))
                for event in phase['routes']:
                    routes.append(dict(base, route=event['route'],
                                       tx_body_bytes=event['txBodyBytes'], rx_body_bytes=event['rxBodyBytes'],
                                       proxy_ms=event['elapsedUs']/1000, status=event['status']))
    keys = ['N', 'condition', 'role', 'phase', 'stage']
    metrics = dict(elapsed_ms='ms', cpu_ms='ms_process', pss_before_kb='kB_API',
                   pss_after_kb='kB_API', uid_tx_bytes='bytes_UID', uid_rx_bytes='bytes_UID')
    summary = summarize(phases, keys, metrics)
    index = {(row['N'], row['role'], row['phase'], row['stage'], row['pair'], row['condition']): row
             for row in phases}
    pairs = []
    for key, on in index.items():
        if key[-1] != 'on':
            continue
        off = index[key[:-1] + ('off',)]
        difference, percent = paired(on['elapsed_ms'], off['elapsed_ms'])
        pairs.append(dict(N=on['N'], role=on['role'], phase=on['phase'], stage=on['stage'],
                          pair=on['pair'], order=on['order'], on_ms=on['elapsed_ms'], off_ms=off['elapsed_ms'],
                          difference_ms=difference, difference_percent=percent))
    pair_keys = ['N', 'role', 'phase', 'stage']
    pair_metrics = dict(difference_ms='ms_on_minus_off', difference_percent='percent_of_off')
    pair_summary = summarize(pairs, pair_keys, pair_metrics)
    by_order = summarize(pairs, pair_keys + ['order'], pair_metrics)
    network = summarize(routes, ['N', 'condition', 'role', 'phase', 'route'],
                        dict(tx_body_bytes='bytes_body', rx_body_bytes='bytes_body', proxy_ms='ms_proxy'))
    coverage = []
    for count in (1, 1000):
        for condition in ('on', 'off'):
            for role in ('A', 'B'):
                selected = [row for row in timeline if row['N'] == count and
                            row['condition'] == condition and row['role'] == role]
                coverage.append(dict(N=count, condition=condition, role=role, planned_pairs=6,
                                     measured_pairs=len({row['pair'] for row in selected}),
                                     valid_pairs=6, excluded_measured_pairs=0,
                                     phase_reports=len(selected)))
    output.mkdir(parents=True, exist_ok=False)
    tables = {'phases.csv': phases, 'routes.csv': routes, 'timeline.csv': timeline,
              'summary.csv': summary, 'paired.csv': pairs, 'paired-summary.csv': pair_summary,
              'paired-by-order.csv': by_order, 'network-summary.csv': network, 'coverage.csv': coverage}
    for name, rows in tables.items():
        write_csv(output/name, rows)
    elapsed = [row for row in summary if row['metric'] == 'elapsed_ms']
    sections = ['# Tabelas CP-12',
                'Geradas de CP-11. A=G52; B=G53; first=primeira abertura; second=pull posterior de A. '
                'n=6 por célula. Tempos em ms do Stopwatch do instrumento Dart. '
                'p95 usa nearest rank e equivale ao máximo; nenhuma estimativa de cauda estável.',
                '## Tempos por etapa',
                markdown_table(['N', 'Coletor', 'Aparelho', 'Abertura', 'Etapa', 'n', 'Mínimo', 'Mediana', 'Máximo/p95'],
                               [[r['N'], r['condition'], r['role'], r['phase'], r['stage'], r['n'],
                                 *[format_value(r[k]) for k in ('minimum', 'median', 'maximum')]] for r in elapsed]),
                '## Diferenças pareadas: ligado menos desligado',
                'Cada diferença usa o mesmo índice de par, aparelho, carga, abertura e etapa. '
                'Valores negativos indicam menor tempo observado no ligado, sem atribuir causalidade.',
                markdown_table(['N', 'Aparelho', 'Abertura', 'Etapa', 'n', 'Mínimo ms', 'Mediana ms', 'Máximo/p95 ms'],
                               [[r['N'], r['role'], r['phase'], r['stage'], r['n'],
                                 *[format_value(r[k]) for k in ('minimum', 'median', 'maximum')]]
                                for r in pair_summary if r['metric'] == 'difference_ms']),
                '## Recursos: medianas por etapa',
                'CPU é tempo acumulado do processo, não uso percentual. PSS é leitura da API Android em kB, '
                'com frequência limitada; não é pico nem heap Dart. UID conta todo tráfego do próprio UID. '
                'Dispersão e faltantes constam em summary.csv.',
                markdown_table(['N', 'Coletor', 'Aparelho', 'Abertura', 'Etapa', 'CPU ms', 'PSS após kB', 'UID TX bytes', 'UID RX bytes'],
                               [[r['N'], r['condition'], r['role'], r['phase'], r['stage'],
                                 *[format_value(next(x['median'] for x in summary if all(x[k] == r[k] for k in keys)
                                                    and x['metric'] == m))
                                   for m in ('cpu_ms', 'pss_after_kb', 'uid_tx_bytes', 'uid_rx_bytes')]] for r in elapsed]),
                '## Corpos HTTP por rota: medianas',
                'Push envia backlog de deltas; pull usa snapshot completo. São bytes de corpo JSON, '
                'sem cabeçalhos, TLS, TCP ou tarifação. Os intervalos completos estão em network-summary.csv.',
                markdown_table(['N', 'Coletor', 'Aparelho', 'Abertura', 'Rota', 'n', 'TX corpo bytes', 'RX corpo bytes'],
                               [[r['N'], r['condition'], r['role'], r['phase'], r['route'], r['n'], format_value(r['median']),
                                 format_value(next(x['median'] for x in network if all(x[k] == r[k]
                                                    for k in ('N', 'condition', 'role', 'phase', 'route'))
                                                   and x['metric'] == 'rx_body_bytes'))]
                                for r in network if r['metric'] == 'tx_body_bytes'])]
    (output/'tables.md').write_text('\n\n'.join(sections)+'\n')
    notes = dict(inputManifestSha256=INPUT_SHA, plannedMainPairs=12, attemptedMainPairs=13,
                 validMainPairs=12, excludedBeforeMeasurement=excluded, warmupPairs=warmups,
                 mainPhaseReports=len(timeline), stageRows=len(phases),
                 roundUnit='pair_index within N/role/phase/condition; operations are not repetitions',
                 percentile='nearest rank ceil(0.95*n); n=6 implies maximum',
                 adbDuration='unavailable: host end timestamp and am start duration not retained',
                 dartHeap='not measured', pssUnchangedStageRows=sum(row['pss_before_kb'] == row['pss_after_kb'] for row in phases),
                 metricsScope='elapsed_ms is Dart harness Stopwatch around one repository action; not ADB startup or pure core',
                 failures='only preflight exclusion; no measured failures')
    (output/'analysis.json').write_text(json.dumps(notes, indent=2)+'\n')
    return notes


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('bundle', type=Path)
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    print(json.dumps(analyze(args.bundle.resolve(), args.output.resolve()), indent=2))
