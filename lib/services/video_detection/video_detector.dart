/// Service that detects video sources from web pages loaded in the WebView.
///
/// It injects JavaScript into the page to monitor <video> elements and
/// extracts video source URLs along with metadata.
class VideoDetector {
  VideoDetector();

  /// JavaScript to inject into every page to detect video elements.
  /// Returns a JSON string with detected video info when a video is found.
  static const String detectionScript = '''
    (function() {
      function getVideoInfo() {
        var videos = document.querySelectorAll('video');
        var sources = [];
        
        for (var i = 0; i < videos.length; i++) {
          var video = videos[i];
          var src = video.src || video.currentSrc;
          
          // Check source elements
          if (!src) {
            var sourceElements = video.querySelectorAll('source');
            for (var j = 0; j < sourceElements.length; j++) {
              if (sourceElements[j].src) {
                src = sourceElements[j].src;
                break;
              }
            }
          }
          
          if (src && src.length > 0) {
            sources.push({
              'url': src,
              'duration': video.duration || 0,
              'width': video.videoWidth || 0,
              'height': video.videoHeight || 0,
              'paused': video.paused,
              'title': document.title || ''
            });
          }
        }
        
        // Also check for iframe-embedded videos (YouTube, Vimeo, etc.)
        var iframes = document.querySelectorAll('iframe');
        for (var k = 0; k < iframes.length; k++) {
          var iframeSrc = iframes[k].src || '';
          if (iframeSrc.match(/youtube\\.com\\/embed|player\\.vimeo\\.com|dailymotion\\.com\\/embed/)) {
            sources.push({
              'url': iframeSrc,
              'duration': 0,
              'width': iframes[k].width || 0,
              'height': iframes[k].height || 0,
              'paused': false,
              'title': document.title || '',
              'isEmbed': true
            });
          }
        }
        
        return JSON.stringify(sources);
      }
      
      return getVideoInfo();
    })();
  ''';

  /// JavaScript to detect video requests from network activity.
  /// Monitors XHR and Fetch requests for common video MIME types.
  static const String networkMonitorScript = '''
    (function() {
      if (window.__videoDetectorInstalled) return 'already_installed';
      window.__videoDetectorInstalled = true;
      window.__detectedVideoUrls = window.__detectedVideoUrls || [];
      
      // Monitor fetch requests
      var originalFetch = window.fetch;
      window.fetch = function() {
        var url = arguments[0];
        if (typeof url === 'string') {
          checkVideoUrl(url);
        } else if (url && url.url) {
          checkVideoUrl(url.url);
        }
        return originalFetch.apply(this, arguments);
      };
      
      // Monitor XHR
      var originalOpen = XMLHttpRequest.prototype.open;
      XMLHttpRequest.prototype.open = function() {
        if (arguments[1]) {
          checkVideoUrl(arguments[1]);
        }
        return originalOpen.apply(this, arguments);
      };
      
      function checkVideoUrl(url) {
        var videoPatterns = [
          /\\.mp4(\\?|$)/i,
          /\\.m3u8(\\?|$)/i,
          /\\.webm(\\?|$)/i,
          /\\.flv(\\?|$)/i,
          /\\.ts(\\?|$)/i,
          /videoplayback/i,
          /\\.mpd(\\?|$)/i,
          /video\\/mp4/i,
          /googlevideo\\.com/i
        ];
        
        for (var i = 0; i < videoPatterns.length; i++) {
          if (videoPatterns[i].test(url)) {
            if (window.__detectedVideoUrls.indexOf(url) === -1) {
              window.__detectedVideoUrls.push(url);
            }
            break;
          }
        }
      }
      
      return 'installed';
    })();
  ''';

  /// Script to retrieve detected network video URLs
  static const String getDetectedUrlsScript = '''
    (function() {
      return JSON.stringify(window.__detectedVideoUrls || []);
    })();
  ''';

  /// Determines if a URL is likely a video page based on common patterns.
  static bool isVideoPage(String url) {
    final videoPatterns = [
      RegExp(r'youtube\.com/watch'),
      RegExp(r'youtu\.be/'),
      RegExp(r'vimeo\.com/\d+'),
      RegExp(r'dailymotion\.com/video'),
      RegExp(r'tiktok\.com/.*/video'),
      RegExp(r'instagram\.com/(p|reel|tv)/'),
      RegExp(r'facebook\.com/.*/videos'),
      RegExp(r'twitter\.com/.*/status'),
      RegExp(r'x\.com/.*/status'),
    ];

    for (final pattern in videoPatterns) {
      if (pattern.hasMatch(url)) return true;
    }
    return false;
  }

  /// Extracts video ID from known platforms.
  static String? extractVideoId(String url) {
    // YouTube
    final ytMatch = RegExp(r'(?:youtube\.com/watch\?v=|youtu\.be/)([a-zA-Z0-9_-]{11})').firstMatch(url);
    if (ytMatch != null) return ytMatch.group(1);

    // Vimeo
    final vimeoMatch = RegExp(r'vimeo\.com/(\d+)').firstMatch(url);
    if (vimeoMatch != null) return vimeoMatch.group(1);

    // TikTok
    final tiktokMatch = RegExp(r'tiktok\.com/.*/video/(\d+)').firstMatch(url);
    if (tiktokMatch != null) return tiktokMatch.group(1);

    return null;
  }

  /// Determines the platform from a URL.
  static String detectPlatform(String url) {
    if (url.contains('youtube.com') || url.contains('youtu.be')) return 'YouTube';
    if (url.contains('vimeo.com')) return 'Vimeo';
    if (url.contains('tiktok.com')) return 'TikTok';
    if (url.contains('instagram.com')) return 'Instagram';
    if (url.contains('facebook.com') || url.contains('fb.watch')) return 'Facebook';
    if (url.contains('twitter.com') || url.contains('x.com')) return 'Twitter/X';
    if (url.contains('dailymotion.com')) return 'Dailymotion';
    return 'Unknown';
  }
}
