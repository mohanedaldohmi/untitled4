import 'dart:async';
import 'dart:io';

import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../core/utils/logger.dart';

/// Ad Unit IDs — replace with real IDs from AdMob console before publishing
class _AdIds {
  // Android
  static const _androidBanner = 'ca-app-pub-3940256099942544/6300978111';
  static const _androidInterstitial = 'ca-app-pub-3940256099942544/1033173712';
  static const _androidRewarded = 'ca-app-pub-3940256099942544/5224354917';
  static const _androidAppOpen = 'ca-app-pub-3940256099942544/9257395921';

  // iOS
  static const _iosBanner = 'ca-app-pub-3940256099942544/2934735716';
  static const _iosInterstitial = 'ca-app-pub-3940256099942544/4411468910';
  static const _iosRewarded = 'ca-app-pub-3940256099942544/1712485313';
  static const _iosAppOpen = 'ca-app-pub-3940256099942544/5575463023';

  static String get bannerId =>
      Platform.isAndroid ? _androidBanner : _iosBanner;
  static String get interstitialId =>
      Platform.isAndroid ? _androidInterstitial : _iosInterstitial;
  static String get rewardedId =>
      Platform.isAndroid ? _androidRewarded : _iosRewarded;
  static String get appOpenId =>
      Platform.isAndroid ? _androidAppOpen : _iosAppOpen;
}

/// Central ad manager — call [AdsManager.instance] to use
class AdsManager {
  AdsManager._();
  static final AdsManager instance = AdsManager._();

  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  AppOpenAd? _appOpenAd;

  bool _interstitialReady = false;
  bool _rewardedReady = false;
  bool _appOpenReady = false;

  /// Whether ads are enabled (disabled for premium users)
  bool adsEnabled = true;

  /// Number of downloads since last interstitial. Shown every N downloads.
  int _downloadsSinceLastInterstitial = 0;
  static const int _interstitialFrequency = 3;

  // ─── Initialization ────────────────────────────────────────────────────────

  Future<void> init() async {
    if (!adsEnabled) return;
    await _loadInterstitial();
    await _loadRewarded();
    await _loadAppOpenAd();
    AppLogger.info('AdsManager initialized');
  }

  void disableAds() {
    adsEnabled = false;
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    _appOpenAd?.dispose();
    _interstitialAd = null;
    _rewardedAd = null;
    _appOpenAd = null;
    _interstitialReady = false;
    _rewardedReady = false;
    _appOpenReady = false;
    AppLogger.info('Ads disabled (premium user)');
  }

  // ─── Banner ─────────────────────────────────────────────────────────────────

  /// Creates a new BannerAd. Caller is responsible for disposing it.
  BannerAd createBannerAd({required BannerAdListener listener}) {
    return BannerAd(
      adUnitId: _AdIds.bannerId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) => AppLogger.debug('Banner ad loaded'),
        onAdFailedToLoad: (ad, err) {
          AppLogger.warning('Banner ad failed: ${err.message}');
          ad.dispose();
        },
      ),
    );
  }

  // ─── Interstitial ──────────────────────────────────────────────────────────

  Future<void> _loadInterstitial() async {
    await InterstitialAd.load(
      adUnitId: _AdIds.interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialReady = true;
          AppLogger.debug('Interstitial ad loaded');
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (_) {
              _interstitialReady = false;
              _loadInterstitial();
            },
            onAdFailedToShowFullScreenContent: (ad, _) {
              ad.dispose();
              _interstitialReady = false;
              _loadInterstitial();
            },
          );
        },
        onAdFailedToLoad: (err) {
          AppLogger.warning('Interstitial failed to load: ${err.message}');
          _interstitialReady = false;
        },
      ),
    );
  }

  /// Call after a successful download. Shows interstitial every [_interstitialFrequency] downloads.
  Future<void> onDownloadCompleted() async {
    if (!adsEnabled) return;
    _downloadsSinceLastInterstitial++;
    if (_downloadsSinceLastInterstitial >= _interstitialFrequency &&
        _interstitialReady) {
      _downloadsSinceLastInterstitial = 0;
      await showInterstitial();
    }
  }

  Future<void> showInterstitial() async {
    if (!adsEnabled || !_interstitialReady || _interstitialAd == null) return;
    await _interstitialAd!.show();
    _interstitialReady = false;
  }

  // ─── Rewarded ─────────────────────────────────────────────────────────────

  Future<void> _loadRewarded() async {
    await RewardedAd.load(
      adUnitId: _AdIds.rewardedId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _rewardedReady = true;
          AppLogger.debug('Rewarded ad loaded');
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (_) {
              _rewardedReady = false;
              _loadRewarded();
            },
            onAdFailedToShowFullScreenContent: (ad, _) {
              ad.dispose();
              _rewardedReady = false;
              _loadRewarded();
            },
          );
        },
        onAdFailedToLoad: (err) {
          AppLogger.warning('Rewarded ad failed to load: ${err.message}');
          _rewardedReady = false;
        },
      ),
    );
  }

  /// Show a rewarded ad. [onRewarded] is called if the user earns the reward.
  Future<void> showRewarded({required void Function() onRewarded}) async {
    if (!_rewardedReady || _rewardedAd == null) {
      AppLogger.warning('Rewarded ad not ready');
      return;
    }
    await _rewardedAd!.show(
      onUserEarnedReward: (_, __) {
        AppLogger.info('User earned reward');
        onRewarded();
      },
    );
    _rewardedReady = false;
  }

  bool get isRewardedReady => _rewardedReady && adsEnabled;

  // ─── App Open ─────────────────────────────────────────────────────────────

  Future<void> _loadAppOpenAd() async {
    await AppOpenAd.load(
      adUnitId: _AdIds.appOpenId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          _appOpenReady = true;
          AppLogger.debug('App open ad loaded');
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (_) {
              _appOpenReady = false;
              ad.dispose();
              _loadAppOpenAd();
            },
            onAdFailedToShowFullScreenContent: (ad, _) {
              _appOpenReady = false;
              ad.dispose();
              _loadAppOpenAd();
            },
          );
        },
        onAdFailedToLoad: (err) {
          AppLogger.warning('App open ad failed: ${err.message}');
          _appOpenReady = false;
        },
      )
    );
  }

  Future<void> showAppOpenAd() async {
    if (!adsEnabled || !_appOpenReady || _appOpenAd == null) return;
    await _appOpenAd!.show();
    _appOpenReady = false;
  }

  void dispose() {
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    _appOpenAd?.dispose();
  }
}
