/// Formats byte sizes into human-readable strings
class SizeFormatter {
  SizeFormatter._();

  static const int _kb = 1024;
  static const int _mb = _kb * 1024;
  static const int _gb = _mb * 1024;

  /// Format bytes to human-readable size string
  static String format(int bytes) {
    if (bytes < 0) return '0 B';
    if (bytes < _kb) return '$bytes B';
    if (bytes < _mb) return '${(bytes / _kb).toStringAsFixed(1)} KB';
    if (bytes < _gb) return '${(bytes / _mb).toStringAsFixed(1)} MB';
    return '${(bytes / _gb).toStringAsFixed(2)} GB';
  }

  /// Format download speed (bytes per second) to human-readable string
  static String formatSpeed(double bytesPerSecond) {
    if (bytesPerSecond < _kb) {
      return '${bytesPerSecond.toStringAsFixed(0)} B/s';
    }
    if (bytesPerSecond < _mb) {
      return '${(bytesPerSecond / _kb).toStringAsFixed(1)} KB/s';
    }
    return '${(bytesPerSecond / _mb).toStringAsFixed(1)} MB/s';
  }

  /// Format remaining time in seconds to human-readable string
  static String formatEta(int seconds) {
    if (seconds < 0) return '--';
    if (seconds < 60) return '${seconds}s';
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (minutes < 60) {
      return '${minutes}m ${remainingSeconds}s';
    }
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return '${hours}h ${remainingMinutes}m';
  }

  /// Calculate download ETA given downloaded bytes, total bytes, and speed
  static int calculateEta(int downloaded, int total, double speedBytesPerSec) {
    if (speedBytesPerSec <= 0 || total <= downloaded) return 0;
    final remaining = total - downloaded;
    return (remaining / speedBytesPerSec).round();
  }

  /// Calculate download progress as percentage string
  static String formatProgress(int downloaded, int total) {
    if (total <= 0) return '0%';
    final percentage = (downloaded / total * 100).clamp(0, 100);
    return '${percentage.toStringAsFixed(1)}%';
  }

  /// Calculate download progress as 0.0 to 1.0
  static double calculateProgress(int downloaded, int total) {
    if (total <= 0) return 0.0;
    return (downloaded / total).clamp(0.0, 1.0);
  }
}
