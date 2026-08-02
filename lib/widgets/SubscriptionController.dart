import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:sleepable_ai/widgets/rating_dialog.dart';
import 'package:sleepable_ai/widgets/showPremiumOfferSheet.dart';
import '../core/constants/app_constants.dart';
import '../core/constants/shared_prefences.dart';
import '../core/utils/library.dart';
import '../data/services/api_end_point.dart';
import '../data/services/network_utils.dart';
import '../modules/sleep_sound/controllers/sleep_sound_controller.dart';
import '../modules/subscription/model/spin_data.dart';

class SubscriptionController extends GetxController {
  RxList<Package> packages = <Package>[].obs;
  Rx<Package?> spinPackage = Rx<Package?>(null);
  Rx<Package?> spinYearlyPackage = Rx<Package?>(null);
  Rx<Package?> spinWeeklyPackage = Rx<Package?>(null);
  RxBool isPremium = false.obs;
  RxBool isLoading = false.obs;
  static const String PREM_KEY = "is_user_premium_cache";
  static const String SPIN_CACHE_KEY = "spin_status_cache";
  Rx<SpinData?> spinInfo = Rx<SpinData?>(null);
  // RxBool isReady = false.obs;
  RxBool isInitialSyncDone = false.obs;
  static bool isConfigured = false;



  @override
  void onInit() {
    super.onInit();
    // Start from the cached value so a paying user is not shown the free/paywall
    // state for the second or two the network sync takes.
    isPremium.value = getBoolAsync(PREM_KEY, defaultValue: false);

    // 2. Agar user logged in hai toh sync start karein
    if (getStringAsync(AppSharedPreferenceKeys.apiToken).isNotEmpty) {
      initData();
    } else {
      isInitialSyncDone.value = true; // Guest user ke liye sync done
    }
  }

  Future<void> initData() async {
    try {
      await Purchases.invalidateCustomerInfoCache();
      isLoading.value = true;
      print("🔄 [DEBUG] initData started...");

      // ✅ STEP 1: Pehle Store Products load karein (Ye zaroori hai)
      print("📦 [DEBUG] Fetching Store Products...");
      await fetchStoreProducts();

      // ✅ STEP 2: Ab status check karein
      print("📡 [DEBUG] Checking Premium Status...");
      await checkPremiumStatus();
      await getBackendSubscriptionStatus();

      await checkSpinStatus();

    } catch (e) {
      print("❌ [DEBUG] Sync Error: $e");
    } finally {
      print("🏁 [DEBUG] initData finished.");
      isLoading.value = false;
      isInitialSyncDone.value = true;
    }
  }

// SubscriptionController.dart mein isse update karein
  Future<void> updatePremiumStatus(bool status, {bool isFromBackend = false}) async {
    // Blocking accidental downgrade: only the backend may turn premium off, so a
    // slow/failed RevenueCat lookup cannot lock a paying user out.
    if (isPremium.value == true && status == false && !isFromBackend) {
      print("🛡️ Blocking accidental downgrade");
      return;
    }

    isPremium.value = status;
    await setValue(PREM_KEY, status);
    isPremium.refresh();
    print("🔔 Cache Updated to: $status");
  }
  bool get hasSpecialOffer => spinInfo.value != null && (spinInfo.value!.discountPct ?? 0) > 0;

  /// iOS: show discount upfront on the primary paywall (no spin required).
  bool shouldShowDiscountOnPaywall() {
    if (Platform.isIOS) {
      return spinYearlyPackage.value != null || (spinInfo.value?.discountPct ?? 0) > 0;
    }
    final spinData = spinInfo.value;
    return spinData != null &&
        (spinData.alreadySpun == true || (spinData.discountPct ?? 0) > 0);
  }

  int get paywallDiscountPercent => spinInfo.value?.discountPct ?? 50;

  /// iOS paywall price line: "Just {price} /year ({symbol}{weekly} / WEEK)"
  String formatIosYearlyPriceLine({
    required String prefix,
    required String yearlyPrice,
    required String currencySymbol,
    required String weeklyAvg,
  }) {
    return '$prefix $yearlyPrice /year ($currencySymbol$weeklyAvg / WEEK)';
  }

