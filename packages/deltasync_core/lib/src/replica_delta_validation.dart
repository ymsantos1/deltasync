part of 'replica.dart';

extension _ReplicaDeltaValidation on Replica {
  void _validateBatch(Delta delta) {
    // Merge is also the shared check for duplicate IDs with divergent payloads.
    const Delta.empty().merge(delta);
    final retained = <DeltaChange>[
      ..._lwwWinners,
      ..._gCounters.values.expand(
        (counter) => counter.exportChanges(requireSequences: false),
      ),
      ..._pnCounters.values.expand(
        (counter) => counter.exportChanges(requireSequences: false),
      ),
      ..._gSets.values.expand((set) => set.exportChanges()),
      ..._twoPSets.values.expand((set) => set.exportChanges()),
      ..._mvRegisters.values.expand((register) => register.exportChanges()),
      ..._orSets.values.expand((set) => set.exportChanges()),
    ];
    Delta(retained).merge(delta);
    final addressTypes = <String, CrdtKind>{};
    for (final address in _state.addresses) {
      addressTypes[address] = _state.kindAt(address)!;
    }
    for (final address in _gCounters.keys) {
      _validateAddressType(addressTypes, address, CrdtKind.gCounter);
    }
    for (final address in _pnCounters.keys) {
      _validateAddressType(addressTypes, address, CrdtKind.pnCounter);
    }
    for (final address in _gSets.keys) {
      _validateAddressType(addressTypes, address, CrdtKind.gSet);
    }
    for (final address in _twoPSets.keys) {
      _validateAddressType(addressTypes, address, CrdtKind.twoPSet);
    }
    for (final address in _mvRegisters.keys) {
      _validateAddressType(addressTypes, address, CrdtKind.mvRegister);
    }
    for (final address in _orSets.keys) {
      _validateAddressType(addressTypes, address, CrdtKind.orSet);
    }
    for (final address in _orMaps.keys) {
      _validateAddressType(addressTypes, address, CrdtKind.orMap);
    }
    for (final change in delta.changes) {
      if (change is LwwDelta<Object?>) {
        _validateMessageId(change.id, 'delta');
        _validateReplicaId(change.replicaId);
        if (change.key.isEmpty ||
            change.key.trim() != change.key ||
            change.timestamp.physicalMilliseconds < 0 ||
            change.timestamp.logical < 0 ||
            (change.deleted && change.value != null) ||
            (change.dot != null &&
                (change.dot!.counter <= 0 ||
                    change.dot!.replicaId != change.replicaId ||
                    change.dot!.crdtId != null))) {
          throw FormatException('Invalid LWW delta');
        }
        if (!change.deleted) {
          try {
            _validateJsonValue(change.value);
          } on ArgumentError {
            throw FormatException('Invalid LWW delta value');
          }
        }
        _validateAddressType(addressTypes, change.key, CrdtKind.lww);
      } else if (change is GCounterDelta) {
        _validateCounterDelta(
          id: change.id,
          replicaId: change.replicaId,
          crdtId: change.crdtId,
          dot: change.dot,
          type: CrdtKind.gCounter,
          expectedId: counterDeltaId(
            CrdtKind.gCounter.wireName,
            change.crdtId,
            change.replicaId,
            change.dot?.counter ?? 0,
          ),
        );
        if (change.dot == null || change.value < 0) {
          throw FormatException('Invalid G-Counter delta');
        }
        _validateAddressType(addressTypes, change.crdtId, CrdtKind.gCounter);
      } else if (change is PnCounterDelta) {
        _validateCounterDelta(
          id: change.id,
          replicaId: change.replicaId,
          crdtId: change.crdtId,
          dot: change.dot,
          type: CrdtKind.pnCounter,
          expectedId: counterDeltaId(
            CrdtKind.pnCounter.wireName,
            change.crdtId,
            change.replicaId,
            change.dot?.counter ?? 0,
          ),
        );
        if (change.dot == null || change.positive < 0 || change.negative < 0) {
          throw FormatException('Invalid PN-Counter delta');
        }
        _validateAddressType(addressTypes, change.crdtId, CrdtKind.pnCounter);
      } else if (change is GSetDelta) {
        _validateMessageId(change.id, 'G-Set delta');
        _validateReplicaId(change.replicaId);
        if (change.crdtId.isEmpty ||
            change.crdtId.trim() != change.crdtId ||
            change.crdtId.startsWith('legacy/') ||
            change.dot.counter <= 0 ||
            change.dot.replicaId != change.replicaId ||
            change.dot.crdtId != change.crdtId ||
            change.id !=
                crdtDeltaId(
                  CrdtKind.gSet.wireName,
                  change.crdtId,
                  change.replicaId,
                  change.dot.counter,
                )) {
          throw FormatException('Invalid G-Set delta identity');
        }
        for (final element in change.elements) {
          try {
            _validateJsonValue(element);
          } on ArgumentError {
            throw FormatException('Invalid G-Set element');
          }
        }
        _validateAddressType(addressTypes, change.crdtId, CrdtKind.gSet);
      } else if (change is TwoPSetDelta) {
        _validateMessageId(change.id, '2P-Set delta');
        _validateReplicaId(change.replicaId);
        if (change.crdtId.isEmpty ||
            change.crdtId.trim() != change.crdtId ||
            change.crdtId.startsWith('legacy/') ||
            change.dot.counter <= 0 ||
            change.dot.replicaId != change.replicaId ||
            change.dot.crdtId != change.crdtId ||
            change.id !=
                crdtDeltaId(
                  CrdtKind.twoPSet.wireName,
                  change.crdtId,
                  change.replicaId,
                  change.dot.counter,
                )) {
          throw FormatException('Invalid 2P-Set delta identity');
        }
        for (final element in change.elements) {
          try {
            _validateJsonValue(element);
          } on ArgumentError {
            throw FormatException('Invalid 2P-Set element');
          }
        }
        _validateAddressType(addressTypes, change.crdtId, CrdtKind.twoPSet);
      } else if (change is MvRegisterDelta) {
        _validateMessageId(change.id, 'MV-Register delta');
        _validateReplicaId(change.replicaId);
        if (change.crdtId.isEmpty ||
            change.crdtId.trim() != change.crdtId ||
            change.crdtId.startsWith('legacy/') ||
            change.dot.counter <= 0 ||
            change.dot.replicaId != change.replicaId ||
            change.dot.crdtId != change.crdtId ||
            change.id !=
                crdtDeltaId(
                  CrdtKind.mvRegister.wireName,
                  change.crdtId,
                  change.replicaId,
                  change.dot.counter,
                ) ||
            change.context.any(
              (dot) => dot.crdtId != change.crdtId || dot.counter <= 0,
            )) {
          throw FormatException(
            'Invalid MV-Register delta identity or context',
          );
        }
        try {
          _validateJsonValue(change.value);
        } on ArgumentError {
          throw FormatException('Invalid MV-Register value');
        }
        _validateAddressType(addressTypes, change.crdtId, CrdtKind.mvRegister);
      } else if (change is OrSetDelta) {
        _validateMessageId(change.id, 'OR-Set delta');
        _validateReplicaId(change.replicaId);
        if (change.crdtId.isEmpty ||
            change.crdtId.trim() != change.crdtId ||
            change.crdtId.startsWith('legacy/') ||
            change.dot.counter <= 0 ||
            change.dot.replicaId != change.replicaId ||
            change.dot.crdtId != change.crdtId ||
            change.id !=
                crdtDeltaId(
                  CrdtKind.orSet.wireName,
                  change.crdtId,
                  change.replicaId,
                  change.dot.counter,
                ) ||
            change.observedDots.any(
              (dot) =>
                  dot.replicaId.trim() != dot.replicaId ||
                  dot.counter <= 0 ||
                  dot.crdtId != change.crdtId,
            )) {
          throw FormatException('Invalid OR-Set delta identity or context');
        }
        if (change.action == OrSetAction.add) {
          try {
            _validateJsonValue(change.element);
          } on ArgumentError {
            throw FormatException('Invalid OR-Set element');
          }
        }
        _validateAddressType(addressTypes, change.crdtId, CrdtKind.orSet);
      } else if (change is OrMapDelta) {
        _validateMessageId(change.id, 'OR-Map delta');
        _validateReplicaId(change.replicaId);
        if (change.crdtId.isEmpty ||
            change.crdtId.trim() != change.crdtId ||
            change.crdtId.startsWith('legacy/') ||
            change.dot.counter <= 0 ||
            change.dot.replicaId != change.replicaId ||
            change.dot.crdtId != change.crdtId ||
            change.id !=
                crdtDeltaId(
                  CrdtKind.orMap.wireName,
                  change.crdtId,
                  change.replicaId,
                  change.dot.counter,
                ) ||
            change.observedDots.any(
              (dot) =>
                  dot.replicaId.trim() != dot.replicaId ||
                  dot.counter <= 0 ||
                  dot.crdtId != change.crdtId,
            )) {
          throw FormatException('Invalid OR-Map delta identity or context');
        }
        _validateAddressType(addressTypes, change.crdtId, CrdtKind.orMap);
      } else {
        throw FormatException('Unsupported CRDT delta type');
      }
    }
  }

