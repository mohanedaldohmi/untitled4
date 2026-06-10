import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../core/errors/app_exception.dart';
import '../../core/network/dio_client.dart';
import '../../core/utils/file_utils.dart';
import '../../core/utils/logger.dart';
import '../../domain/entities/download_task.dart';
import '../../domain/entities/quality_option.dart';
import '../../domain/entities/video_info.dart';
import '../../domain/repositories/repositories.dart';
import '../datasources/download_local_datasource.dart';
import '../models/download_task_model.dart';

class DownloadRepositoryImpl implements DownloadRepository {
  DownloadRepositoryImpl({
    required DownloadLocalDataSource localDataSource,
    required DioClient dioClient,
  })  : _local = localDataSource,
        _dio = dioClient;

  final DownloadLocalDataSource _local;
  final DioClient _dio;

  static const _uuid = Uuid();

  final _cancelTokens = <String, CancelToken>{};
  final _progressControllers = <String, StreamController<DownloadTask>>{};

  @override
  Future<DownloadTask> createDownloadTask({
    required VideoInfo videoInfo,
    required QualityOption quality,
  }) async {
    final filePath = await FileUtils.buildFilePath(
      videoInfo.title,
      quality.format,
    );

    final model = DownloadTaskModel(
      id: _uuid.v4(),
      url: videoInfo.url,
      title: videoInfo.title,
      thumbnailUrl: videoInfo.thumbnailUrl,
      downloadUrl: quality.downloadUrl,
      platform: videoInfo.platform,
      quality: quality.label,
      format: quality.format,
      status: DownloadStatus.pending.index,
      createdAt: DateTime.now(),
      filePath: filePath,
      totalBytes: quality.fileSize ?? 0,
    );

    await _local.saveTask(model);
    return model.toEntity();
  }

  @override
  Future<void> startDownload(String taskId) async {
    final model = await _local.getTask(taskId);
    if (model == null) throw DownloadException('Task not found', taskId: taskId);

    final cancelToken = CancelToken();
    _cancelTokens[taskId] = cancelToken;

    model.status = DownloadStatus.downloading.index;
    model.updatedAt = DateTime.now();
    await _local.saveTask(model);

    _performDownload(model, cancelToken);
  }

