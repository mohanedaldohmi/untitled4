import '../entities/download_task.dart';
import '../entities/quality_option.dart';
import '../entities/video_info.dart';
import '../repositories/repositories.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';

class StartDownloadUseCase {
  const StartDownloadUseCase(this._repository);

  final DownloadRepository _repository;

  Future<DownloadTask> call({
    required VideoInfo videoInfo,
    required QualityOption quality,
    required bool isPremium,
  }) async {
    final activeCount = await _repository.getActiveDownloadCount();
    final maxConcurrent = isPremium
        ? AppConstants.maxConcurrentDownloadsPremium
        : AppConstants.maxConcurrentDownloadsFree;

    if (activeCount >= maxConcurrent) {
      throw PremiumFeatureException(
        'Only $maxConcurrent simultaneous download${maxConcurrent > 1 ? 's' : ''} allowed. '
        '${isPremium ? '' : 'Upgrade to Premium for more.'}',
      );
    }

    final task = await _repository.createDownloadTask(
      videoInfo: videoInfo,
      quality: quality,
    );
    await _repository.startDownload(task.id);
    return task;
  }
}
