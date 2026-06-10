import '../repositories/repositories.dart';

class GetSettingsUseCase {
  const GetSettingsUseCase(this._repository);

  final SettingsRepository _repository;

  Future<T?> get<T>(String key) => _repository.getSetting<T>(key);

  Future<void> set<T>(String key, T value) =>
      _repository.saveSetting<T>(key, value);

  Future<void> remove(String key) => _repository.removeSetting(key);
}
