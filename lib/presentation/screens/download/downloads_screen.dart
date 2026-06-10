import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/download_task.dart';
import '../../providers/download_provider.dart';
import '../../widgets/download_item_card.dart';
import '../../widgets/ads/banner_ad_widget.dart';

class DownloadsScreen extends ConsumerWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadsAsync = ref.watch(downloadsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Downloads'),
        actions: [
          downloadsAsync.maybeWhen(
            data: (tasks) => tasks.any((t) => t.isFinished)
                ? IconButton(
                    icon: const Icon(Icons.clear_all),
                    onPressed: () => _clearCompleted(context, ref),
                    tooltip: 'Clear completed',
                  )
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: downloadsAsync.when(
              data: (tasks) {
                if (tasks.isEmpty) return const _EmptyDownloads();

                final active = tasks.where((t) => t.isActive).toList();
                final finished = tasks.where((t) => t.isFinished).toList();

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (active.isNotEmpty) ...[
                      _SectionHeader(
                        title: 'Active (${active.length})',
                        icon: Icons.downloading,
                      ),
                      const SizedBox(height: 8),
                      ...active.map((task) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: DownloadItemCard(
                              task: task,
                              onPause: () => ref
                                  .read(downloadActionsProvider.notifier)
                                  .pauseDownload(task.id),
                              onResume: () => ref
                                  .read(downloadActionsProvider.notifier)
                                  .resumeDownload(task.id),
                              onCancel: () => ref
                                  .read(downloadActionsProvider.notifier)
                                  .cancelDownload(task.id),
                              onDelete: () => ref
                                  .read(downloadActionsProvider.notifier)
                                  .deleteDownload(task.id),
                            ),
                          )),
                    ],
                    if (finished.isNotEmpty) ...[
                      if (active.isNotEmpty) const SizedBox(height: 16),
                      _SectionHeader(
                        title: 'Completed (${finished.length})',
                        icon: Icons.check_circle_outline,
                      ),
                      const SizedBox(height: 8),
                      ...finished.map((task) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: DownloadItemCard(
                              task: task,
                              onPlay: task.status == DownloadStatus.completed &&
                                      task.filePath != null
                                  ? () => context.push(
                                        '${AppRoutes.player}'
                                        '?filePath=${Uri.encodeComponent(task.filePath!)}'
                                        '&title=${Uri.encodeComponent(task.title)}',
                                      )
                                  : null,
                              onShare: task.status == DownloadStatus.completed &&
                                      task.filePath != null
                                  ? () => _shareFile(context, task)
                                  : null,
                              onOpen: task.status == DownloadStatus.completed &&
                                      task.filePath != null
                                  ? () => _openFile(context, task)
                                  : null,
                              onDelete: () => ref
                                  .read(downloadActionsProvider.notifier)
                                  .deleteDownload(task.id),
                            ),
                          )),
                    ],
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
          const BannerAdWidget(),
        ],
      ),
    );
  }

  Future<void> _shareFile(BuildContext context, DownloadTask task) async {
    if (task.filePath == null) return;
    final file = File(task.filePath!);
    if (!await file.exists()) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File not found')),
        );
      }
      return;
    }
    await Share.shareXFiles(
      [XFile(task.filePath!)],
      text: task.title,
    );
  }

  Future<void> _openFile(BuildContext context, DownloadTask task) async {
    if (task.filePath == null) return;
    final result = await OpenFile.open(task.filePath!);
    if (result.type != ResultType.done && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot open file: ${result.message}')),
      );
    }
  }

  Future<void> _clearCompleted(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Completed'),
        content: const Text(
          'Remove all completed, failed, and cancelled downloads?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(downloadActionsProvider.notifier).clearCompleted();
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primaryColor),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      ],
    );
  }
}

class _EmptyDownloads extends StatelessWidget {
  const _EmptyDownloads();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.download_done_outlined,
              size: 80, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 16),
          Text('No downloads yet',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Paste a video URL on the home screen to get started',
            style: TextStyle(color: Theme.of(context).colorScheme.outline),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
