import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/premium/premium_manager.dart';
import '../../../services/storage/hive_storage_service.dart';
import '../../providers/download_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/theme_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isPremium = ref.watch(isPremiumProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Appearance ────────────────────────────────────────────────────
          _SectionHeader(title: 'Appearance'),
          Card(
            child: SwitchListTile(
              secondary: const Icon(Icons.dark_mode_outlined),
              title: const Text('Dark Mode'),
              value: themeMode == ThemeMode.dark,
              onChanged: (_) =>
                  ref.read(themeModeProvider.notifier).toggleTheme(),
            ),
          ),
          const SizedBox(height: 16),

          // ── Downloads ─────────────────────────────────────────────────────
          _SectionHeader(title: 'Downloads'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.wifi),
                  title: const Text('Wi-Fi Only'),
                  subtitle: const Text('Only download when on Wi-Fi'),
                  value: settings.wifiOnlyDownload,
                  onChanged: (v) =>
                      ref.read(settingsProvider.notifier).setWifiOnly(v),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.high_quality_outlined),
                  title: const Text('Default Quality'),
                  trailing: DropdownButton<String>(
                    value: settings.defaultQuality,
                    underline: const SizedBox.shrink(),
                    items: ['2160p', '1080p', '720p', '480p', '360p', 'Audio']
                        .map((q) => DropdownMenuItem(value: q, child: Text(q)))
                        .toList(),
                    onChanged: (q) {
                      if (q != null) {
                        ref
                            .read(settingsProvider.notifier)
                            .setDefaultQuality(q);
                      }
                    },
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.multiple_stop),
                  title: const Text('Concurrent Downloads'),
                  subtitle: Text(
                    isPremium
                        ? 'Up to ${AppConstants.maxConcurrentDownloadsPremium} (Premium)'
                        : 'Up to ${AppConstants.maxConcurrentDownloadsFree} (Free)',
                  ),
                  trailing: isPremium
                      ? DropdownButton<int>(
                          value: settings.maxConcurrentDownloads
                              .clamp(1, AppConstants.maxConcurrentDownloadsPremium),
                          underline: const SizedBox.shrink(),
                          items: List.generate(
                            AppConstants.maxConcurrentDownloadsPremium,
                            (i) => DropdownMenuItem(
                              value: i + 1,
                              child: Text('${i + 1}'),
                            ),
                          ),
                          onChanged: (v) {
                            if (v != null) {
                              ref
                                  .read(settingsProvider.notifier)
                                  .setMaxConcurrent(v);
                            }
                          },
                        )
                      : const Text(
                          '1',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.photo_library_outlined),
                  title: const Text('Save to Gallery'),
                  subtitle: const Text('Add downloaded videos to gallery'),
                  value: settings.saveToGallery,
                  onChanged: (v) =>
                      ref.read(settingsProvider.notifier).setSaveToGallery(v),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_outlined),
                  title: const Text('Notifications'),
                  subtitle: const Text('Show download progress notifications'),
                  value: settings.showNotifications,
                  onChanged: (v) => ref
                      .read(settingsProvider.notifier)
                      .setShowNotifications(v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Storage ───────────────────────────────────────────────────────
          _SectionHeader(title: 'Storage'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.delete_sweep_outlined),
              title: const Text('Clear Cache'),
              subtitle: const Text('Remove temporary files'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _clearCache(context),
            ),
          ),
          const SizedBox(height: 16),

          // ── Premium ───────────────────────────────────────────────────────
          _SectionHeader(title: 'Premium'),
          Card(
            child: isPremium
                ? const ListTile(
                    leading: Icon(
                      Icons.workspace_premium,
                      color: AppColors.primaryColor,
                    ),
                    title: Text('Premium Active'),
                    subtitle: Text('Enjoy all premium features'),
                    trailing: Icon(
                      Icons.check_circle,
                      color: AppColors.successColor,
                    ),
                  )
                : ListTile(
                    leading: const Icon(
                      Icons.workspace_premium,
                      color: AppColors.primaryColor,
                    ),
                    title: const Text('Upgrade to Premium'),
                    subtitle:
                        const Text('Unlimited downloads, no ads, 4K quality'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(AppRoutes.premium),
                  ),
          ),
          const SizedBox(height: 16),

          // ── About ─────────────────────────────────────────────────────────
          _SectionHeader(title: 'About'),
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('Version'),
                  trailing: Text(AppConstants.appVersion),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('Privacy Policy'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('Terms of Service'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _clearCache(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text('This will remove temporary files. Continue?'),
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
      await HiveStorageService.clearAll();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cache cleared')),
        );
      }
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
