import '../entities/download_task.dart';
import '../repositories/repositories.dart';

class ManageDownloadUseCase {
  const ManageDownloadUseCase(this._repository);

  final DownloadRepository _repository;

  Future<void> pause(String taskId) => _repository.pauseDownload(taskId);

  Future<void> resume(String taskId) => _repository.resumeDownload(taskId);

  Future<void> cancel(String taskId) => _repository.cancelDownload(taskId);

  Future<void> delete(String taskId) => _repository.deleteDownload(taskId);

  Future<void> clearCompleted() => _repository.clearCompleted();

  Stream<DownloadTask> watchTask(String taskId) =>
      _repository.watchDownloadTask(taskId);

  Stream<List<DownloadTask>> watchAllTasks() =>
      _repository.watchAllDownloadTasks();

  Future<List<DownloadTask>> getAllTasks() => _repository.getAllDownloadTasks();
}
