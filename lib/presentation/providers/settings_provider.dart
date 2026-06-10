import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/di/injection.dart';

class SettingsState {
  const SettingsState({
    this.wifiOnlyDownload = false,
    this.defaultQuality = '720p',
    this.maxConcurrent = 1,
    this.saveToGallery = true,
    this.showNotifications = true,
  });

  final bool wifiOnlyDownload;
  final String defaultQuality;
  final int maxConcurrent;
  final bool saveToGallery;
  final bool showNotifications;

  /// Alias used by SettingsScreen
  int get maxConcurrentDownloads => maxConcurrent;

  SettingsState copyWith({
    bool? wifiOnlyDownload,
    String? defaultQuality,
    int? maxConcurrent,
    bool? saveToGallery,
    bool? showNotifications,
  }) {
    return SettingsState(
      wifiOnlyDownload: wifiOnlyDownload ?? this.wifiOnlyDownload,
      defaultQuality: defaultQuality ?? this.defaultQuality,
      maxConcurrent: maxConcurrent ?? this.maxConcurrent,
      saveToGallery: saveToGallery ?? this.saveToGallery,
      showNotifications: showNotifications ?? this.showNotifications,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier(this._ref) : super(const SettingsState()) {
    _loadSettings();
  }

  final Ref _ref;

  Future<void> _loadSettings() async {
    final useCase = _ref.read(getSettingsUseCaseProvider);
    final wifiOnly = await useCase.get<bool>(AppConstants.wifiOnlyKey) ?? false;
    final quality =
        await useCase.get<String>(AppConstants.defaultQualityKey) ?? '720p';
    final concurrent =
        await useCase.get<int>(AppConstants.maxConcurrentKey) ?? 1;
    final gallery =
        await useCase.get<bool>(AppConstants.saveToGalleryKey) ?? true;
    final notifications =
        await useCase.get<bool>(AppConstants.notificationsKey) ?? true;

    state = SettingsState(
      wifiOnlyDownload: wifiOnly,
      defaultQuality: quality,
      maxConcurrent: concurrent,
      saveToGallery: gallery,
      showNotifications: notifications,
    );
  }

  Future<void> setWifiOnly(bool value) async {
    state = state.copyWith(wifiOnlyDownload: value);
    await _ref.read(getSettingsUseCaseProvider).set(AppConstants.wifiOnlyKey, value);
  }

  Future<void> setDefaultQuality(String quality) async {
    state = state.copyWith(defaultQuality: quality);
    await _ref.read(getSettingsUseCaseProvider).set(AppConstants.defaultQualityKey, quality);
  }

  Future<void> setMaxConcurrent(int count) async {
    state = state.copyWith(maxConcurrent: count);
    await _ref.read(getSettingsUseCaseProvider).set(AppConstants.maxConcurrentKey, count);
  }

  Future<void> setSaveToGallery(bool value) async {
    state = state.copyWith(saveToGallery: value);
    await _ref.read(getSettingsUseCaseProvider).set(AppConstants.saveToGalleryKey, value);
  }

  Future<void> setShowNotifications(bool value) async {
    state = state.copyWith(showNotifications: value);
    await _ref.read(getSettingsUseCaseProvider).set(AppConstants.notificationsKey, value);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) => SettingsNotifier(ref),
);
