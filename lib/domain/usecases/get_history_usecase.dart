import '../entities/video_info.dart';
import '../repositories/repositories.dart';

class GetHistoryUseCase {
  const GetHistoryUseCase(this._repository);

  final HistoryRepository _repository;

  Future<List<VideoInfo>> call() => _repository.getHistory();

  Future<void> add(VideoInfo videoInfo) => _repository.addToHistory(videoInfo);

  Future<void> remove(String videoId) =>
      _repository.removeFromHistory(videoId);

  Future<void> clear() => _repository.clearHistory();
}
