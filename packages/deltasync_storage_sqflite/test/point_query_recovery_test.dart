import 'dart:io';

import 'package:deltasync_core/deltasync_core.dart';
import 'package:deltasync_storage_sqflite/deltasync_storage_sqflite.dart';
import 'package:deltasync_sync/deltasync_sync.dart';
import 'package:deltasync_transport/deltasync_transport.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:test/test.dart';

void main() {
  test('point query restores eight kinds from reopened SQLite', () async {
    sqfliteFfiInit();
    final directory = await Directory.systemTemp.createTemp('query-sqlite-');
    SqfliteReplicaStorage storage() => SqfliteReplicaStorage(
      databaseFactory: databaseFactoryFfi,
      databasePath: '${directory.path}/query.sqlite',
    );
    SyncEngine engine(SqfliteReplicaStorage store) => SyncEngine.withStorage(
      replica: Replica('query'),
      storage: store,
      transport: _OfflineTransport(),
    );
    final firstStore = storage();
    final first = engine(firstStore);
    try {
      await first.setDelta('lww', {
        'items': [1],
      });
      await first.incrementGCounter('g', 2);
      await first.decrementPnCounter('pn', 3);
      await first.addGSet('gs', 'a');
      await first.addTwoPSet('two', 'a');
      await first.writeMvRegister('mv', 'a');
      await first.addOrSet('os', 'a');
      await first.addOrMapKey('om', 'key');
      await first.addOrMapValue('om', 'key', 'a');
      final addresses = ['lww', 'g', 'pn', 'gs', 'two', 'mv', 'os', 'om'];
      final before = {
        for (final address in addresses) address: first.valueAt(address),
      };
      final ids = (await first.pendingDelta()).changes.map((c) => c.id).toSet();
      await expectLater(first.push(), throwsStateError);
      await first.dispose();
      await firstStore.close();
      final restoredStore = storage();
      final restored = engine(restoredStore);
      try {
        expect(() => restored.valueAt('lww'), throwsStateError);
        await restored.start();
        for (final entry in before.entries) {
          expect(restored.valueAt(entry.key), entry.value);
        }
        expect(
          (await restored.pendingDelta()).changes.map((c) => c.id).toSet(),
          ids,
        );
        expect(
          () => ((restored.valueAt('lww') as Map)['items'] as List).clear(),
          throwsUnsupportedError,
        );
      } finally {
        await restored.dispose();
        await restoredStore.close();
      }
    } finally {
      await first.dispose();
      await firstStore.close();
      await directory.delete(recursive: true);
    }
  });
}

class _OfflineTransport implements DeltaTransport {
  @override
  String get peerReplicaId => 'peer';
  @override
  Stream<DeltaEnvelope> get incoming => const Stream.empty();
  @override
  Future<void> send(DeltaEnvelope envelope) =>
      Future.error(StateError('offline'));
}
