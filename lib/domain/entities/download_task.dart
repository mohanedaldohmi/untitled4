import 'package:equatable/equatable.dart';

/// Download status enum
enum DownloadStatus {
  pending,
  downloading,
  paused,
  completed,
  failed,
  cancelled,
}

/// Core domain entity for a download task
class DownloadTask extends Equatable {
  const DownloadTask({
    required this.id,
    required this.url,
    required this.title,
    required this.thumbnailUrl,
    required this.downloadUrl,
    required this.platform,
    required this.quality,
    required this.format,
    required this.status,
    required this.createdAt,
    this.filePath,
    this.totalBytes = 0,
    this.downloadedBytes = 0,
    this.errorMessage,
    this.updatedAt,
  });

  final String id;
  final String url;
  final String title;
  final String thumbnailUrl;
  final String downloadUrl;
  final String platform;
  final String quality;
  final String format;
  final DownloadStatus status;
  final DateTime createdAt;
  final String? filePath;
  final int totalBytes;
  final int downloadedBytes;
  final String? errorMessage;
  final DateTime? updatedAt;

  double get progress {
    if (totalBytes <= 0) return 0.0;
    return (downloadedBytes / totalBytes).clamp(0.0, 1.0);
  }

  bool get isActive =>
      status == DownloadStatus.downloading || status == DownloadStatus.pending;

  bool get isFinished =>
      status == DownloadStatus.completed ||
      status == DownloadStatus.failed ||
      status == DownloadStatus.cancelled;

  DownloadTask copyWith({
    String? id,
    String? url,
    String? title,
    String? thumbnailUrl,
    String? downloadUrl,
    String? platform,
    String? quality,
    String? format,
    DownloadStatus? status,
    DateTime? createdAt,
    String? filePath,
    int? totalBytes,
    int? downloadedBytes,
    String? errorMessage,
    DateTime? updatedAt,
  }) {
    return DownloadTask(
      id: id ?? this.id,
      url: url ?? this.url,
      title: title ?? this.title,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      platform: platform ?? this.platform,
      quality: quality ?? this.quality,
      format: format ?? this.format,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      filePath: filePath ?? this.filePath,
      totalBytes: totalBytes ?? this.totalBytes,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      errorMessage: errorMessage ?? this.errorMessage,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        url,
        title,
        thumbnailUrl,
        downloadUrl,
        platform,
        quality,
        format,
        status,
        createdAt,
        filePath,
        totalBytes,
        downloadedBytes,
        errorMessage,
        updatedAt,
      ];
}
