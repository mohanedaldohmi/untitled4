import 'app_exception.dart';

/// Sealed class representing all possible failure types
sealed class Failure {
  const Failure(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {this.statusCode});
  final int? statusCode;
}

class NoInternetFailure extends NetworkFailure {
  const NoInternetFailure() : super('No internet connection');
}

class TimeoutFailure extends NetworkFailure {
  const TimeoutFailure() : super('Request timed out');
}

class ParseFailure extends Failure {
  const ParseFailure(super.message, {this.url});
  final String? url;
}

class UnsupportedPlatformFailure extends ParseFailure {
  const UnsupportedPlatformFailure(String platform)
      : super('Unsupported platform: $platform');
}

class VideoNotFoundFailure extends ParseFailure {
  const VideoNotFoundFailure() : super('Video not found or unavailable');
}

class VideoPrivateFailure extends ParseFailure {
  const VideoPrivateFailure() : super('Video is private');
}

class DownloadFailure extends Failure {
  const DownloadFailure(super.message, {this.taskId});
  final String? taskId;
}

class DownloadCancelledFailure extends DownloadFailure {
  const DownloadCancelledFailure(String taskId)
      : super('Download cancelled', taskId: taskId);
}

class InsufficientStorageFailure extends DownloadFailure {
  const InsufficientStorageFailure(int bytes)
      : super('Insufficient storage space: ${bytes ~/ 1024 ~/ 1024} MB needed');
}

class PermissionFailure extends DownloadFailure {
  const PermissionFailure() : super('Storage permission denied');
}

class StorageFailure extends Failure {
  const StorageFailure(super.message);
}

class PremiumFailure extends Failure {
  const PremiumFailure(super.message);
}

class UnknownFailure extends Failure {
  const UnknownFailure([String message = 'An unexpected error occurred'])
      : super(message);
}

/// Extension to convert exceptions to failures
extension AppExceptionToFailure on AppException {
  Failure toFailure() {
    return switch (this) {
      NoInternetException() => const NoInternetFailure(),
      TimeoutException() => const TimeoutFailure(),
      NetworkException e => NetworkFailure(e.message, statusCode: e.statusCode),
      UnsupportedPlatformException e => UnsupportedPlatformFailure(e.message),
      VideoNotFoundException() => const VideoNotFoundFailure(),
      VideoPrivateException() => const VideoPrivateFailure(),
      ParseException e => ParseFailure(e.message, url: e.url),
      DownloadCancelledException e => DownloadCancelledFailure(e.taskId ?? ''),
      InsufficientStorageException e => InsufficientStorageFailure(0),
      PermissionDeniedException() => const PermissionFailure(),
      DownloadException e => DownloadFailure(e.message, taskId: e.taskId),
      StorageException e => StorageFailure(e.message),
      PremiumFeatureException e => PremiumFailure(e.message),
      PremiumException e => PremiumFailure(e.message),
      _ => UnknownFailure(message),
    };
  }
}
