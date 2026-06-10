import '../../../core/utils/url_utils.dart';
import '../../../data/models/quality_option_model.dart';
import '../../../data/models/video_info_model.dart';

/// TikTok video parser.
class TikTokParser {
  const TikTokParser();

  VideoInfoModel buildModel({
    required String url,
    required Map<String, dynamic> oembedData,
  }) {
    final videoId =
        UrlUtils.extractTikTokVideoId(url) ??
            'tiktok_${DateTime.now().millisecondsSinceEpoch}';

    return VideoInfoModel(
      id: videoId,
      url: url,
      title: oembedData['title'] as String? ?? 'TikTok Video',
      thumbnailUrl: oembedData['thumbnail_url'] as String? ?? '',
      platform: 'tiktok',
      author: oembedData['author_name'] as String?,
      qualities: _buildQualities(url),
    );
  }

  List<QualityOptionModel> _buildQualities(String pageUrl) {
    return [
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
}
