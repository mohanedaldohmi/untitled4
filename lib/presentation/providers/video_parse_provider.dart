import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/injection.dart';
import '../../domain/entities/video_info.dart';
import '../../core/utils/url_utils.dart';

enum ParseState { idle, loading, success, error }

class VideoParseNotifier extends StateNotifier<AsyncValue<VideoInfo?>> {
  VideoParseNotifier(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;

  Future<void> parseUrl(String url) async {
    final validated = UrlUtils.parseAndValidate(url);
    if (validated == null) {
      state = AsyncValue.error('Invalid URL', StackTrace.current);
      return;
    }

    final platform = UrlUtils.detectPlatform(validated);
    if (!platform.isSupported) {
      state = AsyncValue.error(
        'Platform not supported yet: ${UrlUtils.platformDisplayName(platform)}',
        StackTrace.current,
      );
      return;
    }

    state = const AsyncValue.loading();
    final useCase = _ref.read(parseVideoUseCaseProvider);
    state = await AsyncValue.guard(() => useCase(validated));

    // Save to history on success (fire-and-forget)
    state.whenData((videoInfo) {
      if (videoInfo != null) {
        unawaited(_ref.read(getHistoryUseCaseProvider).add(videoInfo));
      }
    });
  }

  void reset() => state = const AsyncValue.data(null);
}

final videoParseProvider =
    StateNotifierProvider<VideoParseNotifier, AsyncValue<VideoInfo?>>(
  (ref) => VideoParseNotifier(ref),
);
