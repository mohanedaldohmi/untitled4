import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/quality_option.dart';
import '../../../domain/entities/video_info.dart';
import '../../../services/video_detection/video_detector.dart';
import '../../providers/browser_provider.dart';
import '../../providers/download_provider.dart';

/// Bottom sheet shown when user taps the floating download button.
/// Displays video info, thumbnail, and quality options.
class DownloadBottomSheet extends ConsumerStatefulWidget {
  const DownloadBottomSheet({
    super.key,
    required this.detectedVideos,
    required this.pageTitle,
    required this.pageUrl,
  });

  final List<DetectedVideo> detectedVideos;
  final String pageTitle;
  final String pageUrl;

  @override
  ConsumerState<DownloadBottomSheet> createState() => _DownloadBottomSheetState();
}

class _DownloadBottomSheetState extends ConsumerState<DownloadBottomSheet> {
  QualityOption? _selectedQuality;
  bool _isDownloading = false;

  List<QualityOption> get _qualities {
    final video = widget.detectedVideos.isNotEmpty ? widget.detectedVideos.first : null;
    if (video == null) return [];

    final platform = VideoDetector.detectPlatform(widget.pageUrl);
    final List<QualityOption> qualities = [];

    // Build quality options based on detected video properties
    if (video.height >= 1080 || platform == 'YouTube') {
      qualities.add(QualityOption(
        label: '1080p',
        width: 1920,
        height: 1080,
        downloadUrl: video.url,
        format: 'mp4',
      ));
    }

    qualities.addAll([
      QualityOption(
        label: '720p',
        width: 1280,
        height: 720,
        downloadUrl: video.url,
        format: 'mp4',
      ),
      QualityOption(
        label: '480p',
        width: 854,
        height: 480,
        downloadUrl: video.url,
        format: 'mp4',
      ),
      QualityOption(
        label: '360p',
        width: 640,
        height: 360,
        downloadUrl: video.url,
        format: 'mp4',
      ),
    ]);

    // Add audio only option
    qualities.add(QualityOption(
      label: 'Audio Only',
      width: 0,
      height: 0,
      downloadUrl: video.url,
      format: 'mp3',
      hasAudio: true,
    ));

    return qualities;
  }

  String _formatDuration(double seconds) {
    if (seconds <= 0) return '';
    final duration = Duration(seconds: seconds.toInt());
    final hours = duration.inHours;
    final mins = duration.inMinutes.remainder(60);
    final secs = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours}h ${mins}m ${secs}s';
    }
    return '${mins}m ${secs}s';
  }

  Future<void> _startDownload(QualityOption quality) async {
    setState(() => _isDownloading = true);

    final video = widget.detectedVideos.first;
    final videoInfo = VideoInfo(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      url: video.url,
      title: widget.pageTitle.isNotEmpty ? widget.pageTitle : 'Video',
      thumbnailUrl: '',
      platform: VideoDetector.detectPlatform(widget.pageUrl),
      qualities: _qualities,
      duration: video.duration > 0 ? Duration(seconds: video.duration.toInt()) : null,
    );

    await ref
        .read(downloadActionsProvider.notifier)
        .startDownload(videoInfo, quality);

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Download started!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final video = widget.detectedVideos.isNotEmpty ? widget.detectedVideos.first : null;
    final qualities = _qualities;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Thumbnail placeholder
                Container(
                  width: 80,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.videocam, size: 28, color: Colors.grey),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.pageTitle.isNotEmpty ? widget.pageTitle : 'Video',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            VideoDetector.detectPlatform(widget.pageUrl),
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (video != null && video.duration > 0) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.access_time,
                              size: 12,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              _formatDuration(video.duration),
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Quality options
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: qualities.length,
              itemBuilder: (context, index) {
                final quality = qualities[index];
                final isSelected = _selectedQuality == quality;
                final isAudio = quality.isAudioOnly;

                return ListTile(
                  onTap: () => setState(() => _selectedQuality = quality),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryPurple.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isAudio ? Icons.audiotrack : Icons.high_quality,
                      color: isSelected ? AppColors.primaryPurple : Colors.grey,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    isAudio
                        ? 'Audio Only'
                        : '${quality.format.toUpperCase()} - ${quality.label}',
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? AppColors.primaryPurple : null,
                    ),
                  ),
                  subtitle: Text(
                    isAudio ? 'MP3' : '${quality.width}×${quality.height}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: AppColors.primaryPurple)
                      : null,
                );
              },
            ),
          ),
          // Download button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _selectedQuality != null && !_isDownloading
                    ? () => _startDownload(_selectedQuality!)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                ),
                child: _isDownloading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.download_rounded, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Download',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
