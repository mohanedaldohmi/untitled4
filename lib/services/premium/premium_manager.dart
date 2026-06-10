import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/logger.dart';
import '../../services/storage/hive_storage_service.dart';

/// Product IDs — must match what you configure in Play Console / App Store Connect
class PremiumProductIds {
  static const String monthly = 'vdp_premium_monthly';
  static const String yearly = 'vdp_premium_yearly';
  static const String lifetime = 'vdp_premium_lifetime';

  static const Set<String> all = {monthly, yearly, lifetime};
}

/// Manages premium / subscription state and in-app purchases
class PremiumManager extends ChangeNotifier {
  PremiumManager._();
  static final PremiumManager instance = PremiumManager._();

  final InAppPurchase _iap = InAppPurchase.instance;

  bool _isPremium = false;
  bool _isAvailable = false;
  bool _isLoading = false;
  String? _errorMessage;

  List<ProductDetails> _products = [];
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  bool get isPremium => _isPremium;
  bool get isAvailable => _isAvailable;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<ProductDetails> get products => _products;

  // ─── Initialization ────────────────────────────────────────────────────────

  Future<void> init() async {
    // Restore from local storage first (fast path)
    _isPremium =
        HiveStorageService.getSetting<bool>(AppConstants.isPremiumKey) ?? false;

    _isAvailable = await _iap.isAvailable();
    if (!_isAvailable) {
      AppLogger.warning('In-app purchases not available on this device');
      notifyListeners();
      return;
    }

    // Listen for purchase updates
    _purchaseSubscription =
        _iap.purchaseStream.listen(_handlePurchaseUpdate, onError: (err) {
      AppLogger.error('Purchase stream error', err);
    });

    await _loadProducts();
    await _restorePurchases();
    AppLogger.info('PremiumManager initialized. isPremium=$_isPremium');
  }

  Future<void> _loadProducts() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response =
          await _iap.queryProductDetails(PremiumProductIds.all);
      if (response.error != null) {
        _errorMessage = response.error!.message;
        AppLogger.warning('Product load error: ${response.error!.message}');
      }
      _products = response.productDetails;
      AppLogger.info('Loaded ${_products.length} products');
    } catch (e, stack) {
      _errorMessage = e.toString();
      AppLogger.error('Failed to load products', e, stack);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Purchase ──────────────────────────────────────────────────────────────

  Future<void> purchase(ProductDetails product) async {
    if (!_isAvailable) return;
    final purchaseParam = PurchaseParam(productDetails: product);

    final isConsumable = product.id == PremiumProductIds.lifetime;
    if (isConsumable) {
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } else {
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    }
  }

  Future<void> _restorePurchases() async {
    try {
      await _iap.restorePurchases();
    } catch (e) {
      AppLogger.warning('Restore purchases error: $e');
    }
  }

  Future<void> restorePurchases() => _restorePurchases();

  // ─── Handle Updates ────────────────────────────────────────────────────────

  void _handlePurchaseUpdate(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      _handleSinglePurchase(purchase);
    }
  }

  Future<void> _handleSinglePurchase(PurchaseDetails purchase) async {
    if (purchase.status == PurchaseStatus.purchased ||
        purchase.status == PurchaseStatus.restored) {
      if (PremiumProductIds.all.contains(purchase.productID)) {
        await _activatePremium();
      }
    } else if (purchase.status == PurchaseStatus.error) {
      _errorMessage = purchase.error?.message ?? 'Purchase failed';
      AppLogger.error('Purchase error: $_errorMessage');
      notifyListeners();
    }

    if (purchase.pendingCompletePurchase) {
      await _iap.completePurchase(purchase);
    }
  }

  Future<void> _activatePremium() async {
    _isPremium = true;
    await HiveStorageService.saveSetting(AppConstants.isPremiumKey, true);
    AppLogger.info('Premium activated!');
    notifyListeners();
  }

  /// For testing: manually grant/revoke premium
  Future<void> debugSetPremium(bool value) async {
    _isPremium = value;
    await HiveStorageService.saveSetting(AppConstants.isPremiumKey, value);
    notifyListeners();
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    super.dispose();
  }
}
