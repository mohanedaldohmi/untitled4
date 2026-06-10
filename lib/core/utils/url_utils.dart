/// Utility for URL validation and platform detection
class UrlUtils {
  UrlUtils._();

  static const _youtubeHosts = [
    'youtube.com',
    'www.youtube.com',
    'm.youtube.com',
    'youtu.be',
    'music.youtube.com',
  ];

  static const _tiktokHosts = [
    'tiktok.com',
    'www.tiktok.com',
    'm.tiktok.com',
    'vm.tiktok.com',
    'vt.tiktok.com',
  ];

  static const _instagramHosts = [
    'instagram.com',
    'www.instagram.com',
  ];

  static const _twitterHosts = [
    'twitter.com',
    'www.twitter.com',
    'x.com',
    'www.x.com',
    't.co',
  ];

  static const _facebookHosts = [
    'facebook.com',
    'www.facebook.com',
    'm.facebook.com',
    'fb.watch',
  ];

  static const _vimeoHosts = [
    'vimeo.com',
    'www.vimeo.com',
    'player.vimeo.com',
  ];

  static const _dailymotionHosts = [
    'dailymotion.com',
    'www.dailymotion.com',
    'dai.ly',
  ];

  /// Validates and normalizes a URL, returns cleaned URL or null if invalid
  static String? parseAndValidate(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    // Add scheme if missing
    String urlStr = trimmed;
    if (!urlStr.startsWith('http://') && !urlStr.startsWith('https://')) {
      urlStr = 'https://$urlStr';
    }

    final uri = Uri.tryParse(urlStr);
    if (uri == null || !uri.hasAuthority) return null;

    return uri.toString();
  }

  /// Check if the URL is valid
  static bool isValidUrl(String url) {
    return parseAndValidate(url) != null;
  }

  /// Detect the video platform from a URL
  static VideoPlatform detectPlatform(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return VideoPlatform.unknown;

    final host = uri.host.toLowerCase();

    if (_youtubeHosts.contains(host)) return VideoPlatform.youtube;
    if (_tiktokHosts.contains(host)) return VideoPlatform.tiktok;
    if (_instagramHosts.contains(host)) return VideoPlatform.instagram;
    if (_twitterHosts.contains(host)) return VideoPlatform.twitter;
    if (_facebookHosts.contains(host)) return VideoPlatform.facebook;
    if (_vimeoHosts.contains(host)) return VideoPlatform.vimeo;
    if (_dailymotionHosts.contains(host)) return VideoPlatform.dailymotion;

    return VideoPlatform.unknown;
  }

  /// Extract YouTube video ID from various URL formats
  static String? extractYouTubeVideoId(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;

    final host = uri.host.toLowerCase();

    if (host == 'youtu.be') {
      return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    }

    if (_youtubeHosts.contains(host)) {
      // Standard watch URL
      final v = uri.queryParameters['v'];
      if (v != null && v.isNotEmpty) return v;

      // Shorts
      if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'shorts') {
        return uri.pathSegments[1];
      }

      // Embed
      if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'embed') {
        return uri.pathSegments[1];
      }
    }

    return null;
  }

  /// Check if URL is a YouTube Shorts URL
  static bool isYouTubeShorts(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    return uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'shorts';
  }

  /// Check if URL is a playlist URL
  static bool isYouTubePlaylist(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    return uri.queryParameters.containsKey('list');
  }

  /// Extract TikTok video ID from URL
  static String? extractTikTokVideoId(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;

    // Pattern: /video/{id}
    final segments = uri.pathSegments;
    final videoIndex = segments.indexOf('video');
    if (videoIndex != -1 && videoIndex + 1 < segments.length) {
      return segments[videoIndex + 1];
    }

    return null;
  }

  /// Get display name for a platform
  static String platformDisplayName(VideoPlatform platform) {
    return switch (platform) {
      VideoPlatform.youtube => 'YouTube',
      VideoPlatform.tiktok => 'TikTok',
      VideoPlatform.instagram => 'Instagram',
      VideoPlatform.twitter => 'Twitter / X',
      VideoPlatform.facebook => 'Facebook',
      VideoPlatform.vimeo => 'Vimeo',
      VideoPlatform.dailymotion => 'Dailymotion',
      VideoPlatform.unknown => 'Unknown',
    };
  }
}

/// Supported video platforms
enum VideoPlatform {
  youtube,
  tiktok,
  instagram,
  twitter,
  facebook,
  vimeo,
  dailymotion,
  unknown;

  bool get isSupported =>
      this == youtube ||
      this == tiktok ||
      this == instagram ||
      this == twitter ||
      this == facebook ||
      this == vimeo ||
      this == dailymotion ||
      this == unknown; // unknown falls through to generic parser
}
