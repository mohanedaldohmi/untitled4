class ApiConstants {
  ApiConstants._();

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 60);
  static const Duration sendTimeout = Duration(seconds: 30);

  // User Agent
  static const String userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

  // YouTube
  static const String youtubeBaseUrl = 'https://www.youtube.com';
  static const String youtubeApiUrl = 'https://www.youtube.com/youtubei/v1';
  static const String youtubeVideoInfoUrl =
      'https://www.youtube.com/get_video_info';
  static const String youtubeOembedUrl =
      'https://www.youtube.com/oembed?url=';
  static const String youtubeInnertubeApiKey = 'AIzaSyAO_FJ2SlqU8Q4STEHLGCilw_Y9_11qcW8';

  // TikTok
  static const String tiktokBaseUrl = 'https://www.tiktok.com';
  static const String tiktokApiUrl = 'https://api.tiktokv.com';
  static const String tiktokOembedUrl =
      'https://www.tiktok.com/oembed?url=';

  // Instagram
  static const String instagramBaseUrl = 'https://www.instagram.com';
  static const String instagramOembedUrl =
      'https://graph.facebook.com/v17.0/instagram_oembed?url=';

  // Twitter/X
  static const String twitterBaseUrl = 'https://twitter.com';

  // Generic oEmbed
  static const String oembedUrl = 'https://noembed.com/embed?url=';

  // Download chunk size (bytes) - 2MB
  static const int downloadChunkSize = 2 * 1024 * 1024;

  // Retry
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);
}