  void _validateCounterDelta({
    required String id,
    required String replicaId,
    required String crdtId,
    required Dot? dot,
    required CrdtKind type,
    required String expectedId,
  }) {
    _validateMessageId(id, 'counter delta');
    _validateReplicaId(replicaId);
    if (crdtId.isEmpty || crdtId.trim() != crdtId) {
      throw FormatException('Invalid CRDT address');
    }
    final legacyAddress =
        dot != null && _isLegacyCounterId(id, replicaId, type, dot);
    if (dot == null ||
        dot.counter <= 0 ||
        dot.replicaId != replicaId ||
        dot.crdtId != crdtId ||
        (crdtId.startsWith('legacy/') && !legacyAddress) ||
        (id != expectedId && !legacyAddress)) {
      throw FormatException('Counter delta identity does not match address');
    }
  }

  bool _isLegacyCounterId(String id, String replicaId, CrdtKind type, Dot dot) {
    return dot.crdtId == 'legacy/${type.wireName}/$replicaId' &&
        id == '$replicaId:${type.wireName}:${dot.counter}';
  }

  void _validateAddressType(
    Map<String, CrdtKind> addressTypes,
    String crdtId,
    CrdtKind type,
  ) {
    final knownType = addressTypes[crdtId];
    if (knownType != null && knownType != type) {
      throw FormatException('CRDT address is already bound to another type');
    }
    addressTypes[crdtId] = type;
  }

  void _validateMessageId(String id, String kind) {
    if (id.isEmpty || id.trim() != id) {
      throw FormatException('Invalid $kind ID');
    }
  }

  void _validateReplicaId(String replicaId) {
    if (replicaId.isEmpty || replicaId.trim() != replicaId) {
      throw FormatException('Invalid replica ID');
    }
  }
}
