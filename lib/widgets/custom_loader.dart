import 'dart:ui';

import 'package:giffy_dialog/giffy_dialog.dart';

import '../core/utils/library.dart';

class LoaderWidget extends StatelessWidget {
  final bool isBlurBackground;
  final Color? loaderColor;
  final double? size;

  const LoaderWidget({
    super.key,
    this.loaderColor,
    this.size,
    this.isBlurBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    final loaderSize = size ?? 40; // 👈 default size

    return isBlurBackground
        ? AbsorbPointer(
      child: SizedBox(
        height: Get.height,
        width: Get.width,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 4.0,
            sigmaY: 4.0,
            tileMode: TileMode.mirror,
          ),
          child: Center(
            child: Lottie.asset(
              Assets.lottieLoadingDots,
              height: loaderSize,
              width: loaderSize,
            ),
          ),
        ),
      ),
    )
        : Center(
      child: Lottie.asset(
        Assets.lottieLoadingDots,
        height: loaderSize,
        width: loaderSize,
      ),
    );
  }
}
