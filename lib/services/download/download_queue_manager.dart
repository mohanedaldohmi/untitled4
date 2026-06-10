import 'dart:async';

import '../../core/constants/app_constants.dart';
import '../../core/utils/logger.dart';
import '../../domain/entities/download_task.dart';
import '../../domain/repositories/repositories.dart';

/// Manages a queue of downloads, enforcing a max-concurrent limit.
/// The [DownloadRepository] handles actual HTTP downloading;
/// [DownloadQueueManager] controls when to start the next task.
class DownloadQueueManager {
  DownloadQueueManager({
    required DownloadRepository repository,
    int maxConcurrent = AppConstants.maxConcurrentDownloads,
  })  : _repository = repository,
        _maxConcurrent = maxConcurrent;

  final DownloadRepository _repository;
  int _maxConcurrent;

  /// IDs waiting to be started
  final List<String> _queue = [];

  /// IDs currently being downloaded
  final Set<String> _active = {};

  bool _isRunning = false;
  StreamSubscription<List<DownloadTask>>? _taskStreamSub;

  // ─── Lifecycle ─────────────────────────────────────────────────────────────

  void start() {
    if (_isRunning) return;
    _isRunning = true;

    // Monitor task completions to advance the queue
    _taskStreamSub = _repository
        .watchAllDownloadTasks()
        .listen(_onTaskListChanged);
  }

  void stop() {
    _isRunning = false;
    _taskStreamSub?.cancel();
    _taskStreamSub = null;
  }

  void setMaxConcurrent(int max) {
    _maxConcurrent = max.clamp(1, AppConstants.maxConcurrentDownloadsPremium);
    _advance();
  }

  // ─── Queue operations ───────────────────────────────────────────────────────

  /// Enqueue a task for downloading. If capacity is available, starts immediately.
  Future<void> enqueue(String taskId) async {
    _queue.add(taskId);
    AppLogger.debug('Queued task $taskId. Queue size: ${_queue.length}');
    _advance();
  }

  Future<void> _advance() async {
    while (_active.length < _maxConcurrent && _queue.isNotEmpty) {
      final taskId = _queue.removeAt(0);
      _active.add(taskId);
      AppLogger.info(
        'Starting download $taskId (active: ${_active.length}/$_maxConcurrent)',
      );
      try {
        await _repository.startDownload(taskId);
      } catch (e) {
        AppLogger.error('Failed to start download $taskId', e);
        _active.remove(taskId);
      }
    }
  }

  void _onTaskListChanged(List<DownloadTask> tasks) {
    final completedOrFailed = tasks
        .where((t) => t.isFinished)
        .map((t) => t.id)
        .toSet();

    // Remove finished tasks from active set
    final finishedActive = _active.intersection(completedOrFailed);
    if (finishedActive.isNotEmpty) {
      _active.removeAll(finishedActive);
      AppLogger.debug(
        'Tasks finished: $finishedActive. Active: ${_active.length}',
      );
      _advance();
    }
  }

  /// Cancel a specific download and remove from queue if waiting
  Future<void> cancel(String taskId) async {
    _queue.remove(taskId);
    _active.remove(taskId);
    await _repository.cancelDownload(taskId);
  }

  /// Pause a download. It stays in active until re-queued with [resume].
  Future<void> pause(String taskId) async {
    _active.remove(taskId);
    await _repository.pauseDownload(taskId);
  }

  /// Resume a paused download
  Future<void> resume(String taskId) async {
    _queue.insert(0, taskId); // priority-resume at front
    _advance();
  }

  int get activeCount => _active.length;
  int get queuedCount => _queue.length;
  int get totalPending => _active.length + _queue.length;
}
