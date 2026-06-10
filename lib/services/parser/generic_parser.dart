import '../../../data/models/quality_option_model.dart';
import '../../../data/models/video_info_model.dart';

/// Generic video parser using noembed.com as a fallback.
/// Works for Vimeo, Dailymotion, Twitter/X, Facebook, and many other platforms.
class GenericParser {
  const GenericParser();

  /// Parse a video URL using the noembed.com public API.
  /// Returns a [VideoInfoModel] with metadata but without download URLs.
  Future<VideoInfoModel?> parse(
    String url, {
    required Future<Map<String, dynamic>?> Function(
      String url, {
      Map<String, dynamic>? queryParameters,
    }) fetchJson,
  }) async {
    final response = await fetchJson(
      'https://noembed.com/embed',
      queryParameters: {'url': url, 'format': 'json'},
    );

    if (response == null) return null;
    if (response['error'] != null) return null;

    final title = response['title'] as String? ?? 'Video';
    final thumbnail = response['thumbnail_url'] as String? ?? '';
    final author = response['author_name'] as String?;
    final platform = _detectPlatform(url);

    // Derive a usable ID from the URL
    final id = Uri.tryParse(url)
            ?.pathSegments
            .where((s) => s.isNotEmpty)
            .lastOrNull ??
        DateTime.now().millisecondsSinceEpoch.toString();

    return VideoInfoModel(
      id: id,
      url: url,
      title: title,
      thumbnailUrl: thumbnail,
      platform: platform,
      author: author,
      qualities: _buildQualities(url, platform),
    );
  }

  List<QualityOptionModel> _buildQualities(String url, String platform) {
    switch (platform) {
      case 'vimeo':
        return [
          QualityOptionModel(
            label: '1080p',
            width: 1920,
            height: 1080,
            downloadUrl: url,
            format: 'mp4',
          ),
          QualityOptionModel(
            label: '720p',
            width: 1280,
            height: 720,
            downloadUrl: url,
            format: 'mp4',
          ),
        ];
      default:
        return [
          QualityOptionModel(
            label: 'Best',
            width: 0,
            height: 0,
            downloadUrl: url,
            format: 'mp4',
          ),
        ];
    }
  }

  String _detectPlatform(String url) {
    final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
    if (host.contains('vimeo')) return 'vimeo';
    if (host.contains('dailymotion')) return 'dailymotion';
    if (host.contains('twitter') || host.contains('x.com')) return 'twitter';
    if (host.contains('facebook') || host.contains('fb.')) return 'facebook';
    return 'web';
  }
}
