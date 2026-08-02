

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

  /// Cached on device so a failed status call cannot drop a user who already
  /// won a discount back to the full price.
  Map<String, dynamic> toJson() => {
        'already_spun': alreadySpun,
        'coupon_code': couponCode,
        'discount_pct': discountPct,
        'original_price': originalPrice,
        'discounted_price': discountedPrice,
        'message': message,
      };
}