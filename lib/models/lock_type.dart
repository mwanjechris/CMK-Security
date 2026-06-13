enum LockType {
  pin,
  pattern,
  biometric;

  String get label {
    switch (this) {
      case LockType.pin:
        return 'PIN';
      case LockType.pattern:
        return 'Pattern';
      case LockType.biometric:
        return 'Biometric';
    }
  }

  String get description {
    switch (this) {
      case LockType.pin:
        return 'Use a 4-6 digit PIN to unlock';
      case LockType.pattern:
        return 'Draw a pattern on a 3×3 grid';
      case LockType.biometric:
        return 'Use fingerprint or face recognition';
    }
  }

  String get iconAsset {
    switch (this) {
      case LockType.pin:
        return 'pin';
      case LockType.pattern:
        return 'pattern';
      case LockType.biometric:
        return 'biometric';
    }
  }

  String toJson() => name;

  static LockType fromJson(String value) {
    return LockType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => LockType.pin,
    );
  }
}
