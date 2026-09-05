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
  RxBool isTrial = false.obs;
  RxString firstReportDate = ''.obs;
  RxInt trialNightsUsed = 0.obs;
  static const String PREM_KEY = "is_user_premium_cache";
  static const String TRIAL_KEY = "is_user_trial_cache";
  static const String FIRST_REPORT_KEY = "trial_first_report_date";
  static const String TRIAL_ENDS_KEY = "trial_ends_at";

  /// Exactly when the store will charge for the trial, straight from the store
  /// via the backend - not a date counted locally. Null unless a trial is running.
  Rx<DateTime?> trialEndsAt = Rx<DateTime?>(null);
  RxBool isLoading = false.obs;
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
    isTrial.value = getBoolAsync(TRIAL_KEY, defaultValue: false);
    firstReportDate.value = getStringAsync(FIRST_REPORT_KEY);
    _restoreTrialEndFromCache();

    // 2. Agar user logged in hai toh sync start karein
    if (getStringAsync(AppSharedPreferenceKeys.apiToken).isNotEmpty) {
      initData();
    } else {
      isInitialSyncDone.value = true; // Guest user ke liye sync done
    }
  }

  Future<void> initData() async {
    try {
      // Re-identify on every launch: a user who logged in before this build (or
      // before RevenueCat finished configuring) would otherwise stay anonymous.
      final storedUuid = getStringAsync(AppSharedPreferenceKeys.userUuid);
      if (storedUuid.isNotEmpty) {
        await identifyUser(storedUuid);
      } else {
        // Anyone already logged in when this build ships never passed through
        // the login path, and will not log in again. Recover their uuid from the
        // cached profile so they do not stay anonymous forever.
        final cachedProfile = getStringAsync(AppSharedPreferenceKeys.currentUserData);
        if (cachedProfile.isNotEmpty) {
          try {
            final uuid = (jsonDecode(cachedProfile)['uuid'] ?? '').toString();
            print("🔑 [RC] Recovered uuid from cached profile: '$uuid'");
            if (uuid.isNotEmpty) await identifyUser(uuid);
          } catch (e) {
            print("❌ [RC] Could not read uuid from cached profile: $e");
          }
        } else {
          print("⚠️ [RC] No stored uuid and no cached profile - user stays anonymous");
        }
      }

      await Purchases.invalidateCustomerInfoCache();
      isLoading.value = true;
      print("🔄 [DEBUG] initData started...");

      // ✅ STEP 1: Pehle Store Products load karein (Ye zaroori hai)
      print("📦 [DEBUG] Fetching Store Products...");
      await fetchStoreProducts();

      // ✅ STEP 2: Ab status check karein
      //
      // Premium access is decided by our backend alone. Some users are granted
      // premium from the admin panel without ever making a store purchase, and
      // RevenueCat has no record of those — asking it would lock them out even
      // though the profile shows PRO. RevenueCat is used to make purchases, not
      // to grant access.
      print("📡 [DEBUG] Checking Premium Status...");
      await getBackendSubscriptionStatus();

      await checkSpinStatus();

      // The store grants a trial once per account - find out before the paywall
      // promises one.
      await refreshTrialEligibility();

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
    if (status) {
      isTrial.value = false;
      await setValue(TRIAL_KEY, false);
    }
    print("🔔 Cache Updated to: $status");
  }

  bool get showPaywalls => !isPremium.value;
  bool get showDreambot => isPremium.value;

  Future<void> applyTrialStatus({required bool trial}) async {
    isTrial.value = trial;
    await setValue(TRIAL_KEY, trial);
  }
  /// Whether the user can open a premium feature.
  ///
  /// A few features are usable during the trial in a limited form - DreamBot
  /// allows one dream - so those pass [trialAllowed]. Everything else stays
  /// locked until the trial converts and the user is actually premium. The
  /// per-feature limit itself is enforced by the backend, not here.
  bool hasAccessTo({bool trialAllowed = false}) {
    if (isPremium.value) return true;
    return trialAllowed && isTrial.value;
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
      Purchases.addCustomerInfoUpdateListener(_onCustomerInfoUpdated);
      print("✅ RevenueCat configured successfully for ${Platform.isIOS ? 'iOS' : 'Android'}");
    } catch (e) {
      isConfigured = false;
      print("❌ RevenueCat Configuration Error: $e");
    }
  }

  static void _onCustomerInfoUpdated(CustomerInfo info) {
    if (!Get.isRegistered<SubscriptionController>()) return;
    Get.find<SubscriptionController>().applyCustomerInfo(info);
  }

  Future<void> applyCustomerInfo(CustomerInfo customerInfo) async {
    final entitlement = customerInfo.entitlements.all['pro'];
    final active = entitlement?.isActive ?? false;
    if (!active) {
      // Backend remains source of truth for access; RC only reports store period.
      return;
    }
    final trial = entitlement!.periodType == PeriodType.trial;
    if (trial) {
      await applyTrialStatus(trial: true);
      await updatePremiumStatus(false, isFromBackend: true);
    } else {
      await applyTrialStatus(trial: false);
      await updatePremiumStatus(true, isFromBackend: true);
    }
  }

  /// Tells RevenueCat which backend user this is.
  ///
  /// Without this RevenueCat creates an anonymous customer, so purchases and
  /// admin-granted entitlements never reach our user record and the webhook has
  /// no one to attach them to. Must be the UUID from the backend profile - not
  /// an email or a generated id.
  Future<void> identifyUser(String uuid) async {
    // Logged in full: identification failing silently is hard to tell apart
    // from the code path never running at all.
    print("🔑 [RC] identifyUser(uuid='$uuid') configured=$isConfigured");

    if (uuid.isEmpty) {
      print("⚠️ [RC] Empty uuid - skipping identify (check the backend field is 'uuid', not 'id')");
      return;
    }
    // Persist first and unconditionally: if RevenueCat has not finished
    // configuring yet, initData() re-identifies from this value on next launch.
    await setValue(AppSharedPreferenceKeys.userUuid, uuid);

    if (!isConfigured) {
      print("⚠️ [RC] Not configured yet - will re-identify on next launch");
      return;
    }
    try {
      final result = await Purchases.logIn(uuid);
      print("✅ [RC] logIn ok -> ${result.customerInfo.originalAppUserId} created=${result.created}");
    } catch (e, st) {
      print("❌ [RC] logIn FAILED for $uuid -> $e");
      print("$st");
    }
    try {
      print("🆔 [RC] appUserID now = ${await Purchases.appUserID}");
    } catch (e) {
      print("❌ [RC] appUserID read failed: $e");
    }
  }

  /// Detaches RevenueCat from this user on logout so the next account does not
  /// inherit the previous customer's entitlements.
  Future<void> resetUser() async {
    await removeKey(AppSharedPreferenceKeys.userUuid);
    if (!isConfigured) return;
    try {
      await Purchases.logOut();
      print("✅ [RC] Logged out");
    } catch (e) {
      print("❌ [RC] logOut failed: $e");
    }
  }

  /// True when the store products could not be loaded at all. The paywall shows
  /// a retry instead of spinning forever, which is what used to happen.
  RxBool offeringsLoadFailed = false.obs;

  /// Loads the plans shown on every paywall.
  ///
  /// Retries before giving up: this runs once at launch, and a single failed
  /// call used to leave the paywall on an endless spinner (and, on iOS, silently
  /// fall back to the full yearly price because the discount offering was missing).
  Future<void> fetchStoreProducts({int retries = 2}) async {
    if (!isConfigured) return;

    for (int attempt = 0; attempt <= retries; attempt++) {
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
        if (offerings.all["discount_offering"] != null) {
          final discountOffering = offerings.all["discount_offering"]!;
          spinYearlyPackage.value = discountOffering.annual;

          if (spinYearlyPackage.value != null) {
            print("🎁 [RC] SPIN OFFER LOADED FROM discount_offering: ${spinYearlyPackage.value?.storeProduct.priceString}");
          }
        } else {
          print("⚠️ [RC] 'discount_offering' NOT FOUND in RevenueCat Dashboard");
        }

        // Only a run that actually produced something counts as loaded.
        if (packages.isNotEmpty || spinYearlyPackage.value != null) {
          offeringsLoadFailed.value = false;
          return;
        }
        print("⚠️ [RC] Offerings came back empty (attempt ${attempt + 1})");
      } catch (e) {
        print("❌ [RC] Fetch attempt ${attempt + 1} failed: $e");
      }

      if (attempt < retries) {
        await Future.delayed(Duration(seconds: 1 << attempt)); // 1s, then 2s
      }
    }

    offeringsLoadFailed.value = true;
  }
  /// True when this user can still get the free trial / introductory price on
  /// the yearly plan. The store grants it once per account, so a returning
  /// subscriber must not be promised a trial the store will refuse.
  RxBool yearlyIntroEligible = true.obs;

  Package? get _yearlyPackage =>
      spinYearlyPackage.value ??
      packages.firstWhereOrNull((p) => p.packageType == PackageType.annual);

  Future<void> refreshTrialEligibility() async {
    if (!isConfigured) return;
    final productId = _yearlyPackage?.storeProduct.identifier;
    if (productId == null) return;

    try {
      final result =
          await Purchases.checkTrialOrIntroductoryPriceEligibility([productId]);
      final status = result[productId]?.status;
      // Only a definite "ineligible" hides the trial wording; unknown keeps the
      // current copy rather than downgrading it on a bad network.
      if (status == IntroEligibilityStatus.introEligibilityStatusIneligible ||
          status == IntroEligibilityStatus.introEligibilityStatusNoIntroOfferExists) {
        yearlyIntroEligible.value = false;
      } else if (status == IntroEligibilityStatus.introEligibilityStatusEligible) {
        yearlyIntroEligible.value = true;
      }
      print("🎟️ [RC] Intro eligibility for $productId: $status");
    } catch (e) {
      print("❌ [RC] Eligibility check failed: $e");
    }
  }

  /// The product the user is subscribed to right now, if any.
  Future<String?> _activeProductId() async {
    try {
      final info = await Purchases.getCustomerInfo();
      final entitlement = info.entitlements.all['pro'];
      if (entitlement?.isActive ?? false) return entitlement!.productIdentifier;
    } catch (e) {
      print("❌ [RC] Could not read active product: $e");
    }
    return null;
  }

  /// Google needs to be told how to handle a plan change, otherwise the result
  /// is whatever the billing library defaults to. Moving up to yearly takes
  /// effect now with credit for unused time; moving down to weekly waits for the
  /// current period to end so the user is not refunded mid-term.
  GoogleProrationMode _prorationModeFor(Package newPackage, String oldProductId) {
    final oldPackage = [...packages, if (spinYearlyPackage.value != null) spinYearlyPackage.value!]
        .firstWhereOrNull((p) => p.storeProduct.identifier == oldProductId);

    final oldIsAnnual = oldPackage?.packageType == PackageType.annual;
    final newIsAnnual = newPackage.packageType == PackageType.annual;

    if (newIsAnnual && !oldIsAnnual) return GoogleProrationMode.immediateWithTimeProration;
    if (!newIsAnnual && oldIsAnnual) return GoogleProrationMode.deferred;
    return GoogleProrationMode.immediateWithTimeProration;
  }

  /// The Play offer to buy the yearly plan with.
  ///
  /// Both offers live on the same base plan, so the discount is no longer a
  /// separate product: `spin` gives a year at the reduced price before the plan
  /// renews at full price, `trial` gives the free days and then full price.
  /// iOS has no equivalent - there the store applies the introductory offer.
  SubscriptionOption? androidYearlyOption({required bool discounted}) {
    if (!Platform.isAndroid) return null;

    final product = _yearlyPackage?.storeProduct;
    final options = product?.subscriptionOptions;
    if (options == null || options.isEmpty) return null;

    final wantedTag = discounted ? 'spin' : 'trial';
    return options.firstWhereOrNull((o) => !o.isBasePlan && o.tags.contains(wantedTag))
        // Tag missing in the console: fall back to shape - the discounted offer
        // is the one carrying an intro phase.
        ?? options.firstWhereOrNull((o) => !o.isBasePlan && (o.introPhase != null) == discounted)
        ?? product?.defaultOption;
  }

  /// What the user is actually charged for the first year on Android.
  ///
  /// The base plan price is the renewal price, so a discounted offer's real
  /// first-year amount comes from its intro phase, not from the product.
  String androidYearlyFirstYearPrice({required bool discounted}) {
    final option = androidYearlyOption(discounted: discounted);
    final intro = option?.introPhase;
    if (intro != null) return intro.price.formatted;
    return _yearlyPackage?.storeProduct.priceString ?? '';
  }

  /// The price the yearly plan renews at once any offer has run out.
  String androidYearlyRenewalPrice() =>
      _yearlyPackage?.storeProduct.priceString ?? '';

  /// Buys [package]. On Android pass [option] to pick a specific Play offer
  /// (the discounted year vs the plain free trial); without it the store
  /// decides, which is not what the spin result should get.
  Future<void> buyProduct(Package package, {SubscriptionOption? option}) async {
    if (!isConfigured) {
      toast("Store not available on this device");
      print("Store not available on this device");
      return;
    }
    try {
      isLoading.value = true;

      // Step 1: RevenueCat Purchase
      // Android needs the plan change spelled out. Without this a switch
      // between plans falls back to whatever the billing library defaults to.
      GoogleProductChangeInfo? changeInfo;
      if (Platform.isAndroid) {
        final oldProductId = await _activeProductId();
        if (oldProductId != null && oldProductId != package.storeProduct.identifier) {
          changeInfo = GoogleProductChangeInfo(
            oldProductId,
            prorationMode: _prorationModeFor(package, oldProductId),
          );
          print("🔁 [RC] Plan change $oldProductId -> ${package.storeProduct.identifier} (${changeInfo.prorationMode})");
        }
      }

      final purchaseResult = await Purchases.purchase(
        option != null && Platform.isAndroid
            ? PurchaseParams.subscriptionOption(
                option,
                googleProductChangeInfo: changeInfo,
              )
            : PurchaseParams.package(
                package,
                googleProductChangeInfo: changeInfo,
              ),
      );
      CustomerInfo customerInfo = purchaseResult.customerInfo;
      final entitlement = customerInfo.entitlements.all['pro'];

      if (entitlement?.isActive ?? false) {
        final storeTrial = entitlement!.periodType == PeriodType.trial;
        await verifyPurchaseWithBackend(
            package.storeProduct.identifier,
            customerInfo.originalAppUserId,
            spinInfo.value?.couponCode,
            periodType: storeTrial ? 'trial' : 'normal',
        );

        if (storeTrial) {
          await applyTrialStatus(trial: true);
          await updatePremiumStatus(false, isFromBackend: true);
          toast("3-day trial started. You are not Premium yet.");
        } else {
          await applyTrialStatus(trial: false);
          await updatePremiumStatus(true, isFromBackend: true);
          toast("Success! Premium Activated.");
        }
        if (Get.isRegistered<SleepSoundController>()) {
          final soundCtrl = Get.find<SleepSoundController>();
          soundCtrl.soundsBySubCategory.clear();
          soundCtrl.refreshCurrentTabSilently();
        }
        Get.until((route) => Get.isOverlaysClosed);
        Get.offAllNamed(Routes.dashboard);
      }
    } on PlatformException catch (e) {
      var errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        // User ne cancel kiya, koi galti nahi hai
      } else {
        if (errorCode == PurchasesErrorCode.productAlreadyPurchasedError) {
          // Already in the store trial for this plan, so it cannot be bought
          // again - the store rejects it. Say that plainly.
          toast("You are already subscribed to this plan. It starts automatically when your free trial ends.");
        } else {
          toast("Purchase Error: ${e.message}");
        }
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
      final entitlement = customerInfo.entitlements.all['pro'];
      final bool active = entitlement?.isActive ?? false;

      if (active) {
        final storeTrial = entitlement!.periodType == PeriodType.trial;
        if (storeTrial) {
          await applyTrialStatus(trial: true);
          await updatePremiumStatus(false, isFromBackend: true);
        } else {
          await applyTrialStatus(trial: false);
          isPremium.value = true;
        }
        await getBackendSubscriptionStatus();
        if (Get.isRegistered<SleepSoundController>()) {
          final soundCtrl = Get.find<SleepSoundController>();
          soundCtrl.soundsBySubCategory.clear();
          soundCtrl.refreshCurrentTabSilently();
        }
        toast(storeTrial
            ? "Trial restored. You are not Premium yet."
            : "Purchases restored. Premium is active.");
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

  /// Returns null when the spin succeeded, otherwise the reason to show the
  /// user. The backend sends a real explanation (e.g. "You have already used
  /// your spin.") which must not be reported as a connection error.
  Future<String?> performSpin() async {
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
        return null;
      }
      return response['message']?.toString();
    } catch (e) {
      print("❌ [Spin] Error: $e");
      // buildHttpResponse throws the backend's own message for a 4xx, so pass
      // that through rather than calling every failure a connection error.
      final reason = e.toString().replaceFirst('Exception:', '').trim();
      return reason.isEmpty ? null : reason;
    } finally {
      isLoading.value = false;
      update();
    }
  }

  // 5. Backend Verification API
  Future<void> verifyPurchaseWithBackend(String productId, String token, String? coupon, {String periodType = 'normal'}) async {
    try {
      final payload = {
        "product_id": productId,
        "app_user_id": token,
        "purchase_token": token,
        "coupon_code": coupon ?? "",
        "period_type": periodType,
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
  /// The single source of truth for premium access.
  ///
  /// Retries before giving up: a failed call must not lock a paying or
  /// admin-granted user out, so on total failure the cached value is kept.
  /// Stores the trial end sent by the backend. Accepts both plain and
  /// microsecond ISO timestamps; anything unparseable is treated as "no trial"
  /// rather than crashing the status sync.
  void _applyTrialEnd(dynamic raw) {
    final text = (raw ?? '').toString();
    if (text.isEmpty || text == 'null') {
      trialEndsAt.value = null;
      removeKey(TRIAL_ENDS_KEY);
      return;
    }
    final parsed = DateTime.tryParse(text);
    if (parsed == null) {
      log("Could not parse trial_ends_at: $text");
      return;
    }
    trialEndsAt.value = parsed.toUtc();
    setValue(TRIAL_ENDS_KEY, text);
  }

  void _restoreTrialEndFromCache() {
    final cached = getStringAsync(TRIAL_ENDS_KEY);
    if (cached.isEmpty) return;
    trialEndsAt.value = DateTime.tryParse(cached)?.toUtc();
  }

  /// Whole days left before the trial converts. Null when no trial is running.
  int? get trialDaysRemaining {
    final end = trialEndsAt.value;
    if (end == null) return null;
    final left = end.difference(DateTime.now().toUtc());
    return left.isNegative ? 0 : left.inDays;
  }

  Future<void> getBackendSubscriptionStatus({int retries = 2}) async {
    for (int attempt = 0; attempt <= retries; attempt++) {
      try {
        final response = await buildHttpResponse(
            endPoint: APIEndPoints.subscriptionStatus,
            method: MethodType.get
        );
        if (response['success']) {
          final data = response['data'] ?? {};
          bool backendStatus = data['is_premium'] ?? false;
          bool trialStatus = data['is_trial'] ?? false;
          await applyTrialStatus(trial: trialStatus && !backendStatus);
          await updatePremiumStatus(backendStatus, isFromBackend: true);
          final first = (data['first_report_date'] ?? '').toString();
          firstReportDate.value = first;
          await setValue(FIRST_REPORT_KEY, first);
          trialNightsUsed.value = data['trial_nights_used'] ?? 0;
          _applyTrialEnd(data['trial_ends_at']);
          return;
        }
      } catch (e) {
        log("Backend subscription check attempt ${attempt + 1} failed: $e");
      }
      if (attempt < retries) {
        await Future.delayed(Duration(seconds: 1 << attempt)); // 1s, then 2s
      }
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
      final trial = customerInfo.entitlements.all['pro']?.periodType == PeriodType.trial;
      if (isActive && trial) {
        await applyTrialStatus(trial: true);
        await updatePremiumStatus(false, isFromBackend: true);
      } else if (isActive) {
        await applyTrialStatus(trial: false);
        updatePremiumStatus(true, isFromBackend: false);
      }
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
