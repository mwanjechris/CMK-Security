import 'dart:io';

enum LockedFileType { image, video, audio, document, other }

class LockedFile {
  final String id;
  final String originalPath;
  final String vaultPath;
  final String fileName;
  final LockedFileType fileType;
  final int sizeBytes;
  final DateTime lockedAt;

  const LockedFile({
    required this.id,
    required this.originalPath,
    required this.vaultPath,
    required this.fileName,
    required this.fileType,
    required this.sizeBytes,
    required this.lockedAt,
  });

  static LockedFileType typeFromPath(String path) {
    final ext = path.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(ext)) {
      return LockedFileType.image;
    } else if (['mp4', 'mkv', 'avi', 'mov', 'webm'].contains(ext)) {
      return LockedFileType.video;
    } else if (['mp3', 'aac', 'wav', 'ogg', 'flac'].contains(ext)) {
      return LockedFileType.audio;
    } else if (['pdf', 'doc', 'docx', 'txt', 'xls', 'xlsx', 'ppt'].contains(ext)) {
      return LockedFileType.document;
    }
    return LockedFileType.other;
  }

  String get sizeLabel {
    if (sizeBytes < 1024) return '${sizeBytes}B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)}KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'originalPath': originalPath,
    'vaultPath': vaultPath,
    'fileName': fileName,
    'fileType': fileType.name,
    'sizeBytes': sizeBytes,
    'lockedAt': lockedAt.toIso8601String(),
  };

  factory LockedFile.fromJson(Map<String, dynamic> json) {
    return LockedFile(
      id: json['id'] as String,
      originalPath: json['originalPath'] as String,
      vaultPath: json['vaultPath'] as String,
      fileName: json['fileName'] as String,
      fileType: LockedFileType.values.firstWhere(
        (e) => e.name == json['fileType'],
        orElse: () => LockedFileType.other,
      ),
      sizeBytes: json['sizeBytes'] as int,
      lockedAt: DateTime.parse(json['lockedAt'] as String),
    );
  }

  Future<bool> get vaultFileExists async => File(vaultPath).exists();
}
