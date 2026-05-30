

class SpinData {
  bool alreadySpun;
  final String? couponCode;
  final int? discountPct;
  final String? originalPrice;
  final String? discountedPrice;
  final String? message;

  SpinData({
    required this.alreadySpun,
    this.couponCode,
    this.discountPct,
    this.originalPrice,
    this.discountedPrice,
    this.message,
  });

  factory SpinData.fromJson(Map<String, dynamic> json) {
    return SpinData(
      alreadySpun: json['already_spun'] ?? (json['discount_pct'] != null),
      couponCode: json['coupon_code'],
      discountPct: json['discount_pct'],
      originalPrice: json['original_price'],
      discountedPrice: json['discounted_price'],
      message: json['message']?.toString(),
    );
  }
}