  /// iOS trial footer: "3 days free, then {price} /year ({symbol}{weekly} / WEEK)"
  String formatIosTrialSubtext({
    required String yearlyPrice,
    required String currencySymbol,
    required String weeklyAvg,
  }) {
    return '3 days free, then $yearlyPrice /year ($currencySymbol$weeklyAvg / WEEK)';
  }

  /// Store-localized yearly price (App Store / Play Store). Same for iOS & Android.
  String getDisplayYearlyPrice({
    required SpinData? spinData,
    required Package? discountPackage,
    required Package? standardPackage,
    required bool showOffer,
  }) {
    if (!showOffer) {
      return standardPackage?.storeProduct.priceString ?? '';
    }
    final storePrice = discountPackage?.storeProduct.priceString
        ?? standardPackage?.storeProduct.priceString
        ?? '';
    if (storePrice.isNotEmpty) return storePrice;
    // Last resort only if offerings failed to load
    return spinData?.discountedPrice ?? '';
  }

  double getDisplayYearlyRawPrice({
    required SpinData? spinData,
    required Package? discountPackage,
    required Package? standardPackage,
    required bool showOffer,
  }) {
    if (!showOffer) {
      return standardPackage?.storeProduct.price ?? 0;
    }
    final storePrice = discountPackage?.storeProduct.price
        ?? standardPackage?.storeProduct.price
        ?? 0;
    if (storePrice > 0) return storePrice;
    // Last resort only if offerings failed to load
    if (spinData?.discountedPrice != null) {
      final cleanPrice = spinData!.discountedPrice!
          .replaceAll(',', '')
          .replaceAll(RegExp(r'[^0-9.]'), '');
      final parsed = double.tryParse(cleanPrice);
      if (parsed != null) return parsed;
    }
    return 0;
  }

  /// Currency symbol from store product currencyCode (Play / App Store country).
  String resolvePaywallCurrencySymbol({
    required Package package,
    required String displayPrice,
  }) {
    // displayPrice kept for call-site compatibility; symbol is always from store.
    return getCurrencySymbol(package.storeProduct.currencyCode);
  }

  static Future<void> init() async {
    await Purchases.setLogLevel(LogLevel.debug);

    PurchasesConfiguration configuration;

    if (Platform.isAndroid) {
      configuration = PurchasesConfiguration("goog_luerHREwpCvCyPwXSpTHyubfXpb");
    } else if (Platform.isIOS) {
      // ✅ Aapki nayi iOS Key yahan add ho gayi hai
      configuration = PurchasesConfiguration("appl_fDrWUKJQoAoYEradFYKasuTvvPr");
    } else {
      return;
    }

    try {
      await Purchases.configure(configuration);
      isConfigured = true;
      print("✅ RevenueCat configured successfully for ${Platform.isIOS ? 'iOS' : 'Android'}");
    } catch (e) {
      isConfigured = false;
      print("❌ RevenueCat Configuration Error: $e");
    }
  }

