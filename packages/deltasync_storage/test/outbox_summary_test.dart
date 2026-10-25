import 'package:deltasync_core/deltasync_core.dart';
import 'package:deltasync_storage/deltasync_storage.dart';
import 'package:test/test.dart';

void main() {
  test('summary rejects negative counts and derives total', () {
    expect(
      () => OutboxSummary(pendingCount: -1, sentCount: 0),
      throwsArgumentError,
    );
    expect(
      () => OutboxSummary(pendingCount: 0, sentCount: -1),
      throwsArgumentError,
    );
    expect(OutboxSummary(pendingCount: 2, sentCount: 3).totalCount, 5);
  });

  test(
    'Memory summary reads metadata without decoding delta payloads',
    () async {
      final storage = MemoryStorage();
      final change = Replica('summary')
          .setDelta('payload', List.filled(1000, 'data'));
      await storage.enqueue(_MetadataEntry(change));
      final summary = await storage.pendingSummary(
        'summary',
        recipientPeerId: 'peer',
      );
      expect(summary.pendingCount, 1);
      expect(summary.sentCount, 0);
    },
  );
}

class _MetadataEntry extends OutboxEntry {
  _MetadataEntry(DeltaChange change)
    : super(delta: Delta([change]), recipientPeerId: 'peer');
  @override
  Delta get delta => throw StateError('Payload must not be read by summary');
}
