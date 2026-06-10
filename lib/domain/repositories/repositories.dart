import '../entities/download_task.dart';
import '../entities/video_info.dart';
import '../entities/quality_option.dart';

abstract class VideoRepository {
  Future<VideoInfo> parseVideoInfo(String url);
}

abstract class DownloadRepository {
  Future<DownloadTask> createDownloadTask({
    required VideoInfo videoInfo,
    required QualityOption quality,
  });

  Future<void> startDownload(String taskId);
  Future<void> pauseDownload(String taskId);
  Future<void> resumeDownload(String taskId);
  Future<void> cancelDownload(String taskId);
  Future<void> deleteDownload(String taskId);

  Stream<DownloadTask> watchDownloadTask(String taskId);
  Stream<List<DownloadTask>> watchAllDownloadTasks();

  Future<List<DownloadTask>> getAllDownloadTasks();
  Future<DownloadTask?> getDownloadTask(String taskId);
  Future<int> getActiveDownloadCount();

  Future<void> clearCompleted();
}

abstract class HistoryRepository {
  Future<List<VideoInfo>> getHistory();
  Future<void> addToHistory(VideoInfo videoInfo);
  Future<void> removeFromHistory(String videoId);
  Future<void> clearHistory();
}

abstract class SettingsRepository {
  Future<T?> getSetting<T>(String key);
  Future<void> saveSetting<T>(String key, T value);
  Future<void> removeSetting(String key);
}
