import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/video_info.dart';
import '../../../domain/entities/quality_option.dart';
import '../../providers/video_parse_provider.dart';
import '../../providers/download_provider.dart';
import '../../widgets/url_input_card.dart';
import '../../widgets/video_info_card.dart';
import '../../widgets/quality_selector.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/ads/banner_ad_widget.dart';
import '../player/web_player_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
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
      body: Column(
        children: [
          Expanded(
            child: SafeArea(
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    floating: true,
                    title: RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: 'Video ',
                            style: TextStyle(
                              fontWeight: FontWeight.w300,
                              fontSize: 22,
                            ),
                          ),
                          TextSpan(
                            text: 'Downloader',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 22,
                              color: AppColors.primaryColor,
                            ),
                          ),
                          TextSpan(
                            text: ' Pro',
                            style: TextStyle(
                              fontWeight: FontWeight.w300,
                              fontSize: 22,
                            ),
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.workspace_premium_outlined),
                        onPressed: () => context.push(AppRoutes.premium),
                        tooltip: 'Go Premium',
                      ),
                    ],
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        UrlInputCard(
                          onSubmit: (url) {
                            _selectedQuality = null;
                            ref.read(videoParseProvider.notifier).parseUrl(url);
                          },
                        ),
                        const SizedBox(height: 16),
                        parseState.when(
                          data: (videoInfo) {
                            if (videoInfo == null) {
                              return const _SupportedPlatforms();
                            }
                            return Column(
                              children: [
                                VideoInfoCard(videoInfo: videoInfo),
                                const SizedBox(height: 12),

                                // Practical fallback: let users watch the page inside the app.
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => WebPlayerScreen(
                                            url: videoInfo.url,
                                            title: videoInfo.title,
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.play_circle_outline),
                                    label: const Text('Play in app'),
                                  ),
                                ),

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
                          error: (error, _) =>
                              _ErrorCard(message: error.toString()),
                        ),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const BannerAdWidget(),
        ],
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

class _SupportedPlatforms extends StatelessWidget {
  const _SupportedPlatforms();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Supported Platforms',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                _PlatformChip(label: 'YouTube', emoji: '▶️'),
                _PlatformChip(label: 'TikTok', emoji: '🎵'),
                _PlatformChip(label: 'Instagram', emoji: '📸'),
                _PlatformChip(label: 'Facebook', emoji: '👤'),
                _PlatformChip(label: 'Twitter/X', emoji: '🐦'),
                _PlatformChip(label: 'Vimeo', emoji: '🎬'),
                _PlatformChip(label: 'Dailymotion', emoji: '📹'),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Paste any video URL above to start downloading.',
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlatformChip extends StatelessWidget {
  const _PlatformChip({required this.label, required this.emoji});

  final String label;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$emoji $label'),
      visualDensity: VisualDensity.compact,
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

