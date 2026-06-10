import 'package:hive/hive.dart';

import '../../../core/constants/app_constants.dart';
import '../../domain/entities/video_info.dart';
import '../../domain/repositories/repositories.dart';
import '../models/video_info_model.dart';
import '../models/quality_option_model.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  static const _maxHistoryItems = 100;

  Box<dynamic>? _box;

  Future<Box<dynamic>> _getBox() async {
    _box ??= await Hive.openBox<dynamic>(AppConstants.historyBox);
    return _box!;
  }

  @override
  Future<List<VideoInfo>> getHistory() async {
    final box = await _getBox();
    return box.values
        .whereType<Map>()
        .map((map) => _mapToVideoInfo(map.cast<String, dynamic>()))
        .toList()
        .reversed
        .toList();
  }

  @override
  Future<void> addToHistory(VideoInfo videoInfo) async {
    final box = await _getBox();

    // Remove duplicate
    await box.delete(videoInfo.id);

    final data = {
      'id': videoInfo.id,
      'url': videoInfo.url,
      'title': videoInfo.title,
      'thumbnailUrl': videoInfo.thumbnailUrl,
      'platform': videoInfo.platform,
      'author': videoInfo.author,
      'durationSeconds': videoInfo.duration?.inSeconds,
      'addedAt': DateTime.now().toIso8601String(),
    };
    await box.put(videoInfo.id, data);

    // Keep within limit
    if (box.length > _maxHistoryItems) {
      final keys = box.keys.toList();
      await box.delete(keys.first);
    }
  }

  @override
  Future<void> removeFromHistory(String videoId) async {
    final box = await _getBox();
    await box.delete(videoId);
  }

  @override
  Future<void> clearHistory() async {
    final box = await _getBox();
    await box.clear();
  }

  VideoInfo _mapToVideoInfo(Map<String, dynamic> map) {
    return VideoInfo(
      id: map['id'] as String? ?? '',
      url: map['url'] as String? ?? '',
      title: map['title'] as String? ?? 'Unknown',
      thumbnailUrl: map['thumbnailUrl'] as String? ?? '',
      platform: map['platform'] as String? ?? '',
      qualities: const [],
      author: map['author'] as String?,
      duration: map['durationSeconds'] != null
          ? Duration(seconds: map['durationSeconds'] as int)
          : null,
    );
  }
}
