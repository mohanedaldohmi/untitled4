import '../../../data/models/quality_option_model.dart';
import '../../../data/models/video_info_model.dart';

/// YouTube video parser.
/// Uses the official oEmbed endpoint for metadata, then builds
/// standard quality option stubs. Actual stream URLs require a
/// server-side yt-dlp integration — the [downloadUrl] field
/// on each quality option intentionally holds the page URL as
/// a placeholder; replace with your backend endpoint in production.
class YouTubeParser {
  const YouTubeParser();

  /// Standard YouTube thumbnail URL patterns
  static String thumbnailUrl(String videoId, {String quality = 'hqdefault'}) {
    return 'https://img.youtube.com/vi/$videoId/$quality.jpg';
  }

  /// Build quality options for a YouTube video.
  /// We use the video page URL as a placeholder download URL
  /// because direct MP4 stream extraction requires a backend service.
  List<QualityOptionModel> buildQualities(String videoId, String pageUrl) {
    return [
      QualityOptionModel(
        label: '1080p HD',
        width: 1920,
        height: 1080,
        downloadUrl: pageUrl,
        format: 'mp4',
      ),
      QualityOptionModel(
        label: '720p HD',
        width: 1280,
        height: 720,
        downloadUrl: pageUrl,
        format: 'mp4',
      ),
      QualityOptionModel(
        label: '480p',
        width: 854,
        height: 480,
        downloadUrl: pageUrl,
        format: 'mp4',
      ),
      QualityOptionModel(
        label: '360p',
        width: 640,
        height: 360,
        downloadUrl: pageUrl,
        format: 'mp4',
      ),
      QualityOptionModel(
        label: '144p',
        width: 256,
        height: 144,
        downloadUrl: pageUrl,
        format: 'mp4',
      ),
      QualityOptionModel(
        label: 'MP3 128kbps',
        width: 0,
        height: 0,
        downloadUrl: pageUrl,
        format: 'mp3',
        hasAudio: true,
        isVideoOnly: false,
      ),
    ];
  }

  /// Parse YouTube metadata from the oEmbed response and return a [VideoInfoModel].
  VideoInfoModel buildModel({
    required String videoId,
    required String pageUrl,
    required Map<String, dynamic> oembedData,
  }) {
    final thumb = oembedData['thumbnail_url'] as String?;
    final thumbUrl = (thumb != null && thumb.isNotEmpty)
        ? thumb
        : thumbnailUrl(videoId, quality: 'maxresdefault');

    return VideoInfoModel(
      id: videoId,
      url: pageUrl,
      title: oembedData['title'] as String? ?? 'YouTube Video',
      thumbnailUrl: thumbUrl,
      platform: 'youtube',
      author: oembedData['author_name'] as String?,
      qualities: buildQualities(videoId, pageUrl),
    );
  }
}
