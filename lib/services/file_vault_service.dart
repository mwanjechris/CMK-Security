import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:path_provider/path_provider.dart';
import '../models/locked_file.dart';
import 'storage_service.dart';

class FileVaultService {
  final StorageService _storage;
  static const _vaultDirName = '.cmk_vault';

  FileVaultService(this._storage);

  Future<Directory> _vaultDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/$_vaultDirName');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<enc.Key> _vaultKey() async {
    final stored = await _storage.getPin();
    String keySource = stored ?? _generateRandomKey();
    final padded = keySource.padRight(32, '0').substring(0, 32);
    return enc.Key.fromUtf8(padded);
  }

  String _generateRandomKey() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rng = Random.secure();
    return List.generate(32, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  Future<LockedFile> lockFile(String filePath) async {
    final original = File(filePath);
    if (!await original.exists()) throw Exception('File not found: $filePath');

    final bytes = await original.readAsBytes();
    final key = await _vaultKey();
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(key));
    final encrypted = encrypter.encryptBytes(bytes, iv: iv);

    final vaultDir = await _vaultDir();
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final vaultPath = '${vaultDir.path}/$id.cmkv';

    final outFile = File(vaultPath);
    final combined = Uint8List(16 + encrypted.bytes.length);
    combined.setRange(0, 16, iv.bytes);
    combined.setRange(16, combined.length, encrypted.bytes);
    await outFile.writeAsBytes(combined);

    final lockedFile = LockedFile(
      id: id,
      originalPath: filePath,
      vaultPath: vaultPath,
      fileName: filePath.split('/').last,
      fileType: LockedFile.typeFromPath(filePath),
      sizeBytes: bytes.length,
      lockedAt: DateTime.now(),
    );

    final existing = await _storage.getLockedFiles();
    existing.add(lockedFile);
    await _storage.saveLockedFiles(existing);

    await original.delete();
    return lockedFile;
  }

  Future<String> unlockFile(LockedFile lockedFile, String destinationDir) async {
    final vaultFile = File(lockedFile.vaultPath);
    if (!await vaultFile.exists()) throw Exception('Vault file not found');

    final combined = await vaultFile.readAsBytes();
    final iv = enc.IV(combined.sublist(0, 16));
    final encryptedBytes = combined.sublist(16);

    final key = await _vaultKey();
    final encrypter = enc.Encrypter(enc.AES(key));
    final encrypted = enc.Encrypted(encryptedBytes);
    final decrypted = encrypter.decryptBytes(encrypted, iv: iv);

    final outPath = '$destinationDir/${lockedFile.fileName}';
    await File(outPath).writeAsBytes(decrypted);
    return outPath;
  }

  Future<void> removeFromVault(LockedFile lockedFile) async {
    final vaultFile = File(lockedFile.vaultPath);
    if (await vaultFile.exists()) await vaultFile.delete();

    final existing = await _storage.getLockedFiles();
    existing.removeWhere((f) => f.id == lockedFile.id);
    await _storage.saveLockedFiles(existing);
  }
}
