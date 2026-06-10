import 'package:equatable/equatable.dart';

import 'quality_option.dart';

/// Core domain entity for parsed video information
class VideoInfo extends Equatable {
  const VideoInfo({
    required this.id,
    required this.url,
    required this.title,
    required this.thumbnailUrl,
    required this.platform,
    required this.qualities,
    this.description,
    this.duration,
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
  final List<QualityOption> qualities;
  final String? description;
  final Duration? duration;
  final String? author;
  final String? authorAvatarUrl;
  final int? viewCount;
  final int? likeCount;
  final DateTime? uploadDate;
  final bool isLive;

  /// Get best available quality
  QualityOption? get bestQuality {
    if (qualities.isEmpty) return null;
    final videos = qualities.where((q) => !q.isAudioOnly).toList()
      ..sort((a, b) => b.height.compareTo(a.height));
    return videos.isNotEmpty ? videos.first : qualities.first;
  }

  /// Get audio-only options
  List<QualityOption> get audioQualities =>
      qualities.where((q) => q.isAudioOnly).toList();

  /// Get video-only options sorted by resolution
  List<QualityOption> get videoQualities {
    return qualities.where((q) => !q.isAudioOnly).toList()
      ..sort((a, b) => b.height.compareTo(a.height));
  }

  @override
  List<Object?> get props => [
        id,
        url,
        title,
        thumbnailUrl,
        platform,
        qualities,
        description,
        duration,
        author,
        authorAvatarUrl,
        viewCount,
        likeCount,
        uploadDate,
        isLive,
      ];
}
