import 'dart:collection';
import 'dart:io';

import 'package:deltasync_core/deltasync_core.dart';
import 'package:deltasync_core/src/replica/contents.dart';
import 'package:deltasync_core/src/replica/delta_validation.dart';

// Fixed, bounded workloads for R-21. Counts measure public context expansion and
// JSON input reads, not total heap allocations. Times are local observations.
void main(List<String> args) {
  const iterations = 20;
  const prefix = 5000;
  const sparse = [5002, 5010];
  const fields = 1000;
  final context = [
    for (var counter = 1; counter <= prefix; counter++)
      Dot(replicaId: 'origin', counter: counter, crdtId: 'field'),
    for (final counter in sparse)
      Dot(replicaId: 'origin', counter: counter, crdtId: 'field'),
  ];
  final change = _ObservedMvDelta(context);
  final delta = Delta([change]);
  final contents = ReplicaContents('receiver');
  final input = _ObservedList(List<Object?>.generate(5000, (i) => i));
  final json = {
    'data': input,
    'nested': [
      {'enabled': true, 'text': 'draft'},
    ],
  };
  final state = ReplicaState();
  for (var i = 0; i < fields; i++) {
    state.applyDelta(
      LwwDelta<Object?>(
        key: 'field/$i',
        id: 'device:delta:${i + 1}',
        replicaId: 'device',
        timestamp: HlcTimestamp(1000, i),
        value: {'values': List<int>.generate(16, (i) => i)},
      ),
    );
  }
  print(
    'stage=${args.firstOrNull ?? "current"}, os=${Platform.operatingSystem}, '
    'dart=${Platform.version.split(" ").first}, iterations=$iterations',
  );
  final mvTimer = Stopwatch()..start();
  for (var i = 0; i < iterations; i++) {
    validateReplicaDeltaBatch(delta, contents);
  }
  mvTimer.stop();
  print(
    'mv: prefix=$prefix, sparse=${sparse.length}, logical=${context.length}, '
    'expansions=${change.expansions}, materialized-dots=${change.materialized}, '
    'elapsed-us=${mvTimer.elapsedMicroseconds}',
  );
  final jsonTimer = Stopwatch()..start();
  for (var i = 0; i < iterations; i++) {
    validateJsonInput(json);
  }
  jsonTimer.stop();
  print(
    'json: elements=${input.length}, input-reads=${input.reads}, '
    'elapsed-us=${jsonTimer.elapsedMicroseconds}',
  );
  final queryTimer = Stopwatch()..start();
  var queriedValues = 0;
  for (var i = 0; i < iterations; i++) {
    final value = state['field/0'] as Map;
    queriedValues += (value['values'] as List).length;
  }
  queryTimer.stop();
  print(
    'query: fields=$fields, returned-elements=$queriedValues, '
    'elapsed-us=${queryTimer.elapsedMicroseconds}',
  );
}

class _ObservedMvDelta extends MvRegisterDelta {
  _ObservedMvDelta(Iterable<Dot> context)
    : super(
        id: crdtDeltaId('mv-register', 'field', 'origin', 5011),
        replicaId: 'origin',
        crdtId: 'field',
        dot: const Dot(replicaId: 'origin', counter: 5011, crdtId: 'field'),
        value: 'next',
        context: context,
      );
  int expansions = 0;
  int materialized = 0;
  @override
  List<Dot> get context {
    final dots = super.context;
    expansions++;
    materialized += dots.length;
    return dots;
  }
}

class _ObservedList extends ListBase<Object?> {
  _ObservedList(this._items);
  final List<Object?> _items;
  int reads = 0;
  @override
  int get length => _items.length;
  @override
  set length(int value) => _items.length = value;
  @override
  Object? operator [](int index) {
    reads++;
    return _items[index];
  }

  @override
  void operator []=(int index, Object? value) => _items[index] = value;
}
