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
import '../modules/subscription/model/access_state.dart';
import '../modules/subscription/model/spin_data.dart';
import '../localization/lang_extension.dart';

class SubscriptionController extends GetxController with WidgetsBindingObserver {
  RxList<Package> packages = <Package>[].obs;
  Rx<Package?> spinPackage = Rx<Package?>(null);
  Rx<Package?> spinYearlyPackage = Rx<Package?>(null);
  Rx<Package?> spinWeeklyPackage = Rx<Package?>(null);
  /// What this user may do, as the backend last reported it. The single
  /// source for every lock and every paywall decision.
  final Rx<AccessState> access = AccessState.unknown().obs;
  static const String ACCESS_CACHE_KEY = "access_state_cache";
  DateTime? _lastAccessRefresh;

  // Mirrors of [access], kept so existing Obx/ever listeners keep working.
  // Written only by [_setAccess]; never set them anywhere else.
  RxBool isPremium = false.obs;
  RxBool isTrial = false.obs;
  RxString firstReportDate = ''.obs;
  RxInt trialNightsUsed = 0.obs;
  /// Plan description from the backend, used when the store has no record of
  /// the purchase - Premium granted by support, for instance.
  RxString backendPlanName = ''.obs;
  RxString backendPlanPrice = ''.obs;
  RxString backendStartsAt = ''.obs;
  RxString backendExpiresAt = ''.obs;

  /// Exactly when the store will charge for the trial, straight from the store
  /// via the backend - not a date counted locally. Null unless a trial is running.
  Rx<DateTime?> trialEndsAt = Rx<DateTime?>(null);
  RxBool isLoading = false.obs;
  bool _restoreInFlight = false;
  static const String SPIN_CACHE_KEY = "spin_status_cache";
  Rx<SpinData?> spinInfo = Rx<SpinData?>(null);
  // RxBool isReady = false.obs;
  RxBool isInitialSyncDone = false.obs;
  static bool isConfigured = false;



  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    // Start from the last access block the backend sent, so a paying user is
    // not shown the locked state for the second or two the network sync takes.
    _restoreAccessFromCache();

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
      final uuid = _signedInUuid();
      if (uuid.isNotEmpty) {
        await identifyUser(uuid);
      } else {
        print("⚠️ [RC] No stored uuid and no cached profile - user stays anonymous");
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
      // RevenueCat has no record of those - asking it would lock them out even
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

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    // Trial ends, purchases on another device and admin grants all happen
    // while the app is in the background.
    final last = _lastAccessRefresh;
    if (last != null && DateTime.now().difference(last) < const Duration(minutes: 1)) return;
    if (getStringAsync(AppSharedPreferenceKeys.apiToken).isEmpty) return;
    _lastAccessRefresh = DateTime.now();
    getBackendSubscriptionStatus(retries: 0);
  }

  /// Takes an access block from any backend response that carries one: the
  /// login body, GET /users/subscription/, `data.access` on the home page, or
  /// the restore / verify response. Returns false and changes nothing when
  /// [json] is not an access block, so a partial response never resets the
  /// user to "free".
  Future<bool> applyAccess(dynamic json) async {
    final parsed = AccessState.tryParse(json);
    if (parsed == null) return false;
    _setAccess(parsed);
    await setValue(ACCESS_CACHE_KEY, jsonEncode(parsed.raw));
    return true;
  }

  void _setAccess(AccessState state) {
    access.value = state;
    isPremium.value = state.isPremium;
    isTrial.value = state.isTrial;
    firstReportDate.value = state.firstReportDate ?? '';
    trialNightsUsed.value = state.trialNightsUsed;
    trialEndsAt.value = state.trialEndsAt;
  }

  void _restoreAccessFromCache() {
    final cached = getStringAsync(ACCESS_CACHE_KEY);
    if (cached.isEmpty) return;
    try {
      final parsed = AccessState.tryParse(jsonDecode(cached));
      if (parsed != null) _setAccess(parsed);
    } catch (e) {
      log("Could not read cached access state: $e");
    }
  }

