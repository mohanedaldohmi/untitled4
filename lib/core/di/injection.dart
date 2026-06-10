import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import '../../core/network/network_info.dart';
import '../../data/datasources/download_local_datasource.dart';
import '../../data/datasources/video_remote_datasource.dart';
import '../../data/repositories/download_repository_impl.dart';
import '../../data/repositories/history_repository_impl.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../data/repositories/video_repository_impl.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/usecases/get_history_usecase.dart';
import '../../domain/usecases/get_settings_usecase.dart';
import '../../domain/usecases/manage_download_usecase.dart';
import '../../domain/usecases/parse_video_usecase.dart';
import '../../domain/usecases/start_download_usecase.dart';

// ─── Infrastructure ──────────────────────────────────────────────────────────

final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient.instance;
});

final connectivityProvider = Provider<Connectivity>((ref) {
  return Connectivity();
});

final networkInfoProvider = Provider<NetworkInfo>((ref) {
  return NetworkInfoImpl(ref.watch(connectivityProvider));
});

// ─── Data Sources ─────────────────────────────────────────────────────────────

final downloadLocalDataSourceProvider =
    FutureProvider<DownloadLocalDataSource>((ref) async {
  return HiveDownloadLocalDataSource.create();
});

final videoRemoteDataSourceProvider = Provider<VideoRemoteDataSource>((ref) {
  return VideoRemoteDataSourceImpl(ref.watch(dioClientProvider));
});

// ─── Repositories ─────────────────────────────────────────────────────────────

final videoRepositoryProvider = Provider<VideoRepository>((ref) {
  return VideoRepositoryImpl(ref.watch(videoRemoteDataSourceProvider));
});

final downloadRepositoryProvider =
    FutureProvider<DownloadRepository>((ref) async {
  final local = await ref.watch(downloadLocalDataSourceProvider.future);
  return DownloadRepositoryImpl(
    localDataSource: local,
    dioClient: ref.watch(dioClientProvider),
  );
});

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return HistoryRepositoryImpl();
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepositoryImpl();
});

// ─── Use Cases ───────────────────────────────────────────────────────────────

final parseVideoUseCaseProvider = Provider<ParseVideoUseCase>((ref) {
  return ParseVideoUseCase(ref.watch(videoRepositoryProvider));
});

final startDownloadUseCaseProvider =
    FutureProvider<StartDownloadUseCase>((ref) async {
  final repo = await ref.watch(downloadRepositoryProvider.future);
  return StartDownloadUseCase(repo);
});

final manageDownloadUseCaseProvider =
    FutureProvider<ManageDownloadUseCase>((ref) async {
  final repo = await ref.watch(downloadRepositoryProvider.future);
  return ManageDownloadUseCase(repo);
});

final getHistoryUseCaseProvider = Provider<GetHistoryUseCase>((ref) {
  return GetHistoryUseCase(ref.watch(historyRepositoryProvider));
});

final getSettingsUseCaseProvider = Provider<GetSettingsUseCase>((ref) {
  return GetSettingsUseCase(ref.watch(settingsRepositoryProvider));
});
