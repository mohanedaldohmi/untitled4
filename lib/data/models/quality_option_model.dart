import '../../domain/entities/quality_option.dart';

class QualityOptionModel {
  const QualityOptionModel({
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

  final String label;
  final int width;
  final int height;
  final String downloadUrl;
  final String format;
  final int? fileSize;
  final int? bitrate;
  final bool hasAudio;
  final bool isVideoOnly;

  factory QualityOptionModel.fromJson(Map<String, dynamic> json) {
    return QualityOptionModel(
      label: json['label'] as String? ?? '${json['height']}p',
      width: json['width'] as int? ?? 0,
      height: json['height'] as int? ?? 0,
      downloadUrl: json['url'] as String? ?? json['downloadUrl'] as String? ?? '',
      format: json['ext'] as String? ?? json['format'] as String? ?? 'mp4',
      fileSize: json['filesize'] as int? ?? json['fileSizeApprox'] as int?,
      bitrate: json['tbr'] != null
          ? ((json['tbr'] as num) * 1000).round()
          : null,
      hasAudio: json['acodec'] != 'none' && json['hasAudio'] != false,
      isVideoOnly: json['acodec'] == 'none',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'width': width,
      'height': height,
      'url': downloadUrl,
      'format': format,
      'filesize': fileSize,
      'bitrate': bitrate,
      'hasAudio': hasAudio,
      'isVideoOnly': isVideoOnly,
    };
  }

  QualityOption toEntity() {
    return QualityOption(
      label: label,
      width: width,
      height: height,
      downloadUrl: downloadUrl,
      format: format,
      fileSize: fileSize,
      bitrate: bitrate,
      hasAudio: hasAudio,
      isVideoOnly: isVideoOnly,
    );
  }

  factory QualityOptionModel.fromEntity(QualityOption entity) {
    return QualityOptionModel(
      label: entity.label,
      width: entity.width,
      height: entity.height,
      downloadUrl: entity.downloadUrl,
      format: entity.format,
      fileSize: entity.fileSize,
      bitrate: entity.bitrate,
      hasAudio: entity.hasAudio,
      isVideoOnly: entity.isVideoOnly,
    );
  }
}
