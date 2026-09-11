/// Hybrid Logical Clock timestamp.
///
/// Physical time orders normally; logical counter preserves deterministic
/// ordering when physical time is equal or moves backwards.
class HlcTimestamp implements Comparable<HlcTimestamp> {
  const HlcTimestamp(this.physicalMilliseconds, this.logical);

  final int physicalMilliseconds;
  final int logical;

  @override
  int compareTo(HlcTimestamp other) {
    final physical = physicalMilliseconds.compareTo(other.physicalMilliseconds);
    return physical == 0 ? logical.compareTo(other.logical) : physical;
  }

  Map<String, Object?> toJson() => {
    'physicalMilliseconds': physicalMilliseconds,
    'logical': logical,
  };

  factory HlcTimestamp.fromJson(Map<String, Object?> json) {
    final physical = json['physicalMilliseconds'];
    final logical = json['logical'];
    if (physical is! int || logical is! int || physical < 0 || logical < 0) {
      throw FormatException('Invalid HLC timestamp');
    }
    return HlcTimestamp(physical, logical);
  }

  @override
  bool operator ==(Object other) =>
      other is HlcTimestamp &&
      other.physicalMilliseconds == physicalMilliseconds &&
      other.logical == logical;

  @override
  int get hashCode => Object.hash(physicalMilliseconds, logical);
}

/// Mutable Hybrid Logical Clock used to create and observe timestamps.
class HlcClock {
  HlcClock({int Function()? nowMilliseconds})
    : _nowMilliseconds =
          nowMilliseconds ??
          (() => DateTime.now().toUtc().millisecondsSinceEpoch);

  final int Function() _nowMilliseconds;
  HlcTimestamp _last = const HlcTimestamp(0, 0);

  HlcTimestamp get current => _last;

  HlcTimestamp tick() {
    final physical = _nowMilliseconds();
    final nextPhysical = physical > _last.physicalMilliseconds
        ? physical
        : _last.physicalMilliseconds;
    final nextLogical = nextPhysical == _last.physicalMilliseconds
        ? _last.logical + 1
        : 0;
    return _last = HlcTimestamp(nextPhysical, nextLogical);
  }

  HlcTimestamp observe(HlcTimestamp remote) {
    final physical = _nowMilliseconds();
    final nextPhysical = [
      physical,
      _last.physicalMilliseconds,
      remote.physicalMilliseconds,
    ].reduce((first, second) => first > second ? first : second);
    final nextLogical =
        nextPhysical == _last.physicalMilliseconds &&
            nextPhysical == remote.physicalMilliseconds
        ? (_last.logical > remote.logical ? _last.logical : remote.logical) + 1
        : nextPhysical == _last.physicalMilliseconds
        ? _last.logical + 1
        : nextPhysical == remote.physicalMilliseconds
        ? remote.logical + 1
        : 0;
    return _last = HlcTimestamp(nextPhysical, nextLogical);
  }
}