  Future<void> fetchStoreProducts() async {
    if (!isConfigured) return;
    try {
      Offerings offerings = await Purchases.getOfferings();
      print("🔍 [RC] Total Offerings found: ${offerings.all.keys.toList()}");

      // ✅ 1. Current / Regular Offering Loading (default_new - ₹5,400)
      if (offerings.current != null) {
        final allAvailablePackages = offerings.current!.availablePackages;

        // Saare regular packages ko map karo reactive list mein
        packages.assignAll(allAvailablePackages);
        print("✅ [RC] Standard Plans Loaded from Current: ${packages.length}");

        // Regular Weekly plan link karein
        spinWeeklyPackage.value = allAvailablePackages.firstWhereOrNull(
                (p) => p.packageType == PackageType.weekly
        );
      }

      // ✅ 2. Discount Offering Loading (discount_offering - ₹2,800)
      // 🔥 ABSOLUTE SYNC LOCK: Ab hum specific discount offering ko dashboard se target kar rahe hain
      if (offerings.all["discount_offering"] != null) {
        final discountOffering = offerings.all["discount_offering"]!;

        // Dashboard par humne 'Annual' identifier link kiya hai, toh direct .annual uthayenge
        spinYearlyPackage.value = discountOffering.annual;

        if (spinYearlyPackage.value != null) {
          print("🎁 [RC] SPIN OFFER LOADED FROM discount_offering: ${spinYearlyPackage.value?.storeProduct.priceString}");
        }
      } else {
        print("⚠️ [RC] 'discount_offering' NOT FOUND in RevenueCat Dashboard");
      }

    } catch (e) {
      print("❌ [RC] Fetch Error: $e");
    }
  }
  Future<void> buyProduct(Package package) async {
    if (!isConfigured) {
      toast("Store not available on this device");
      print("Store not available on this device");
      return;
    }
    try {
      isLoading.value = true;

      // Step 1: RevenueCat Purchase
      final purchaseResult = await Purchases.purchasePackage(package);
      CustomerInfo customerInfo = purchaseResult.customerInfo;

      // Step 2: Check Entitlement (Identifier 'pro' hi rakhna dashboard par)
      if (customerInfo.entitlements.all['pro']?.isActive ?? false) {

        // ✅ Backend Sync: Product ID aur User ID bhejein
        await verifyPurchaseWithBackend(
            package.storeProduct.identifier,
            customerInfo.originalAppUserId,
            spinInfo.value?.couponCode
        );

        isPremium.value = true;
        if (Get.isRegistered<SleepSoundController>()) {
          final soundCtrl = Get.find<SleepSoundController>();
          soundCtrl.soundsBySubCategory.clear();
          soundCtrl.refreshCurrentTabSilently();
        }
        toast("Success! Premium Activated.");
        Get.until((route) => Get.isOverlaysClosed);
        Get.offAllNamed(Routes.dashboard);
      }
    } on PlatformException catch (e) {
      var errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        // User ne cancel kiya, koi galti nahi hai
      } else {
        toast("Purchase Error: ${e.message}");
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Apple Guideline 3.1.1: users must be able to restore a subscription they
  /// already own (after reinstalling or on a new device). Wired to the "Restore
  /// Purchases" button in Settings and on the iOS paywall.
  Future<void> restorePurchases() async {
    if (!isConfigured) {
      toast("Store not available on this device");
      return;
    }
    try {
      isLoading.value = true;
      final CustomerInfo customerInfo = await Purchases.restorePurchases();
      final bool active = customerInfo.entitlements.all['pro']?.isActive ?? false;

      if (active) {
        isPremium.value = true;
        await getBackendSubscriptionStatus();
        if (Get.isRegistered<SleepSoundController>()) {
          final soundCtrl = Get.find<SleepSoundController>();
          soundCtrl.soundsBySubCategory.clear();
          soundCtrl.refreshCurrentTabSilently();
        }
        toast("Purchases restored. Premium is active.");
        Get.until((route) => Get.isOverlaysClosed);
        Get.offAllNamed(Routes.dashboard);
      } else {
        toast("No active subscription found to restore.");
      }
    } on PlatformException catch (e) {
      toast("Restore failed: ${e.message}");
    } catch (e) {
      toast("Restore failed. Please try again.");
    } finally {
      isLoading.value = false;
    }
  }
  // 2. Spin Wheel API (Check Status)
  //
  // A user who already won a discount must never be shown the full price just
  // because this call failed. So retry a few times, and fall back to the last
  // known status from disk instead of silently leaving spinInfo null.
  Future<void> checkSpinStatus({int retries = 2}) async {
    for (int attempt = 0; attempt <= retries; attempt++) {
      try {
        final response = await buildHttpResponse(
            endPoint: APIEndPoints.spinWheel,
            method: MethodType.get
        );
        if (response['success']) {
          final data = SpinData.fromJson(response['data']);
          spinInfo.value = data;
          await setValue(SPIN_CACHE_KEY, jsonEncode(data.toJson()));
          return;
        }
      } catch (e) {
        log("Spin Status attempt ${attempt + 1} failed: $e");
      }
      if (attempt < retries) {
        await Future.delayed(Duration(seconds: 1 << attempt)); // 1s, then 2s
      }
    }
    _restoreSpinStatusFromCache();
  }

  void _restoreSpinStatusFromCache() {
    if (spinInfo.value != null) return;
    final cached = getStringAsync(SPIN_CACHE_KEY);
    if (cached.isEmpty) return;
    try {
      spinInfo.value = SpinData.fromJson(jsonDecode(cached));
      log("Spin status restored from cache");
    } catch (e) {
      log("Spin cache restore failed: $e");
    }
  }

  Future<void> performSpin() async {
    try {
      isLoading.value = true;
      print("🚀 [Spin] Starting Spin API Call...");

      final response = await buildHttpResponse(
          endPoint: APIEndPoints.spinWheel,
          method: MethodType.post
      );

      if (response['success'] == true || response['message'].toString().contains("already")) {
        // 1. Data parse karein
        final data = SpinData.fromJson(response['data']);

        // 2. Force status true (Security check)
        data.alreadySpun = true;

        // 3. Rx variable mein assign karein
        spinInfo.value = data;
        // Persist the win so a later failed status call cannot revert the user
        // to the full price.
        await setValue(SPIN_CACHE_KEY, jsonEncode(data.toJson()));

        // 4. 🔥 Turant UI update trigger karein (RevenueCat se pehle)
        update();
        spinInfo.refresh();

        print("💰 [Spin] Price Syncing: ${spinInfo.value?.discountedPrice}");

        // 5. Background mein Store sync karein
        await Purchases.invalidateCustomerInfoCache();
        await fetchStoreProducts();

        print("✅ [Spin] Full Sync Done");
      }
    } catch (e) {
      print("❌ [Spin] Error: $e");
    } finally {
      isLoading.value = false;
      update();
    }
  }

  // 5. Backend Verification API
  Future<void> verifyPurchaseWithBackend(String productId, String token, String? coupon) async {
    try {
      final payload = {
        "product_id": productId,
        "purchase_token": token, // Isme google ka purchase token jayega
        "coupon_code": coupon ?? ""
      };

      await buildHttpResponse(
          endPoint: APIEndPoints.verifyPurchase,
          method: MethodType.post,
          request: payload
      );
      await getBackendSubscriptionStatus(); // Refresh status
    } catch (e) {
      log("Verification Sync Error: $e");
    }
  }

  // 6. Get Status from Backend
  Future<void> getBackendSubscriptionStatus() async {
    try {
      final response = await buildHttpResponse(
          endPoint: APIEndPoints.subscriptionStatus,
          method: MethodType.get
      );
      if (response['success']) {
        bool backendStatus = response['data']['is_premium'] ?? false;
        updatePremiumStatus(backendStatus, isFromBackend: true);
      }
    } catch (e) {
      log("Backend check failed: $e");
    }
  }

  Future<void> checkPremiumStatus() async {
    if (!isConfigured) {
      print("⚠️ [RC] Skipping status check: Not configured");
      return;
    }

    try {
      print("⏳ [RC] Fetching CustomerInfo...");
      CustomerInfo customerInfo = await Purchases.getCustomerInfo().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print("⏰ [RC] CustomerInfo Timeout - Moving on");
          throw TimeoutException("RC Timeout");
        },
      );

      print("✅ [RC] CustomerInfo received");
      bool isActive = customerInfo.entitlements.all['pro']?.isActive ?? false;

      updatePremiumStatus(isActive, isFromBackend: false);
    } catch (e) {
      print("❌ [RC] Error in checkPremiumStatus: $e");
      }
  }
  void checkAndShowPremiumSheet(BuildContext context) {
    if (isPremium.value || Platform.isIOS) return;

    final spinData = spinInfo.value;
    if (spinData != null && spinData.alreadySpun) {
      showPremiumOfferSheet6(context);
    } else {
      showPremiumOfferSheet5(context);
    }
  }
  String getCurrencySymbol(String currencyCode) {
    if (currencyCode == "INR" || currencyCode.toUpperCase() == "INR") {
      return "₹";
    }

    try {
      var format = NumberFormat.simpleCurrency(name: currencyCode);
      return format.currencySymbol;
    } catch (e) {
      final Map<String, String> currencyMap = {
        'USD': '\$',
        'EUR': '€',
        'GBP': '£',
        'JPY': '¥',
        'CAD': 'CA\$',
        'AUD': 'A\$',
      };
      return currencyMap[currencyCode.toUpperCase()] ?? currencyCode;
    }
  }

  void checkAndShowRatingAfterPostDelay() {
    if (Platform.isIOS) return;

    bool hasRated = getBoolAsync("user_has_rated", defaultValue: false);
    if (hasRated) return;

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (Get.context != null && !Get.isDialogOpen!) {
        Get.dialog(
          const RatingDialog(),
          barrierDismissible: false, // User ko "No" ya "Rate" click karne par majboor karein
        );
      }
    });
  }
}
