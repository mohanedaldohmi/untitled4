import 'package:hive/hive.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/logger.dart';
import '../models/download_task_model.dart';

abstract class DownloadLocalDataSource {
  Future<List<DownloadTaskModel>> getAllTasks();
  Future<DownloadTaskModel?> getTask(String taskId);
  Future<void> saveTask(DownloadTaskModel task);
  Future<void> deleteTask(String taskId);
  Future<void> clearCompleted();
  Stream<List<DownloadTaskModel>> watchAllTasks();
  Stream<DownloadTaskModel> watchTask(String taskId);
}

class HiveDownloadLocalDataSource implements DownloadLocalDataSource {
  HiveDownloadLocalDataSource(this._box);

  final Box<DownloadTaskModel> _box;

  static Future<HiveDownloadLocalDataSource> create() async {
    final box = await Hive.openBox<DownloadTaskModel>(
      AppConstants.downloadTasksBox,
    );
    return HiveDownloadLocalDataSource(box);
  }

  @override
  Future<List<DownloadTaskModel>> getAllTasks() async {
    return _box.values.where((t) => t != null).cast<DownloadTaskModel>().toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<DownloadTaskModel?> getTask(String taskId) async {
    return _box.get(taskId);
  }

  @override
  Future<void> saveTask(DownloadTaskModel task) async {
    await _box.put(task.id, task);
  }

  @override
  Future<void> deleteTask(String taskId) async {
    await _box.delete(taskId);
  }

  @override
  Future<void> clearCompleted() async {
    final completed = _box.values
        .where((t) => t != null && (t!.status == 2 || t!.status == 4 || t!.status == 5))
        .map((t) => t!.id)
        .toList();
    await _box.deleteAll(completed);
    AppLogger.info('Cleared ${completed.length} completed download tasks');
  }

  @override
  Stream<List<DownloadTaskModel>> watchAllTasks() {
    return _box.watch().map((_) => _box.values.where((t) => t != null).cast<DownloadTaskModel>().toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  }

  @override
  Stream<DownloadTaskModel> watchTask(String taskId) {
    return _box
        .watch(key: taskId)
        .map((event) => event.value as DownloadTaskModel)
        .where((task) => task != null && task.id == taskId);
  }
}
