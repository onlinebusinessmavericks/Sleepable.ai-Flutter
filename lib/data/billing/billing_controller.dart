// import 'dart:async';
// import 'package:in_app_purchase/in_app_purchase.dart';
//
// class BillingController {
//   final InAppPurchase _iap = InAppPurchase.instance;
//   late StreamSubscription<List<PurchaseDetails>> _subscription;
//
//   Future<void> init() async {
//     final available = await _iap.isAvailable();
//     if (!available) {
//       throw Exception("Google Play Billing not available");
//     }
//
//     _subscription = _iap.purchaseStream.listen(_listenToPurchases);
//   }
//
//   Future<List<ProductDetails>> loadProducts() async {
//     final response = await _iap.queryProductDetails({
//       'premium_monthly',
//       'premium_yearly',
//       'remove_ads',
//     });
//
//     return response.productDetails;
//   }
//
//   void buy(ProductDetails product) {
//     final purchaseParam = PurchaseParam(productDetails: product);
//     _iap.buyNonConsumable(purchaseParam: purchaseParam);
//   }
//
//   void _listenToPurchases(List<PurchaseDetails> purchases) {
//     for (var purchase in purchases) {
//       if (purchase.status == PurchaseStatus.purchased) {
//         _verifyAndComplete(purchase);
//       }
//     }
//   }
//
//   Future<void> _verifyAndComplete(PurchaseDetails purchase) async {
//     // TODO: Server-side verification (recommended)
//     if (purchase.pendingCompletePurchase) {
//       await _iap.completePurchase(purchase);
//     }
//   }
//
//   void dispose() {
//     _subscription.cancel();
//   }
// }
