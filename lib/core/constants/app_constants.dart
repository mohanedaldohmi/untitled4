class AppConstants {
  AppConstants._();

  static const String appName = 'Video Downloader Pro';
  static const String appVersion = '1.0.0';
  static const int appBuildNumber = 1;

  static const int maxConcurrentDownloads = 3;
  static const String downloadFolderName = 'VideoDownloaderPro';
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  static const List<String> supportedPlatforms = [
    'YouTube',
    'TikTok',
    'Instagram',
    'Facebook',
    'Twitter/X',
    'Vimeo',
    'Dailymotion',
    'Reddit',
    'Generic MP4',
  ];

  static const List<String> supportedFormats = [
    'MP4',
    'MP3',
    'WEBM',
    'M4A',
  ];

  static const List<String> supportedQualities = [
    '1080p',
    '720p',
    '480p',
    '360p',
    '240p',
    '144p',
    'MP3 320kbps',
    'MP3 192kbps',
    'MP3 128kbps',
  ];

  static const int historyMaxItems = 500;
  static const int cacheMaxAgeDays = 7;
  static const int adInterstitialFrequency = 3;

  // Hive box names
  static const String downloadTasksBox = 'download_tasks';
  static const String historyBox = 'history';
  static const String settingsBox = 'settings';
  static const String favoritesBox = 'favorites';

  // Settings keys (canonical names for HiveStorageService)
  static const String themeKey = 'theme_mode';
  static const String wifiOnlyKey = 'wifi_only';
  static const String defaultQualityKey = 'default_quality';
  static const String maxConcurrentKey = 'max_concurrent';
  static const String saveToGalleryKey = 'save_to_gallery';
  static const String notificationsKey = 'notifications';
  static const String isPremiumKey = 'is_premium';
  static const String downloadCountKey = 'download_count';

  // Legacy aliases for backward compatibility
  static const String keyThemeMode = themeKey;
  static const String keyDownloadPath = 'download_path';
  static const String keyConcurrentDownloads = maxConcurrentKey;
  static const String keyAutoPlay = 'auto_play';
  static const String keyWifiOnly = wifiOnlyKey;
  static const String keyNotifications = notificationsKey;
  static const String keyIsPremium = isPremiumKey;
  static const String keyLanguage = 'language';
  static const String keyDownloadCount = downloadCountKey;

  // Premium limits
  static const int maxConcurrentDownloadsFree = 1;
  static const int maxConcurrentDownloadsPremium = 5;
}
