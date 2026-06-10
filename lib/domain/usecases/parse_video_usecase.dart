import '../entities/video_info.dart';
import '../repositories/repositories.dart';

class ParseVideoUseCase {
  const ParseVideoUseCase(this._repository);

  final VideoRepository _repository;

  Future<VideoInfo> call(String url) async {
    return _repository.parseVideoInfo(url);
  }
}
