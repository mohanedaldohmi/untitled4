import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../services/premium/premium_manager.dart';
import '../../providers/download_provider.dart';

class PremiumScreen extends ConsumerStatefulWidget {
  const PremiumScreen({super.key});

  @override
  ConsumerState<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends ConsumerState<PremiumScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final isPremium = ref.watch(isPremiumProvider);
    final pm = PremiumManager.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Go Premium'),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Hero
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                const Icon(Icons.workspace_premium, size: 64, color: Colors.white),
                const SizedBox(height: 16),
                const Text(
                  'Video Downloader Pro',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isPremium ? '✅ Premium Active' : 'Unlock the full experience',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          if (isPremium) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: const [
                    Icon(Icons.check_circle, size: 48, color: AppColors.successColor),
                    SizedBox(height: 12),
                    Text(
                      'You have Premium!',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'All premium features are unlocked. Enjoy unlimited downloads, no ads, and more.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            const Text(
              'Premium Features',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            ..._features.map((f) => _FeatureRow(feature: f)),
            const SizedBox(height: 32),

            // Products from IAP or fallback pricing
            if (pm.products.isNotEmpty) ...[
              ...pm.products.map((product) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _PricingCard(
                      title: product.title,
                      price: product.price,
                      period: '',
                      isHighlighted:
                          product.id == PremiumProductIds.yearly,
                      onTap: () => _purchase(product.id),
                    ),
                  )),
            ] else ...[
              _PricingCard(
                title: 'Monthly',
                price: '\$2.99',
                period: '/month',
                onTap: () => _purchase(PremiumProductIds.monthly),
              ),
              const SizedBox(height: 12),
              _PricingCard(
                title: 'Yearly',
                price: '\$19.99',
                period: '/year',
                badge: 'Save 44%',
                isHighlighted: true,
                onTap: () => _purchase(PremiumProductIds.yearly),
              ),
              const SizedBox(height: 12),
              _PricingCard(
                title: 'Lifetime',
                price: '\$49.99',
                period: ' one-time',
                onTap: () => _purchase(PremiumProductIds.lifetime),
              ),
            ],

            const SizedBox(height: 24),
            TextButton(
              onPressed: _isLoading ? null : _restore,
              child: const Text('Restore Purchases'),
            ),
            const SizedBox(height: 8),
            Text(
              'Payment will be charged to your account. Subscriptions automatically renew unless cancelled.',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],

          if (_isLoading) ...[
            const SizedBox(height: 24),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }

  static const _features = [
    (Icons.download_done, '4K & 1080p Downloads'),
    (Icons.playlist_play, 'Up to 5 Concurrent Downloads'),
    (Icons.block, 'No Ads'),
    (Icons.speed, 'Faster Download Speed'),
    (Icons.audio_file, 'Audio Extraction (MP3)'),
    (Icons.support_agent, 'Priority Support'),
  ];

  Future<void> _purchase(String productId) async {
    final pm = PremiumManager.instance;
    if (!pm.isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('In-app purchases not available')),
      );
      return;
    }

    final product = pm.products.firstWhere(
      (p) => p.id == productId,
      orElse: () => pm.products.first,
    );

    setState(() => _isLoading = true);
    try {
      await pm.purchase(product);
      // Update provider
      ref.read(isPremiumProvider.notifier).state = pm.isPremium;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Purchase failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _restore() async {
    setState(() => _isLoading = true);
    await PremiumManager.instance.restorePurchases();
    ref.read(isPremiumProvider.notifier).state =
        PremiumManager.instance.isPremium;
    setState(() => _isLoading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            PremiumManager.instance.isPremium
                ? 'Premium restored!'
                : 'No active subscription found',
          ),
        ),
      );
    }
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.feature});

  final (IconData, String) feature;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(feature.$1, size: 20, color: AppColors.primaryColor),
          const SizedBox(width: 12),
          Text(feature.$2, style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }
}

class _PricingCard extends StatelessWidget {
  const _PricingCard({
    required this.title,
    required this.price,
    required this.period,
    required this.onTap,
    this.badge,
    this.isHighlighted = false,
  });

  final String title;
  final String price;
  final String period;
  final String? badge;
  final bool isHighlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isHighlighted ? AppColors.primaryColor.withOpacity(0.15) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isHighlighted
            ? const BorderSide(color: AppColors.primaryColor, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          badge!,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 11),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: price,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: isHighlighted
                            ? AppColors.primaryColor
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    TextSpan(
                      text: period,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