  /// Whether a paywall may be shown - the backend's `features.show_paywall`.
  bool get showPaywalls => access.value.showPaywall;
  /// Running 3-day store trial that has not converted to Premium yet.
  bool get isOnFreeTrial => isTrial.value && !isPremium.value;

  /// A track's padlock. The backend sends `is_premium` per user - it already
  /// means "locked for this user" - so it is used as it is.
  bool isPremiumItemLocked({required bool itemIsPremium}) => itemIsPremium;

  /// True once the user has actually won the spin discount.
  ///
  /// This used to also accept `discount_pct > 0`, but the backend now sends
  /// that field before any spin - it is the amount the wheel WILL award, not
  /// something the user holds. Reading it as a win put "LUCKY SPIN OFFER
  /// APPLIED" and the discounted price in front of brand new users.
  bool get hasSpecialOffer => spinInfo.value?.alreadySpun == true;

  /// iOS: no spin and no discount paywall. Weekly + yearly come from the
  /// App Store current offering only.
  bool shouldShowDiscountOnPaywall() {
    if (Platform.isIOS) return false;
    return spinInfo.value?.alreadySpun == true;
  }

  int get paywallDiscountPercent => spinInfo.value?.discountPct ?? 50;

  /// Store / backend prices often arrive as "₹ 1,990.00" or "$ 39.99".
  /// Every on-screen amount should be sign immediately against the number.
  static String compactPriceString(String? price) {
    if (price == null || price.isEmpty) return '';
    var s = price
        .replaceAll('\u00A0', ' ')
        .replaceAll('\u202F', ' ')
        .replaceAll('\u2007', ' ')
        .trim();
    s = s.replaceFirstMapped(RegExp(r'^(\D+?)\s+(\d)'), (m) => '${m[1]}${m[2]}');
    // Suffix currencies only ("9,99 €") — do not eat " / year" or similar copy.
    s = s.replaceFirstMapped(RegExp(r'(\d)\s+([^\d\s/]+)$'), (m) => '${m[1]}${m[2]}');
    return s;
  }

  /// iOS paywall price line.
  ///
  /// The App Store applies an introductory offer on its own, so the first year
  /// and the renewal are different amounts. The line has to say "for the first
  /// year" rather than "/ year" whenever that is the case.
  String formatIosYearlyPriceLine({
    required String prefix,
    required String yearlyPrice,
    required String currencySymbol,
    required String weeklyAvg,
  }) {
    final period = yearlyHasFirstYearDiscount ? 'for the first year' : '/ year';
    return '$prefix ${compactPriceString(yearlyPrice)} $period ($currencySymbol$weeklyAvg / week)';
  }

  /// iOS paywall footer: what happens once the first year is up.
  ///
  /// iOS has no free trial, so this must never promise one - it used to open
  /// with "3 days free", which was true only on Android.
  String formatIosTrialSubtext({
    required String yearlyPrice,
    required String currencySymbol,
    required String weeklyAvg,
  }) {
    if (!yearlyHasFirstYearDiscount) {
      return '${compactPriceString(yearlyPrice)} / year. Cancel anytime.';
    }
    final renewal = compactPriceString(_yearlyPackage?.storeProduct.priceString);
    return '${compactPriceString(yearlyPrice)} for the first year, then $renewal / year. Cancel anytime.';
  }

  /// Yearly price to show, taken from what the first year actually costs.
  ///
  /// These used to read `storeProduct.priceString`, which is the renewal price.
  /// On Android the discounted offering used to show the same number as full
  /// price. The package arguments are kept so call sites do not have to change;
  /// only the source of the number moved.
  String getDisplayYearlyPrice({
    required SpinData? spinData,
    required Package? discountPackage,
    required Package? standardPackage,
    required bool showOffer,
  }) {
    final price = yearlyFirstYearPrice(discounted: showOffer);
    if (price.isNotEmpty) return price;
    // Last resort only if offerings failed to load
    return compactPriceString(spinData?.discountedPrice);
  }

