import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/injection.dart';
import '../../domain/entities/download_task.dart';
import '../../domain/entities/quality_option.dart';
import '../../domain/entities/video_info.dart';
import '../../services/ads/ads_manager.dart';
import '../../services/premium/premium_manager.dart';

final downloadsListProvider = StreamProvider<List<DownloadTask>>((ref) async* {
  final repo = await ref.watch(downloadRepositoryProvider.future);
  yield* repo.watchAllDownloadTasks();
});

final activeDownloadsProvider = Provider<List<DownloadTask>>((ref) {
  return ref.watch(downloadsListProvider).maybeWhen(
        data: (tasks) => tasks.where((t) => t.isActive).toList(),
        orElse: () => [],
      );
});

final completedDownloadsProvider = Provider<List<DownloadTask>>((ref) {
  return ref.watch(downloadsListProvider).maybeWhen(
        data: (tasks) => tasks
            .where((t) => t.status == DownloadStatus.completed)
            .toList(),
        orElse: () => [],
      );
});

/// Riverpod provider that reflects PremiumManager.instance.isPremium
final isPremiumProvider = StateProvider<bool>((ref) {
  return PremiumManager.instance.isPremium;
});

class DownloadActionsNotifier extends StateNotifier<AsyncValue<void>> {
  DownloadActionsNotifier(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;

  Future<void> startDownload(VideoInfo videoInfo, QualityOption quality) async {
    state = const AsyncValue.loading();
    final useCase = await _ref.read(startDownloadUseCaseProvider.future);
    final isPremium = _ref.read(isPremiumProvider);
    state = await AsyncValue.guard(
      () async {
        final task = await useCase(
          videoInfo: videoInfo,
          quality: quality,
          isPremium: isPremium,
        );
        // Trigger ad logic after a short delay to not block navigation
        Future.delayed(const Duration(seconds: 1), () {
          AdsManager.instance.onDownloadCompleted();
        });
       // return task;
      },
    );
  }

  Future<void> pauseDownload(String taskId) async {
    final useCase = await _ref.read(manageDownloadUseCaseProvider.future);
    await useCase.pause(taskId);
  }

  Future<void> resumeDownload(String taskId) async {
    final useCase = await _ref.read(manageDownloadUseCaseProvider.future);
    await useCase.resume(taskId);
  }

  Future<void> cancelDownload(String taskId) async {
    final useCase = await _ref.read(manageDownloadUseCaseProvider.future);
    await useCase.cancel(taskId);
  }

  Future<void> deleteDownload(String taskId) async {
    final useCase = await _ref.read(manageDownloadUseCaseProvider.future);
    await useCase.delete(taskId);
  }

  Future<void> clearCompleted() async {
    final useCase = await _ref.read(manageDownloadUseCaseProvider.future);
    await useCase.clearCompleted();
  }
}

final downloadActionsProvider =
    StateNotifierProvider<DownloadActionsNotifier, AsyncValue<void>>(
  (ref) => DownloadActionsNotifier(ref),
);
