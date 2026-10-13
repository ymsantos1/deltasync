import 'dart:convert';

import '../delta.dart';
import '../delta_change.dart';
import '../g_counter.dart';
import '../g_set.dart';
import '../identity.dart';
import '../json/value.dart' show validateJsonValue;
import '../lww_delta.dart';
import '../mv_register.dart';
import '../or_map.dart';
import '../or_set.dart';
import '../pn_counter.dart';
import '../two_p_set.dart';
import 'contents.dart';

/// Checks a batch against retained identities and address bindings, without
/// modifying the replica. Candidate application still checks each CRDT's join.
void validateReplicaDeltaBatch(Delta delta, ReplicaContents contents) {
  // Merge is also the shared check for duplicate IDs with divergent payloads.
  const Delta.empty().merge(delta);
  Delta(contents.exportChanges(forValidation: true)).merge(delta);
  final addressTypes = contents.addressTypes;
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
          validateJsonInput(change.value);
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
          validateJsonInput(element);
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
          validateJsonInput(element);
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
              )) {
        throw FormatException('Invalid MV-Register delta identity or context');
      }
      // The delta constructor owns and validates its immutable compact context.
      // Its public context view expands prefixes and is not needed for validation.
      try {
        validateJsonInput(change.value);
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
          validateJsonInput(change.element);
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

void validateJsonInput(Object? value) {
  try {
    validateJsonValue(value);
  } on JsonUnsupportedObjectError {
    throw ArgumentError.value(value, 'value', 'must be JSON-compatible');
  } on UnsupportedError {
    throw ArgumentError.value(value, 'value', 'must be JSON-compatible');
  }
}