  void _performDownload(DownloadTaskModel model, CancelToken cancelToken) async {
    try {
      final filePath = model.filePath!;
      int startByte = 0;

      // Preflight: try to detect unsupported download URLs (often HTML pages)
      await _validateDownloadUrl(model);

      // Check for partial file (resume support)
      final partFile = File('$filePath.part');
      if (await partFile.exists()) {
        startByte = await partFile.length();
        AppLogger.info('Resuming download from byte $startByte: ${model.title}');
      }

      await _dio.download(
        model.downloadUrl,
        '$filePath.part',
        cancelToken: cancelToken,
        startByte: startByte > 0 ? startByte : null,
        onReceiveProgress: (received, total) async {
          final totalBytes = total > 0 ? total : model.totalBytes;
          model.downloadedBytes = startByte + received;
          model.totalBytes = totalBytes > 0 ? totalBytes : 0;
          model.updatedAt = DateTime.now();
          await _local.saveTask(model);
        },
      );

      // Rename .part to final file
      await partFile.rename(filePath);

      model.status = DownloadStatus.completed.index;
      model.downloadedBytes = model.totalBytes;
      model.updatedAt = DateTime.now();
      await _local.saveTask(model);
      AppLogger.info('Download completed: ${model.title}');
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        AppLogger.info('Download cancelled: ${model.title}');
        return;
      }
      model.status = DownloadStatus.failed.index;
      model.errorMessage = e.message ?? 'Download failed';
      model.updatedAt = DateTime.now();
      await _local.saveTask(model);
    } on DownloadException catch (e) {
      model.status = DownloadStatus.failed.index;
      model.errorMessage = e.message;
      model.updatedAt = DateTime.now();
      await _local.saveTask(model);
    } catch (e, stack) {
      AppLogger.error('Download error: ${model.title}', e, stack);
      model.status = DownloadStatus.failed.index;
      model.errorMessage = e.toString();
      model.updatedAt = DateTime.now();
      await _local.saveTask(model);
    } finally {
      _cancelTokens.remove(model.id);
    }
  }

  Future<void> _validateDownloadUrl(DownloadTaskModel model) async {
    try {
      // Many platforms return a watch-page URL as a placeholder; downloading that yields HTML.
      final response = await _dio.dio.head<dynamic>(
        model.downloadUrl,
        options: Options(
          followRedirects: true,
          validateStatus: (s) => s != null && s < 500,
        ),
      );

      final status = response.statusCode ?? 0;
      if (status >= 400) {
        throw DownloadException(
          'Could not access download URL (HTTP $status).',
          taskId: model.id,
        );
      }

      final contentType = response.headers.value('content-type')?.toLowerCase();
      if (contentType == null) return; // some servers don't return it on HEAD

      // If it's clearly HTML, it's not a media file.
      if (contentType.contains('text/html') || contentType.contains('application/xhtml')) {
        throw DownloadException(
          'This link is a webpage, not a direct video file.\n'
          'For YouTube/TikTok/Instagram, the app needs a server extractor to generate a direct MP4 link.',
          taskId: model.id,
        );
      }

      // Basic allow-list: video/audio or common stream manifests.
      final looksLikeMedia = contentType.startsWith('video/') ||
          contentType.startsWith('audio/') ||
          contentType.contains('application/octet-stream') ||
          contentType.contains('application/vnd.apple.mpegurl') ||
          contentType.contains('application/x-mpegurl');

      if (!looksLikeMedia) {
        // Not fatal for all servers, but usually indicates a non-media resource.
        AppLogger.debug(
          'Download URL content-type does not look like media: $contentType (${model.downloadUrl})',
        );
      }
    } catch (e) {
      // If HEAD fails (some servers block), don't block download; just log.
      if (e is DownloadException) rethrow;
      AppLogger.debug('Preflight HEAD failed for ${model.downloadUrl}: $e');
    }
  }

  @override
  Future<void> pauseDownload(String taskId) async {
    _cancelTokens[taskId]?.cancel('paused');
    _cancelTokens.remove(taskId);

    final model = await _local.getTask(taskId);
    if (model == null) return;
    model.status = DownloadStatus.paused.index;
    model.updatedAt = DateTime.now();
    await _local.saveTask(model);
  }

  @override
  Future<void> resumeDownload(String taskId) async {
    final model = await _local.getTask(taskId);
    if (model == null) return;
    model.status = DownloadStatus.pending.index;
    model.updatedAt = DateTime.now();
    await _local.saveTask(model);
    await startDownload(taskId);
  }

  @override
  Future<void> cancelDownload(String taskId) async {
    _cancelTokens[taskId]?.cancel('cancelled');
    _cancelTokens.remove(taskId);

    final model = await _local.getTask(taskId);
    if (model == null) return;

    // Delete partial file
    if (model.filePath != null) {
      await FileUtils.deleteFile('${model.filePath}.part');
    }

    model.status = DownloadStatus.cancelled.index;
    model.updatedAt = DateTime.now();
    await _local.saveTask(model);
  }

  @override
  Future<void> deleteDownload(String taskId) async {
    await cancelDownload(taskId);
    final model = await _local.getTask(taskId);
    if (model?.filePath != null) {
      await FileUtils.deleteFile(model!.filePath!);
    }
    await _local.deleteTask(taskId);
  }

  @override
  Stream<DownloadTask> watchDownloadTask(String taskId) {
    return _local.watchTask(taskId).map((m) => m!.toEntity());
  }

  @override
  Stream<List<DownloadTask>> watchAllDownloadTasks() {
    return _local.watchAllTasks().map((list) => list.map((m) => m!.toEntity()).toList());
  }

  @override
  Future<List<DownloadTask>> getAllDownloadTasks() async {
    final models = await _local.getAllTasks();
    return models.map((m) => m!.toEntity()).toList();
  }

  @override
  Future<DownloadTask?> getDownloadTask(String taskId) async {
    final model = await _local.getTask(taskId);
    return model?.toEntity();
  }

  @override
  Future<int> getActiveDownloadCount() async {
    final tasks = await _local.getAllTasks();
    return tasks
        .where(
          (t) => t!.status == DownloadStatus.downloading.index || t!.status == DownloadStatus.pending.index,
        )
        .length;
  }

  @override
  Future<void> clearCompleted() => _local.clearCompleted();
}
