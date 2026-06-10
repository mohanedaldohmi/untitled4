import '../../domain/entities/video_info.dart';
import 'quality_option_model.dart';

class VideoInfoModel {
  const VideoInfoModel({
    required this.id,
    required this.url,
    required this.title,
    required this.thumbnailUrl,
    required this.platform,
    required this.qualities,
    this.description,
    this.durationSeconds,
    this.author,
    this.authorAvatarUrl,
    this.viewCount,
    this.likeCount,
    this.uploadDate,
    this.isLive = false,
  });

  final String id;
  final String url;
  final String title;
  final String thumbnailUrl;
  final String platform;
  final List<QualityOptionModel> qualities;
  final String? description;
  final int? durationSeconds;
  final String? author;
  final String? authorAvatarUrl;
  final int? viewCount;
  final int? likeCount;
  final DateTime? uploadDate;
  final bool isLive;

  factory VideoInfoModel.fromJson(Map<String, dynamic> json) {
    final formatsJson = json['formats'] as List<dynamic>? ?? [];
    return VideoInfoModel(
      id: json['id'] as String? ?? '',
      url: json['webpage_url'] as String? ?? json['url'] as String? ?? '',
      title: json['title'] as String? ?? 'Unknown',
      thumbnailUrl: json['thumbnail'] as String? ?? '',
      platform: json['extractor'] as String? ?? 'unknown',
      qualities: formatsJson
          .map((f) => QualityOptionModel.fromJson(f as Map<String, dynamic>))
          .where((q) => q.downloadUrl.isNotEmpty)
          .toList(),
      description: json['description'] as String?,
      durationSeconds: json['duration'] as int?,
      author: json['uploader'] as String? ?? json['channel'] as String?,
      authorAvatarUrl: null,
      viewCount: json['view_count'] as int?,
      likeCount: json['like_count'] as int?,
      uploadDate: _parseDate(json['upload_date'] as String?),
      isLive: json['is_live'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'title': title,
      'thumbnailUrl': thumbnailUrl,
      'platform': platform,
      'qualities': qualities.map((q) => q.toJson()).toList(),
      'description': description,
      'durationSeconds': durationSeconds,
      'author': author,
      'authorAvatarUrl': authorAvatarUrl,
      'viewCount': viewCount,
      'likeCount': likeCount,
      'uploadDate': uploadDate?.toIso8601String(),
      'isLive': isLive,
    };
  }

  VideoInfo toEntity() {
    return VideoInfo(
      id: id,
      url: url,
      title: title,
      thumbnailUrl: thumbnailUrl,
      platform: platform,
      qualities: qualities.map((q) => q.toEntity()).toList(),
      description: description,
      duration: durationSeconds != null
          ? Duration(seconds: durationSeconds!)
          : null,
      author: author,
      authorAvatarUrl: authorAvatarUrl,
      viewCount: viewCount,
      likeCount: likeCount,
      uploadDate: uploadDate,
      isLive: isLive,
    );
  }

  static DateTime? _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.length < 8) return null;
    try {
      return DateTime.parse(
        '${dateStr.substring(0, 4)}-${dateStr.substring(4, 6)}-${dateStr.substring(6, 8)}',
      );
    } catch (_) {
      return null;
    }
  }
}
