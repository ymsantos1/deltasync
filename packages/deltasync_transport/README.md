# deltasync_transport

Version 1.0.1 requires upgrade review despite its patch number. The release
aligns all DeltaSync packages and includes intentional source breaks; see the
[migration guide](https://github.com/ymsantos1/deltasync/blob/main/docs/migracao-1.0.1.md).

Pure Dart transport contracts and versioned envelopes for DeltaSync.
Add `deltasync_transport: ^1.0.1` to your dependencies.

- Implement `DeltaTransport` to send envelopes and expose an incoming stream.
- Implement `AcknowledgingDeltaTransport` when the protocol supports a response
  confirming remote application and persistence.
- Use `DeltaEnvelope` and `DeltaAcknowledgement` JSON codecs at network boundaries.
  Sender, recipient, ACK stage and change IDs are validated explicitly.

With `SyncEngine`, route received envelopes through `receiveEnvelope`. With
`IncomingAcknowledgingDeltaTransport`, the engine sends the ACK through the
adapter after commit; otherwise send the returned ACK after the future succeeds.
An ACK for receipt
alone must not remove pending changes; outbox removal requires the expected
peer's `appliedAndPersisted` acknowledgement.

One engine addresses a fixed peer; this ACK does not prove delivery to other
participants. Codec validation is not authentication. Bound network waits with
timeouts, let accepted operations drain on engine disposal, then close resources
owned by the concrete adapter. DeltaTransport itself has no close requirement.
Scheduling pushes/retries and retaining installation/peer identity belong to the
application; the engine does not create a network worker.

This package supplies no HTTP/WebSocket server, authentication, peer discovery,
encryption or production network policy. Consumers own those choices and retry
policy. See a small transport adapter in the
[facade example](https://github.com/ymsantos1/deltasync/blob/main/example/deltasync_example.dart)
and an existing application in the
[Compass fork](https://github.com/ymsantos1/samples-for-tcc).
