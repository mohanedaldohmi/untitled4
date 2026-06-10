import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/quality_option.dart';
import '../../../domain/entities/video_info.dart';
import '../../providers/video_parse_provider.dart';
import '../../providers/download_provider.dart';
import '../../widgets/url_input_card.dart';
import '../../widgets/video_info_card.dart';
import '../../widgets/quality_selector.dart';
import '../../widgets/gradient_button.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  QualityOption? _selectedQuality;

  @override
  Widget build(BuildContext context) {
    final parseState = ref.watch(videoParseProvider);
    final downloadActions = ref.watch(downloadActionsProvider);

    ref.listen(downloadActionsProvider, (_, next) {
      next.whenOrNull(
        error: (error, _) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString()),
            backgroundColor: AppColors.errorColor,
          ),
        ),
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search & Download'),
        actions: [
          if (parseState.value != null)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() => _selectedQuality = null);
                ref.read(videoParseProvider.notifier).reset();
              },
              tooltip: 'Clear',
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            UrlInputCard(
              onSubmit: (url) {
                setState(() => _selectedQuality = null);
                ref.read(videoParseProvider.notifier).parseUrl(url);
              },
            ),
            const SizedBox(height: 16),
            parseState.when(
              data: (videoInfo) {
                if (videoInfo == null) return const _SearchHint();
                return Column(
                  children: [
                    VideoInfoCard(videoInfo: videoInfo),
                    const SizedBox(height: 12),
                    QualitySelector(
                      qualities: videoInfo.qualities,
                      selected: _selectedQuality,
                      onSelected: (q) =>
                          setState(() => _selectedQuality = q),
                    ),
                    const SizedBox(height: 16),
                    GradientButton(
                      onPressed: _selectedQuality != null
                          ? () => _startDownload(videoInfo)
                          : null,
                      isLoading: downloadActions is AsyncLoading,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.download_rounded),
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
                  ],
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, _) => _ErrorCard(message: error.toString()),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startDownload(VideoInfo videoInfo) async {
    final quality = _selectedQuality;
    if (quality == null) return;

    await ref
        .read(downloadActionsProvider.notifier)
        .startDownload(videoInfo, quality);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Download started!'),
          backgroundColor: AppColors.successColor,
        ),
      );
      context.go(AppRoutes.downloads);
    }
  }
}

class _SearchHint extends StatelessWidget {
  const _SearchHint();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.search_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Paste a video URL above',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'YouTube · TikTok · Instagram · Facebook · Twitter · Vimeo · Dailymotion',
              style: TextStyle(
                color: Theme.of(context).colorScheme.outline,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.errorColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.errorColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: AppColors.errorColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
