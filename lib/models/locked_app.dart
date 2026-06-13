import 'dart:typed_data';

class LockedApp {
  final String packageName;
  final String appName;
  final bool isHidden;
  final DateTime lockedAt;

  const LockedApp({
    required this.packageName,
    required this.appName,
    this.isHidden = false,
    required this.lockedAt,
  });

  LockedApp copyWith({
    String? packageName,
    String? appName,
    bool? isHidden,
    DateTime? lockedAt,
  }) {
    return LockedApp(
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      isHidden: isHidden ?? this.isHidden,
      lockedAt: lockedAt ?? this.lockedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'packageName': packageName,
    'appName': appName,
    'isHidden': isHidden,
    'lockedAt': lockedAt.toIso8601String(),
  };

  factory LockedApp.fromJson(Map<String, dynamic> json) {
    return LockedApp(
      packageName: json['packageName'] as String,
      appName: json['appName'] as String,
      isHidden: (json['isHidden'] as bool?) ?? false,
      lockedAt: DateTime.parse(json['lockedAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LockedApp && packageName == other.packageName;

  @override
  int get hashCode => packageName.hashCode;
}

class InstalledApp {
  final String packageName;
  final String appName;
  final List<int>? iconBytes;

  const InstalledApp({
    required this.packageName,
    required this.appName,
    this.iconBytes,
  });

  factory InstalledApp.fromMap(Map<dynamic, dynamic> map) {
    List<int>? icon;
    final raw = map['icon'];
    if (raw != null) {
      if (raw is List) {
        icon = List<int>.from(raw);
      } else if (raw is Uint8List) {
        icon = raw.toList();
      }
    }
    return InstalledApp(
      packageName: map['packageName'] as String,
      appName: map['appName'] as String,
      iconBytes: icon,
    );
  }
}
