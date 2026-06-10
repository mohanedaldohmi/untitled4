import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/size_formatter.dart';
import '../../domain/entities/download_task.dart';

class DownloadItemCard extends StatelessWidget {
  const DownloadItemCard({
    super.key,
    required this.task,
    this.onPause,
    this.onResume,
    this.onCancel,
    this.onDelete,
    this.onPlay,
    this.onShare,
    this.onOpen,
  });

  final DownloadTask task;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onCancel;
  final VoidCallback? onDelete;
  final VoidCallback? onPlay;
  final VoidCallback? onShare;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: task.thumbnailUrl.isNotEmpty
                      ? Image.network(
                          task.thumbnailUrl,
                          width: 56,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder(),
                        )
                      : _placeholder(),
                ),
                const SizedBox(width: 12),
                // Title + meta
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          _StatusBadge(status: task.status),
                          const SizedBox(width: 6),
                          Text(
                            '${task.quality} • ${task.format.toUpperCase()}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Actions
                _buildActions(context),
              ],
            ),
            // Progress bar for active tasks
            if (task.status == DownloadStatus.downloading) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: task.progress,
                        backgroundColor:
                            Theme.of(context).colorScheme.surfaceContainerHighest,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primaryColor,
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    SizeFormatter.formatProgress(
                      task.downloadedBytes,
                      task.totalBytes,
                    ),
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${SizeFormatter.format(task.downloadedBytes)} / ${SizeFormatter.format(task.totalBytes)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ],
            if (task.status == DownloadStatus.failed &&
                task.errorMessage != null) ...[
              const SizedBox(height: 6),
              Text(
                task.errorMessage!,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.errorColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onPlay != null)
          IconButton(
            icon: const Icon(Icons.play_circle_outline),
            onPressed: onPlay,
            tooltip: 'Play',
            iconSize: 22,
          ),
        if (onOpen != null)
          IconButton(
            icon: const Icon(Icons.open_in_new),
            onPressed: onOpen,
            tooltip: 'Open',
            iconSize: 22,
          ),
        if (onShare != null)
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: onShare,
            tooltip: 'Share',
            iconSize: 22,
          ),
        if (task.status == DownloadStatus.downloading && onPause != null)
          IconButton(
            icon: const Icon(Icons.pause_circle_outline),
            onPressed: onPause,
            tooltip: 'Pause',
            iconSize: 22,
          ),
        if (task.status == DownloadStatus.paused && onResume != null)
          IconButton(
            icon: const Icon(Icons.play_circle_outline),
            onPressed: onResume,
            tooltip: 'Resume',
            iconSize: 22,
          ),
        if ((task.isActive) && onCancel != null)
          IconButton(
            icon: const Icon(Icons.cancel_outlined),
            onPressed: onCancel,
            tooltip: 'Cancel',
            iconSize: 22,
          ),
        if (onDelete != null)
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: onDelete,
            tooltip: 'Delete',
            iconSize: 22,
          ),
      ],
    );
  }

  Widget _placeholder() {
    return Container(
      width: 56,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Icon(Icons.video_file_outlined, size: 20),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final DownloadStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      DownloadStatus.pending => ('Pending', AppColors.primaryColor),
      DownloadStatus.downloading => ('Downloading', AppColors.infoColor),
      DownloadStatus.paused => ('Paused', AppColors.warningColor),
      DownloadStatus.completed => ('Done', AppColors.successColor),
      DownloadStatus.failed => ('Failed', AppColors.errorColor),
      DownloadStatus.cancelled => ('Cancelled', AppColors.textSecondary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
