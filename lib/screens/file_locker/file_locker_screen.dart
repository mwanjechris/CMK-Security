import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/locked_file.dart';
import '../../providers/providers.dart';

class FileLockerScreen extends ConsumerWidget {
  const FileLockerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filesAsync = ref.watch(lockedFilesProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('File Vault'),
        backgroundColor: AppTheme.background,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _pickAndLockFile(context, ref),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add File'),
      ),
      body: filesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppTheme.error, size: 48),
              const SizedBox(height: 12),
              Text('$e', style: const TextStyle(color: Color(0xFF888899))),
            ],
          ),
        ),
        data: (files) {
          if (files.isEmpty) return const _EmptyFileVault();
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: files.length,
            itemBuilder: (context, i) => _FileItem(file: files[i]),
          );
        },
      ),
    );
  }

  Future<void> _pickAndLockFile(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: false);
    if (result == null || result.files.isEmpty) return;
    final path = result.files.first.path;
    if (path == null) return;

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Encrypting and locking file...')),
      );
    }

    try {
      await ref.read(lockedFilesProvider.notifier).lockFile(path);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File locked successfully!'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }
}

class _FileItem extends ConsumerWidget {
  final LockedFile file;

  const _FileItem({required this.file});

  IconData get _icon {
    switch (file.fileType) {
      case LockedFileType.image:
        return Icons.image_rounded;
      case LockedFileType.video:
        return Icons.video_file_rounded;
      case LockedFileType.audio:
        return Icons.audio_file_rounded;
      case LockedFileType.document:
        return Icons.description_rounded;
      case LockedFileType.other:
        return Icons.insert_drive_file_rounded;
    }
  }

  Color get _color {
    switch (file.fileType) {
      case LockedFileType.image:
        return const Color(0xFF00B4D8);
      case LockedFileType.video:
        return const Color(0xFFFF6B6B);
      case LockedFileType.audio:
        return const Color(0xFF2ED573);
      case LockedFileType.document:
        return const Color(0xFFFFD32A);
      case LockedFileType.other:
        return const Color(0xFF888899);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _color.withAlpha(30),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(_icon, color: _color, size: 24),
        ),
        title: Text(
          file.fileName,
          style: const TextStyle(color: AppTheme.onBackground, fontWeight: FontWeight.w500),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${file.sizeLabel} • ${_formatDate(file.lockedAt)}',
          style: const TextStyle(color: Color(0xFF666688), fontSize: 12),
        ),
        trailing: PopupMenuButton<String>(
          color: AppTheme.surfaceVariant,
          onSelected: (action) => _handleAction(context, ref, action),
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'unlock',
              child: Row(
                children: [
                  Icon(Icons.lock_open_rounded, color: AppTheme.primary, size: 18),
                  SizedBox(width: 8),
                  Text('Unlock & Restore', style: TextStyle(color: AppTheme.onBackground)),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_rounded, color: AppTheme.error, size: 18),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: AppTheme.error)),
                ],
              ),
            ),
          ],
          icon: const Icon(Icons.more_vert, color: Color(0xFF666688)),
        ),
      ),
    );
  }

  Future<void> _handleAction(BuildContext context, WidgetRef ref, String action) async {
    if (action == 'unlock') {
      try {
        final dir = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
        final path = await ref.read(lockedFilesProvider.notifier).unlockFile(file, dir.path);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Restored to $path'),
              backgroundColor: AppTheme.success,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
          );
        }
      }
    } else if (action == 'delete') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppTheme.surfaceVariant,
          title: const Text('Delete File?', style: TextStyle(color: AppTheme.onBackground)),
          content: Text(
            'This will permanently delete "${file.fileName}" from the vault.',
            style: const TextStyle(color: Color(0xFF888899)),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
      if (confirm == true) {
        await ref.read(lockedFilesProvider.notifier).removeFile(file);
      }
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _EmptyFileVault extends StatelessWidget {
  const _EmptyFileVault();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(Icons.lock_rounded, color: AppTheme.accent, size: 56),
            ),
            const SizedBox(height: 24),
            const Text(
              'File Vault is Empty',
              style: TextStyle(
                color: AppTheme.onBackground,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Tap "Add File" to encrypt and hide sensitive files. They\'ll be protected behind your lock.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF888899), fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
