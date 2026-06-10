import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../constants/app_constants.dart';
import 'logger.dart';

class FileUtils {
  FileUtils._();

  /// Get the downloads directory path
  static Future<Directory> getDownloadsDirectory() async {
    Directory dir;

    if (Platform.isAndroid) {
      // Use external storage on Android
      final extDir = await getExternalStorageDirectory();
      dir = Directory(
        '${extDir?.path ?? (await getApplicationDocumentsDirectory()).path}'
        '/${AppConstants.downloadFolderName}',
      );
    } else if (Platform.isIOS) {
      final docDir = await getApplicationDocumentsDirectory();
      dir = Directory('${docDir.path}/${AppConstants.downloadFolderName}');
    } else {
      final docDir = await getApplicationDocumentsDirectory();
      dir = Directory('${docDir.path}/${AppConstants.downloadFolderName}');
    }

    if (!await dir.exists()) {
      await dir.create(recursive: true);
      AppLogger.info('Created downloads directory: ${dir.path}');
    }

    return dir;
  }

  /// Build a sanitized file path for a download
  static Future<String> buildFilePath(
    String fileName,
    String extension,
  ) async {
    final dir = await getDownloadsDirectory();
    final sanitized = sanitizeFileName(fileName);
    final baseName = '${sanitized}_${DateTime.now().millisecondsSinceEpoch}';
    return '${dir.path}/$baseName.$extension';
  }

  /// Sanitize file name by removing invalid characters
  static String sanitizeFileName(String name) {
    final sanitized = name
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .trim();

    // Limit length to avoid OS limits
    if (sanitized.length > 100) {
      return sanitized.substring(0, 100);
    }
    return sanitized.isEmpty ? 'video' : sanitized;
  }

  /// Check available storage space in bytes
  static Future<int> getAvailableSpace() async {
    try {
      final dir = await getDownloadsDirectory();
      final stat = await dir.stat();
      // This is a simplified check; real implementation would use statvfs
      return stat.size;
    } catch (e) {
      AppLogger.warning('Failed to get available space: $e');
      return 0;
    }
  }

  /// Check if file exists at path
  static Future<bool> fileExists(String path) async {
    return File(path).exists();
  }

  /// Delete file at path
  static Future<bool> deleteFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      AppLogger.error('Failed to delete file: $path', e);
      return false;
    }
  }

  /// Get file size in bytes
  static Future<int> getFileSize(String path) async {
    try {
      final file = File(path);
      return await file.length();
    } catch (e) {
      return 0;
    }
  }

  /// Get file extension from URL or path
  static String getExtension(String urlOrPath) {
    final uri = Uri.tryParse(urlOrPath);
    if (uri != null) {
      final path = uri.path;
      final lastDot = path.lastIndexOf('.');
      if (lastDot != -1 && lastDot < path.length - 1) {
        return path.substring(lastDot + 1).toLowerCase();
      }
    }
    return 'mp4';
  }

  /// Get list of downloaded files in the downloads directory
  static Future<List<File>> getDownloadedFiles() async {
    try {
      final dir = await getDownloadsDirectory();
      final entities = await dir.list().toList();
      return entities
          .whereType<File>()
          .where((f) => _isMediaFile(f.path))
          .toList();
    } catch (e) {
      AppLogger.error('Failed to list downloaded files', e);
      return [];
    }
  }

  static bool _isMediaFile(String path) {
    const extensions = ['.mp4', '.mp3', '.webm', '.m4a', '.mkv', '.avi'];
    final lower = path.toLowerCase();
    return extensions.any((ext) => lower.endsWith(ext));
  }
}
