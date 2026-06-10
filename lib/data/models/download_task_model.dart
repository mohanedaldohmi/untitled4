import 'package:hive/hive.dart';

import '../../domain/entities/download_task.dart';

part 'download_task_model.g.dart';

@HiveType(typeId: 0)
class DownloadTaskModel extends HiveObject {
  DownloadTaskModel({
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

  @HiveField(0)
  String id;

  @HiveField(1)
  String url;

  @HiveField(2)
  String title;

  @HiveField(3)
  String thumbnailUrl;

  @HiveField(4)
  String downloadUrl;

  @HiveField(5)
  String platform;

  @HiveField(6)
  String quality;

  @HiveField(7)
  String format;

  @HiveField(8)
  int status; // Stored as int, mapped to DownloadStatus enum

  @HiveField(9)
  DateTime createdAt;

  @HiveField(10)
  String? filePath;

  @HiveField(11)
  int totalBytes;

  @HiveField(12)
  int downloadedBytes;

  @HiveField(13)
  String? errorMessage;

  @HiveField(14)
  DateTime? updatedAt;

  DownloadTask toEntity() {
    return DownloadTask(
      id: id,
      url: url,
      title: title,
      thumbnailUrl: thumbnailUrl,
      downloadUrl: downloadUrl,
      platform: platform,
      quality: quality,
      format: format,
      status: DownloadStatus.values[status.clamp(0, DownloadStatus.values.length - 1)],
      createdAt: createdAt,
      filePath: filePath,
      totalBytes: totalBytes,
      downloadedBytes: downloadedBytes,
      errorMessage: errorMessage,
      updatedAt: updatedAt,
    );
  }

  factory DownloadTaskModel.fromEntity(DownloadTask task) {
    return DownloadTaskModel(
      id: task.id,
      url: task.url,
      title: task.title,
      thumbnailUrl: task.thumbnailUrl,
      downloadUrl: task.downloadUrl,
      platform: task.platform,
      quality: task.quality,
      format: task.format,
      status: task.status.index,
      createdAt: task.createdAt,
      filePath: task.filePath,
      totalBytes: task.totalBytes,
      downloadedBytes: task.downloadedBytes,
      errorMessage: task.errorMessage,
      updatedAt: task.updatedAt,
    );
  }
}
