/// Base class for all app exceptions
sealed class AppException implements Exception {
  const AppException(this.message, {this.code, this.stackTrace});

  final String message;
  final String? code;
  final StackTrace? stackTrace;

  @override
  String toString() => '$runtimeType: $message${code != null ? ' (code: $code)' : ''}';
}

/// Network-related exceptions
class NetworkException extends AppException {
  const NetworkException(
    super.message, {
    super.code,
    super.stackTrace,
    this.statusCode,
  });

  final int? statusCode;
}

class NoInternetException extends NetworkException {
  const NoInternetException()
      : super('No internet connection. Please check your network settings.');
}

class TimeoutException extends NetworkException {
  const TimeoutException()
      : super('Request timed out. Please try again.');
}

/// Video parsing exceptions
class ParseException extends AppException {
  const ParseException(
    super.message, {
    super.code,
    super.stackTrace,
    this.url,
  });

  final String? url;
}

class UnsupportedPlatformException extends ParseException {
  const UnsupportedPlatformException(String platform)
      : super('Platform "$platform" is not supported yet.');
}

class VideoPrivateException extends ParseException {
  const VideoPrivateException()
      : super('This video is private and cannot be downloaded.');
}

class VideoNotFoundException extends ParseException {
  const VideoNotFoundException()
      : super('Video not found. It may have been deleted or is unavailable.');
}

/// Download exceptions
class DownloadException extends AppException {
  const DownloadException(
    super.message, {
    super.code,
    super.stackTrace,
    this.taskId,
  });

  final String? taskId;
}

class DownloadCancelledException extends DownloadException {
  const DownloadCancelledException(String taskId)
      : super('Download was cancelled.', taskId: taskId);
}

class InsufficientStorageException extends DownloadException {
  InsufficientStorageException(int requiredBytes)
      : super(
            'Not enough storage space. Required: ${(requiredBytes / 1024 / 1024).toStringAsFixed(1)} MB');
}

class PermissionDeniedException extends DownloadException {
  const PermissionDeniedException()
      : super('Storage permission denied. Please grant storage access.');
}

/// Storage exceptions
class StorageException extends AppException {
  const StorageException(
    super.message, {
    super.code,
    super.stackTrace,
  });
}

class StorageReadException extends StorageException {
  const StorageReadException(String key)
      : super('Failed to read data for key: $key');
}

class StorageWriteException extends StorageException {
  const StorageWriteException(String key)
      : super('Failed to write data for key: $key');
}

/// Premium feature exception
class PremiumException extends AppException {
  const PremiumException(super.message, {super.code, super.stackTrace});
}

class PremiumFeatureException extends PremiumException {
  const PremiumFeatureException(String feature)
      : super('$feature requires a premium subscription.');
}

class PurchaseFailedException extends PremiumException {
  const PurchaseFailedException(String reason)
      : super('Purchase failed: $reason');
}
