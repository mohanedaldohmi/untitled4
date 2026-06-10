import '../../domain/repositories/repositories.dart';
import '../../services/storage/hive_storage_service.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  @override
  Future<T?> getSetting<T>(String key) async {
    return HiveStorageService.getSetting<T>(key);
  }

  @override
  Future<void> saveSetting<T>(String key, T value) async {
    await HiveStorageService.saveSetting<T>(key, value);
  }

  @override
  Future<void> removeSetting(String key) async {
    await HiveStorageService.removeSetting(key);
  }
}
