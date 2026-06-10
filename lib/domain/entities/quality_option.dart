import 'package:equatable/equatable.dart';

/// Quality option for a video
class QualityOption extends Equatable {
  const QualityOption({
    required this.label,
    required this.width,
    required this.height,
    required this.downloadUrl,
    required this.format,
    this.fileSize,
    this.bitrate,
    this.hasAudio = true,
    this.isVideoOnly = false,
  });

  final String label;      // e.g., "1080p", "720p", "480p", "360p", "Audio"
  final int width;
  final int height;
  final String downloadUrl;
  final String format;     // e.g., "mp4", "webm", "m4a"
  final int? fileSize;     // bytes, null if unknown
  final int? bitrate;      // bps
  final bool hasAudio;
  final bool isVideoOnly;

  bool get isAudioOnly => format == 'm4a' || format == 'mp3' || !hasAudio && height == 0;

  String get resolution => isAudioOnly ? 'Audio' : '${height}p';

  QualityOption copyWith({
    String? label,
    int? width,
    int? height,
    String? downloadUrl,
    String? format,
    int? fileSize,
    int? bitrate,
    bool? hasAudio,
    bool? isVideoOnly,
  }) {
    return QualityOption(
      label: label ?? this.label,
      width: width ?? this.width,
      height: height ?? this.height,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      format: format ?? this.format,
      fileSize: fileSize ?? this.fileSize,
      bitrate: bitrate ?? this.bitrate,
      hasAudio: hasAudio ?? this.hasAudio,
      isVideoOnly: isVideoOnly ?? this.isVideoOnly,
    );
  }

  @override
  List<Object?> get props => [
        label,
        width,
        height,
        downloadUrl,
        format,
        fileSize,
        bitrate,
        hasAudio,
        isVideoOnly,
      ];
}
