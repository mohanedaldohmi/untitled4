import '../../domain/entities/video_info.dart';
import '../../domain/repositories/repositories.dart';
import '../datasources/video_remote_datasource.dart';

class VideoRepositoryImpl implements VideoRepository {
  VideoRepositoryImpl(this._remote);

  final VideoRemoteDataSource _remote;

  @override
  Future<VideoInfo> parseVideoInfo(String url) async {
    final model = await _remote.getVideoInfo(url);
    return model.toEntity();
  }
}
