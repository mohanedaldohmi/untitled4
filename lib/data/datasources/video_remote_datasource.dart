import 'package:dio/dio.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/url_utils.dart';
import '../../../services/parser/generic_parser.dart';
import '../../../services/parser/tiktok_parser.dart';
import '../../../services/parser/youtube_parser.dart';
import '../models/quality_option_model.dart';
import '../models/video_info_model.dart';

abstract class VideoRemoteDataSource {
  Future<VideoInfoModel> getVideoInfo(String url);
}

class VideoRemoteDataSourceImpl implements VideoRemoteDataSource {
  VideoRemoteDataSourceImpl(this._dioClient);

  final DioClient _dioClient;

  final _youtubeParser = const YouTubeParser();
  final _tiktokParser = const TikTokParser();
  final _genericParser = const GenericParser();

  @override
  Future<VideoInfoModel> getVideoInfo(String url) async {
    final platform = UrlUtils.detectPlatform(url);

    return switch (platform) {
      VideoPlatform.youtube => _fetchYouTube(url),
      VideoPlatform.tiktok => _fetchTikTok(url),
      VideoPlatform.instagram => _fetchInstagram(url),
      VideoPlatform.twitter => _fetchGeneric(url, 'twitter'),
      VideoPlatform.facebook => _fetchGeneric(url, 'facebook'),
      VideoPlatform.vimeo => _fetchGeneric(url, 'vimeo'),
      VideoPlatform.dailymotion => _fetchGeneric(url, 'dailymotion'),
      _ => _fetchGeneric(url, 'web'),
    };
  }

  // ─── YouTube ──────────────────────────────────────────────────────────────

  Future<VideoInfoModel> _fetchYouTube(String url) async {
    try {
      final videoId = UrlUtils.extractYouTubeVideoId(url);
      if (videoId == null) throw ParseException('Invalid YouTube URL', url: url);

      final response = await _dioClient.get<Map<String, dynamic>>(
        'https://www.youtube.com/oembed',
        queryParameters: {'url': url, 'format': 'json'},
      );

      if (response.statusCode != 200 || response.data == null) {
        throw ParseException('Failed to fetch YouTube video info', url: url);
      }

      return _youtubeParser.buildModel(
        videoId: videoId,
        pageUrl: url,
        oembedData: response.data!,
      );
    } on DioException catch (e) {
      _handleDioError(e, url);
      rethrow;
    }
  }

  // ─── TikTok ───────────────────────────────────────────────────────────────

  Future<VideoInfoModel> _fetchTikTok(String url) async {
    try {
      final response = await _dioClient.get<Map<String, dynamic>>(
        'https://www.tiktok.com/oembed',
        queryParameters: {'url': url},
      );

      if (response.statusCode != 200 || response.data == null) {
        throw ParseException('Failed to fetch TikTok video info', url: url);
      }

      return _tiktokParser.buildModel(url: url, oembedData: response.data!);
    } on DioException catch (e) {
      _handleDioError(e, url);
      rethrow;
    }
  }

  // ─── Instagram ────────────────────────────────────────────────────────────

  Future<VideoInfoModel> _fetchInstagram(String url) async {
    try {
      final response = await _dioClient.get<Map<String, dynamic>>(
        'https://www.instagram.com/oembed/',
        queryParameters: {'url': url},
      );

      if (response.statusCode != 200 || response.data == null) {
        throw ParseException('Failed to fetch Instagram video info', url: url);
      }

      final data = response.data!;
      return VideoInfoModel(
        id: Uri.parse(url).pathSegments.where((s) => s.isNotEmpty).last,
        url: url,
        title: data['title'] as String? ?? 'Instagram Video',
        thumbnailUrl: data['thumbnail_url'] as String? ?? '',
        platform: 'instagram',
        author: data['author_name'] as String?,
        qualities: _buildBasicQualities(url),
      );
    } on DioException catch (e) {
      _handleDioError(e, url);
      rethrow;
    }
  }

  // ─── Generic / noembed ────────────────────────────────────────────────────

  Future<VideoInfoModel> _fetchGeneric(
    String url,
    String expectedPlatform,
  ) async {
    try {
      final result = await _genericParser.parse(
        url,
        fetchJson: (endpoint, {queryParameters}) async {
          try {
            final res = await _dioClient.get<Map<String, dynamic>>(
              endpoint,
              queryParameters: queryParameters,
            );
            if (res.statusCode == 200) return res.data;
            return null;
          } catch (_) {
            return null;
          }
        },
      );

      if (result == null) {
        throw ParseException(
          'Could not retrieve video info. Platform may not be supported.',
          url: url,
        );
      }

      return result;
    } catch (e) {
      if (e is ParseException) rethrow;
      throw ParseException(
        'Failed to fetch video info: ${e.toString()}',
        url: url,
      );
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  List<QualityOptionModel> _buildBasicQualities(String url) {
    return [
      QualityOptionModel(
        label: '720p',
        width: 1280,
        height: 720,
        downloadUrl: url,
        format: 'mp4',
      ),
      QualityOptionModel(
        label: '480p',
        width: 854,
        height: 480,
        downloadUrl: url,
        format: 'mp4',
      ),
      QualityOptionModel(
        label: 'MP3',
        width: 0,
        height: 0,
        downloadUrl: url,
        format: 'mp3',
        hasAudio: true,
        isVideoOnly: false,
      ),
    ];
  }

  void _handleDioError(DioException e, String url) {
    AppLogger.error('Network error fetching video info for $url', e);
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      throw const TimeoutException();
    }
    if (e.type == DioExceptionType.connectionError) {
      throw const NoInternetException();
    }
    if (e.response?.statusCode == 404) {
      throw VideoNotFoundException();
    }
    if (e.response?.statusCode == 403) {
      throw VideoPrivateException();
    }
    throw NetworkException(
      e.message ?? 'Network error',
      statusCode: e.response?.statusCode,
    );
  }
}