  double getDisplayYearlyRawPrice({
    required SpinData? spinData,
    required Package? discountPackage,
    required Package? standardPackage,
    required bool showOffer,
  }) {
    final amount = yearlyFirstYearAmount(discounted: showOffer);
    if (amount > 0) return amount;
    // Last resort only if offerings failed to load
    final raw = spinData?.discountedPrice;
    if (raw != null) {
      final parsed = double.tryParse(raw.replaceAll(',', '').replaceAll(RegExp(r'[^0-9.]'), ''));
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

  /// The store's view changed (renewal, cancellation, a purchase finishing).
  /// Access is still the backend's call, so ask it again rather than reading
  /// the receipt.
  Future<void> applyCustomerInfo(CustomerInfo customerInfo) async {
    if (getStringAsync(AppSharedPreferenceKeys.apiToken).isEmpty) return;
    await getBackendSubscriptionStatus();
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

  /// The backend uuid of the signed-in user, or '' when nobody is signed in.
  ///
  /// Users who logged in before the uuid was persisted only have it inside the
  /// cached profile, so fall back to that.
  String _signedInUuid() {
    final stored = getStringAsync(AppSharedPreferenceKeys.userUuid);
    if (stored.isNotEmpty) return stored;
    final cachedProfile = getStringAsync(AppSharedPreferenceKeys.currentUserData);
    if (cachedProfile.isEmpty) return '';
    try {
      return (jsonDecode(cachedProfile)['uuid'] ?? '').toString();
    } catch (e) {
      log("Could not read uuid from cached profile: $e");
      return '';
    }
  }

  /// Play offer id of the spin discount. The coupon only belongs to a purchase
  /// made through this offer.
  static const String _spinOfferId = 'yearly-spin-offer';

  /// Confirms RevenueCat is attached to the signed-in user before a purchase or
  /// restore, and returns that app user id.
  ///
  /// A receipt bought on an anonymous customer lands where the backend webhook
  /// can never match it, so this retries logIn once and returns null if the id
  /// still is not the user's uuid. Callers must not open checkout on null.
  Future<String?> _ensureIdentity() async {
    if (!isConfigured) return null;
    final uuid = _signedInUuid();
    if (uuid.isEmpty) return null;

    for (int attempt = 0; attempt < 2; attempt++) {
      try {
        if (await Purchases.appUserID == uuid) return uuid;
        await Purchases.logIn(uuid);
        if (await Purchases.appUserID == uuid) {
          await setValue(AppSharedPreferenceKeys.userUuid, uuid);
          return uuid;
        }
      } catch (e) {
        log("RevenueCat identity attempt ${attempt + 1} failed: $e");
      }
    }
    return null;
  }

  /// Clears cached entitlements and detaches RevenueCat so the next account
  /// does not inherit this customer's premium / trial state.
  Future<void> clearSessionState() async {
    _setAccess(AccessState.unknown());
    _lastAccessRefresh = null;
    await removeKey(ACCESS_CACHE_KEY);
    spinInfo.value = null;
    backendPlanName.value = '';
    backendPlanPrice.value = '';
    backendStartsAt.value = '';
    backendExpiresAt.value = '';
    isInitialSyncDone.value = true;
    await resetUser();
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

        // Current offering: weekly + yearly at the store's localized price.
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

        // Android Lucky Spin discount offering. iOS has no discount plan.
        if (Platform.isIOS) {
          spinYearlyPackage.value = null;
        } else if (offerings.all["discount_offering"] != null) {
          final discountOffering = offerings.all["discount_offering"]!;
          spinYearlyPackage.value = discountOffering.annual;

          if (spinYearlyPackage.value != null) {
            print("🎁 [RC] discount_offering annual = ${spinYearlyPackage.value?.storeProduct.identifier} @ ${spinYearlyPackage.value?.storeProduct.priceString}");
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

  Package? get _yearlyPackage {
    if (Platform.isIOS) {
      return packages.firstWhereOrNull((p) => p.packageType == PackageType.annual);
    }
    return spinYearlyPackage.value ??
        packages.firstWhereOrNull((p) => p.packageType == PackageType.annual);
  }

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

  /// Full store id of a purchase: `product:basePlan` on Google Play, the plain
  /// product id on the App Store.
  ///
  /// On Android the entitlement keeps the base plan in a separate field, so
  /// `productIdentifier` alone ("sleepable_yearly") never equals the id of the
  /// package being bought ("sleepable_yearly:yearly-base").
  static String _storeIdOf(EntitlementInfo entitlement) {
    final product = entitlement.productIdentifier;
    final plan = entitlement.productPlanIdentifier;
    if (plan == null || plan.isEmpty || product.contains(':')) return product;
    return '$product:$plan';
  }

  /// The subscription a store id belongs to, without its base plan.
  static String _subscriptionIdOf(String storeId) => storeId.split(':').first;

  /// Full store id of the subscription the user holds right now, if any.
  Future<String?> _activeStoreProductId() async {
    try {
      final info = await Purchases.getCustomerInfo();
      final entitlement = info.entitlements.all['pro'];
      if (entitlement?.isActive ?? false) return _storeIdOf(entitlement!);
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

  /// Play formats a subscription option id as "<basePlanId>:<offerId>" for an
  /// offer, and as just "<basePlanId>" for the base plan. The backend matches
  /// on the bare offer id, so hand it that. Null on iOS and on a base-plan
  /// purchase, where there is no offer to report.
  String? _playOfferId(SubscriptionOption? option) {
    if (option == null || option.isBasePlan) return null;
    final id = option.id;
    final sep = id.lastIndexOf(':');
    return sep >= 0 ? id.substring(sep + 1) : id;
  }

  /// What the user is actually charged for the first year on Android.
  ///
  /// The base plan price is the renewal price, so a discounted offer's real
  /// first-year amount comes from its intro phase, not from the product.
  String androidYearlyFirstYearPrice({required bool discounted}) {
    final option = androidYearlyOption(discounted: discounted);
    final intro = option?.introPhase;
    if (intro != null) return compactPriceString(intro.price.formatted);
    return compactPriceString(_yearlyPackage?.storeProduct.priceString);
  }

  /// The price the yearly plan renews at once any offer has run out.
  String androidYearlyRenewalPrice() =>
      compactPriceString(_yearlyPackage?.storeProduct.priceString);

  /// What the first year actually costs, as a number, on either platform.
  ///
  /// The store product carries the *renewal* price - on Play the discount lives
  /// in the offer's intro phase, on the App Store in the introductory offer.
  /// Every "per week" and "per day" figure has to come from here, otherwise the
  /// page shows a discounted yearly price next to a full-price weekly average,
  /// which is what the paywalls were doing.
  double yearlyFirstYearAmount({required bool discounted}) {
    if (Platform.isAndroid) {
      final intro = androidYearlyOption(discounted: discounted)?.introPhase;
      if (intro != null) return intro.price.amountMicros / 1000000.0;
      return _yearlyPackage?.storeProduct.price ?? 0;
    }
    // iOS: the App Store applies the introductory offer by itself to everyone
    // who qualifies, so the first year costs the intro price when one exists.
    final product = _yearlyPackage?.storeProduct;
    return product?.introductoryPrice?.price ?? product?.price ?? 0;
  }

  /// What the plan costs every year after the first one.
  double yearlyRenewalAmount() => _yearlyPackage?.storeProduct.price ?? 0;

  /// Whether the yearly plan's first year is cheaper than its renewal.
  bool get yearlyHasFirstYearDiscount =>
      yearlyRenewalAmount() > yearlyFirstYearAmount(discounted: hasSpecialOffer);

  /// Formatted first-year price for either platform.
  String yearlyFirstYearPrice({required bool discounted}) {
    if (Platform.isAndroid) return androidYearlyFirstYearPrice(discounted: discounted);
    final product = _yearlyPackage?.storeProduct;
    return compactPriceString(product?.introductoryPrice?.priceString ?? product?.priceString);
  }

  /// The crossed-out price, or null when there is nothing to cross out.
  ///
  /// A strike-through that reads the same as the price beside it is worse than
  /// none at all - it claims a saving that does not exist.
  String? yearlyStrikePrice({required bool discounted}) {
    final renewal = yearlyRenewalAmount();
    final first = yearlyFirstYearAmount(discounted: discounted);
    if (renewal <= first) return null;
    return compactPriceString(_yearlyPackage?.storeProduct.priceString);
  }

  /// The Play offer a purchase should go through when the caller did not name
  /// one.
  ///
  /// Only the yearly plan carries offers: `spin` for the discounted year and
  /// `trial` for the plain three days. Which one applies is decided by whether
  /// the user has actually won the spin, the same test the paywall uses to
  /// decide what price to print - so the sheet and the store agree.
  SubscriptionOption? _defaultOptionFor(Package package) {
    if (!Platform.isAndroid) return null;
    if (package.packageType != PackageType.annual) return null;
    return androidYearlyOption(discounted: hasSpecialOffer);
  }

  /// Buys [package]. On Android pass [option] to pick a specific Play offer
  /// (the discounted year vs the plain free trial); without it one is worked
  /// out from whether the user has won the spin.
  Future<void> buyProduct(Package package, {SubscriptionOption? option}) async {
    if (!isConfigured) {
      toast("Store not available on this device");
      print("Store not available on this device");
      return;
    }
    // Checkout only opens where a paywall may: never for trial or paid users,
    // and not before the backend has said so. For the plan someone already
    // holds, Play would reject the request outright.
    if (!access.value.showPaywall) {
      if (access.value.hasAccess) {
        toast(Get.context?.lang.purchaseAlreadyHasAccess ??
            "You already have access to Sleepable. You can manage your plan in My Subscription.");
      }
      return;
    }
    try {
      isLoading.value = true;

      // Checkout only opens once RevenueCat is attached to this account.
      final appUserId = await _ensureIdentity();
      if (appUserId == null) {
        toast(Get.context?.lang.purchaseIdentityError ??
            "We couldn't confirm your account with the store. Please check your connection and try again.");
        return;
      }

      // Step 1: RevenueCat Purchase
      // Android needs the plan change spelled out. Without this a switch
      // between plans falls back to whatever the billing library defaults to.
      GoogleProductChangeInfo? changeInfo;
      if (Platform.isAndroid) {
        final activeStoreId = await _activeStoreProductId();
        final targetStoreId = package.storeProduct.identifier;
        // A change request that names the user's own current subscription is
        // what Play answers with "One or more of the arguments provided are
        // invalid". Only a genuinely different subscription gets one.
        if (activeStoreId != null &&
            _subscriptionIdOf(activeStoreId) != _subscriptionIdOf(targetStoreId)) {
          changeInfo = GoogleProductChangeInfo(
            _subscriptionIdOf(activeStoreId),
            prorationMode: _prorationModeFor(package, activeStoreId),
          );
          print("🔁 [RC] Plan change $activeStoreId -> $targetStoreId (${changeInfo.prorationMode})");
        }
      }

      // The discount lives in the Play offer, not in the product. Five of the
      // six purchase buttons never passed one, so the store fell back to its
      // default offer and sold the full-price trial even to someone who had
      // just won the spin. Work it out here so no call site can forget again.
      option ??= _defaultOptionFor(package);

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
        final offerId = _playOfferId(option);
        final verified = await verifyPurchaseWithBackend(
          productId: package.storeProduct.identifier,
          appUserId: appUserId,
          periodType: entitlement!.periodType.name,
          offerId: offerId,
          couponCode: offerId == _spinOfferId ? spinInfo.value?.couponCode : null,
        );
        if (!verified) log("verify-purchase did not succeed; relying on the status refresh");

        // Refresh either way: the RevenueCat webhook may already have credited
        // the purchase even when our own verify call failed. Access is whatever
        // the backend says, never what the store receipt implies.
        await getBackendSubscriptionStatus();
        if (!access.value.hasAccess) {
          toast(Get.context?.lang.purchaseActivationError ??
              "Your purchase went through, but we couldn't activate it yet. Please tap Restore Purchases in a moment.");
          return;
        }

        if (isPremium.value) {
          toast("Success! Premium Activated.");
        } else {
          toast("3-day trial started. You are not Premium yet.");
        }
        await _reloadAfterAccessChange();
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
  /// Purchases" button in Settings, My Subscription, and the iOS paywall.
  ///
  /// Store restore alone is not enough: Premium is granted by our backend. After
  /// RevenueCat re-links the receipt we POST /users/restore-purchase/ so the
  /// subscription row and is_premium flag are rebuilt for this account.
  Future<void> restorePurchases() async {
    if (_restoreInFlight) return;
    final loggedIn = getStringAsync(AppSharedPreferenceKeys.apiToken).isNotEmpty;
    if (!isConfigured && !loggedIn) {
      toast("Store not available on this device");
      return;
    }

    _restoreInFlight = true;
    isLoading.value = true;
    try {
      String appUserId = '';
      String productId = '';
      String periodType = '';

      if (isConfigured) {
        // Restoring onto an anonymous customer would re-link the receipt to
        // the wrong place, so identity has to be settled first.
        final confirmedId = await _ensureIdentity();
        if (confirmedId == null) {
          toast(Get.context?.lang.purchaseIdentityError ??
              "We couldn't confirm your account with the store. Please check your connection and try again.");
          return;
        }
        appUserId = confirmedId;
        try {
          await Purchases.invalidateCustomerInfoCache();
          final CustomerInfo customerInfo = await Purchases.restorePurchases();
          final entitlement = customerInfo.entitlements.all['pro'];
          if (entitlement?.isActive ?? false) {
            productId = _storeIdOf(entitlement!);
            periodType = entitlement.periodType.name;
          }
        } on PlatformException catch (e) {
          log("Store restore failed: ${e.message}");
          if (!loggedIn) {
            toast("Restore failed: ${e.message}");
            return;
          }
        }
      }

      if (!loggedIn) {
        toast("Restore failed. Please try again.");
        return;
      }

      final payload = <String, dynamic>{
        if (appUserId.isNotEmpty) "app_user_id": appUserId,
        if (productId.isNotEmpty) "product_id": productId,
        if (periodType.isNotEmpty) "period_type": periodType,
      };

      Map? response;
      Object? lastError;
      for (int attempt = 0; attempt <= 2; attempt++) {
        try {
          response = await buildHttpResponse(
            endPoint: APIEndPoints.restorePurchase,
            method: MethodType.post,
            request: payload,
          );
          lastError = null;
          break;
        } catch (e) {
          lastError = e;
          log("Restore API attempt ${attempt + 1} failed: $e");
          if (attempt < 2) {
            await Future.delayed(Duration(seconds: 1 << attempt));
          }
        }
      }

      if (response == null || response['success'] != true) {
        final reason = lastError?.toString().replaceFirst('Exception:', '').trim() ?? '';
        toast(reason.isNotEmpty
            ? "Restore failed: $reason"
            : "Restore failed. Please try again.");
        return;
      }

      final data = (response['data'] is Map)
          ? Map<String, dynamic>.from(response['data'] as Map)
          : <String, dynamic>{};
      await _applySubscriptionPayload(data);
      await getBackendSubscriptionStatus();
      await refreshEntitlementDetails();
      await _reloadAfterAccessChange();

      final restored = response['restored'] == true;
      if (restored) {
        toast(isOnFreeTrial
            ? "Trial restored. You are not Premium yet."
            : "Purchases restored. Premium is active.");
        Get.until((route) => Get.isOverlaysClosed);
        Get.offAllNamed(Routes.dashboard);
      } else {
        toast("No active subscription found to restore.");
      }
    } catch (e) {
      toast("Restore failed. Please try again.");
    } finally {
      isLoading.value = false;
      _restoreInFlight = false;
    }
  }

  /// Paid Premium: drop cached Music/Story locks and refetch so padlocks go without a reboot.
  /// Trial must not call this — those lists stay the free catalog.
  /// Track padlocks come from the backend per user, so after a purchase or
  /// restore every list that carries them is fetched again: the Sounds tab
  /// lists, favorites, mixes, and the home payload.
  Future<void> _reloadAfterAccessChange() async {
    if (Get.isRegistered<SleepSoundController>()) {
      await Get.find<SleepSoundController>().refreshCatalogAfterAccessChange();
    }
    if (Get.isRegistered<HomeController>()) {
      await Get.find<HomeController>().fetchHomePageData();
    }
  }

  /// The store's own record of the active subscription: which product, when it
  /// was bought, when it renews, whether it has been cancelled. Null when the
  /// user has no store purchase - a free user, or one granted premium by an
  /// admin, where the backend is the only source of truth.
  Rx<EntitlementInfo?> activeEntitlement = Rx<EntitlementInfo?>(null);

  Future<void> refreshEntitlementDetails() async {
    if (!isConfigured) return;
    try {
      final info = await Purchases.getCustomerInfo();
      activeEntitlement.value = info.entitlements.all['pro'];
    } catch (e) {
      print("[RC] Could not read entitlement details: $e");
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

      // Branch on the structured flag, never on the message text. The backend
      // translates its messages, so matching the English word "already" failed
      // silently on every non-English device and the win was thrown away.
      final body = response['data'];
      final alreadySpun = body is Map && body['already_spun'] == true;

      if ((response['success'] == true || alreadySpun) && body is Map) {
        final data = SpinData.fromJson(Map<String, dynamic>.from(body));

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

  /// Records a store purchase on the backend. Returns true when it was accepted.
  ///
  /// Retries, because this is what creates the subscription row: a single
  /// failed call used to be swallowed and left a paying user with no record.
  /// The caller refreshes the subscription status either way.
  Future<bool> verifyPurchaseWithBackend({
    required String productId,
    required String appUserId,
    required String periodType,
    String? offerId,
    String? couponCode,
    int retries = 2,
  }) async {
    final payload = <String, dynamic>{
      "product_id": productId,
      "app_user_id": appUserId,
      "period_type": periodType,
      // Play offer the purchase actually went through, so the backend can
      // tell a spin discount apart from a plain trial. Empty on iOS, where
      // the store applies the introductory offer without an offer id.
      "offer_id": offerId ?? "",
      if (couponCode != null && couponCode.isNotEmpty) "coupon_code": couponCode,
    };

    for (int attempt = 0; attempt <= retries; attempt++) {
      try {
        final response = await buildHttpResponse(
          endPoint: APIEndPoints.verifyPurchase,
          method: MethodType.post,
          request: payload,
        );
        if (response is Map && response['success'] == true) {
          await applyAccess(response['data']);
          return true;
        }
        log("verify-purchase rejected: ${response is Map ? response['message'] : response}");
      } catch (e) {
        log("verify-purchase attempt ${attempt + 1} failed: $e");
      }
      if (attempt < retries) {
        await Future.delayed(Duration(seconds: 1 << attempt)); // 1s, then 2s
      }
    }
    return false;
  }

  // 6. Get Status from Backend
  /// The single source of truth for premium access.
  ///
  /// Retries before giving up: a failed call must not lock a paying or
  /// admin-granted user out, so on total failure the cached value is kept.
  Future<void> _applySubscriptionPayload(dynamic raw) async {
    final data = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
    await applyAccess(data);
    // The backend describes the plan too. It is the only source for a
    // user whose Premium was granted outside the store, where there is
    // no purchase for RevenueCat to report.
    if (data.containsKey('plan_name')) {
      backendPlanName.value = (data['plan_name'] ?? '').toString();
    }
    if (data.containsKey('price')) {
      backendPlanPrice.value = compactPriceString((data['price'] ?? '').toString());
    }
    if (data.containsKey('starts_at')) {
      backendStartsAt.value = (data['starts_at'] ?? '').toString();
    }
    if (data.containsKey('expires_at')) {
      backendExpiresAt.value = (data['expires_at'] ?? '').toString();
    }
  }

  /// Whole days left before the trial converts. Null when no trial is running.
  int? get trialDaysRemaining {
    final end = trialEndsAt.value;
    if (end == null) return null;
    final left = end.difference(DateTime.now().toUtc());
    return left.isNegative ? 0 : left.inDays;
  }

  /// Refreshes [access] from GET /users/subscription/. On failure the current
  /// state is kept as it is - a network error must never turn a paying or
  /// trial user into a free one. Returns whether the refresh succeeded.
  Future<bool> getBackendSubscriptionStatus({int retries = 2}) async {
    for (int attempt = 0; attempt <= retries; attempt++) {
      try {
        final response = await buildHttpResponse(
            endPoint: APIEndPoints.subscriptionStatus,
            method: MethodType.get
        );
        if (response['success'] == true) {
          await _applySubscriptionPayload(response['data'] ?? {});
          _lastAccessRefresh = DateTime.now();
          return true;
        }
      } catch (e) {
        log("Backend subscription check attempt ${attempt + 1} failed: $e");
      }
      if (attempt < retries) {
        await Future.delayed(Duration(seconds: 1 << attempt)); // 1s, then 2s
      }
    }
    return false;
  }

  /// Opens the exit offer after a paywall is dismissed.
  ///
  /// [context] is deliberately ignored. Every caller pops its own sheet on the
  /// line above this call, so by the time we get here that element is already
  /// deactivated - and pushing a bottom sheet against a dead context does
  /// nothing at all, which is why Lucky Spin never appeared when the yearly
  /// paywall was closed. Go through the navigator's own context instead, once
  /// the pop has been through a frame.
  void checkAndShowPremiumSheet(BuildContext context) {
    if (!access.value.showPaywall || Platform.isIOS) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = Get.context;
      if (ctx == null) return;

      final spinData = spinInfo.value;
      if (spinData != null && spinData.alreadySpun) {
        showPremiumOfferSheet6(ctx);
      } else {
        showPremiumOfferSheet5(ctx);
      }
    });
  }
  String getCurrencySymbol(String currencyCode) {
    if (currencyCode == "INR" || currencyCode.toUpperCase() == "INR") {
      return "₹";
    }

    try {
      var format = NumberFormat.simpleCurrency(name: currencyCode);
      return format.currencySymbol.trim();
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

  /// Set once a review has been asked for in this session.
  ///
  /// The prompt used to have no throttle beyond "has the user already rated",
  /// and it was fired from every paywall dismissal, so it reappeared again and
  /// again - at one point on top of the spin wheel.
  static bool _ratingAskedThisSession = false;

  void checkAndShowRatingAfterPostDelay() {
    if (Platform.isIOS) return;
    if (_ratingAskedThisSession) return;
    if (getBoolAsync("user_has_rated", defaultValue: false)) return;

    // Ask only once the user has actually spent some time in the app.
    if (getIntAsync("app_open_count", defaultValue: 0) < 3) return;

    // And leave them alone for a week after they say no.
    final declined = getStringAsync("rating_declined_at");
    if (declined.isNotEmpty) {
      final when = DateTime.tryParse(declined);
      if (when != null && DateTime.now().difference(when).inDays < 7) return;
    }

    _ratingAskedThisSession = true;

    Future.delayed(const Duration(milliseconds: 1500), () {
      // Never stack it on whatever the user is already dealing with.
      if (Get.context == null) return;
      if (Get.isDialogOpen == true || Get.isBottomSheetOpen == true) return;
      // Dismissible: forcing a choice on a review prompt is the kind of thing
      // both stores take a dim view of.
      Get.dialog(const RatingDialog(), barrierDismissible: true);
    });
  }
}
