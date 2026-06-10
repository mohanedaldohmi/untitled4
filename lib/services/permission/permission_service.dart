import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/utils/logger.dart';

/// Central permission management service
class PermissionService {
  const PermissionService._();

  /// Request storage permissions required for downloading files.
  /// Returns true if all required permissions were granted.
  static Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      // Android 13+ uses READ_MEDIA_VIDEO / READ_MEDIA_AUDIO
      // Android 12 and below uses READ/WRITE_EXTERNAL_STORAGE
      final sdkInt = await _getAndroidSdkInt();
      if (sdkInt >= 33) {
        final video = await Permission.videos.request();
        final audio = await Permission.audio.request();
        AppLogger.info(
          'Storage permissions (Android 13+): video=${video.name}, audio=${audio.name}',
        );
        return video.isGranted && audio.isGranted;
      } else {
        final storage = await Permission.storage.request();
        AppLogger.info('Storage permission: ${storage.name}');
        return storage.isGranted;
      }
    } else if (Platform.isIOS) {
      // iOS requires Photos permission to save to gallery
      final photos = await Permission.photos.request();
      AppLogger.info('Photos permission: ${photos.name}');
      return photos.isGranted;
    }
    return true;
  }

  /// Check current storage permission status without prompting.
  static Future<bool> hasStoragePermission() async {
    if (Platform.isAndroid) {
      final sdkInt = await _getAndroidSdkInt();
      if (sdkInt >= 33) {
        return (await Permission.videos.status).isGranted &&
            (await Permission.audio.status).isGranted;
      }
      return (await Permission.storage.status).isGranted;
    } else if (Platform.isIOS) {
      final status = await Permission.photos.status;
      return status.isGranted || status.isLimited;
    }
    return true;
  }

  /// Request notification permission (Android 13+ requires explicit request).
  static Future<bool> requestNotificationPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      AppLogger.info('Notification permission: ${status.name}');
      return status.isGranted;
    }
    return true;
  }

  /// Open the app settings page so users can manually enable permissions.
  static Future<void> openSettings() => openAppSettings();

  static Future<int> _getAndroidSdkInt() async {
    try {
      final info = await DeviceInfoPlugin().androidInfo;
      return info.version.sdkInt;
    } catch (e) {
      AppLogger.error('Failed to read Android SDK version, defaulting to 30', e);
      return 30;
    }
  }
}
