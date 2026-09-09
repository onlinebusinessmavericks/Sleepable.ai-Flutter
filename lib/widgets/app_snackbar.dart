import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Every in-app message goes through here instead of calling Get.snackbar.
///
/// GetX takes its snackbar colours from the ambient ThemeData: the text falls
/// back to `theme.iconTheme.color` and then to black, painted over a
/// translucent grey. This app draws dark screens but follows the system theme
/// (`ThemeMode.system`), so on a phone set to light mode every message came out
/// black on near-black and could not be read at all. Pinning the colours here
/// means a message looks the same whatever the phone is set to.
///
/// Call sites keep the Get.snackbar signature, so only the name changes.
void appSnackbar(
  String title,
  String message, {
  SnackPosition snackPosition = SnackPosition.BOTTOM,
  Duration duration = const Duration(seconds: 3),
  Color? colorText,
  Color? backgroundColor,
  EdgeInsets? margin,
  double borderRadius = 14,
  TextButton? mainButton,
  bool isError = false,
}) {
  // Slightly lighter than the app background so the message reads as a layer
  // above the screen rather than a hole in it.
  const surface = Color(0xFF1E2233);
  const errorSurface = Color(0xFF3A1F26);

  Get.snackbar(
    title,
    message,
    snackPosition: snackPosition,
    duration: duration,
    colorText: colorText ?? Colors.white,
    backgroundColor: backgroundColor ?? (isError ? errorSurface : surface),
    margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    borderRadius: borderRadius,
    mainButton: mainButton,
    barBlur: 0,
    overlayBlur: 0,
    boxShadows: const [
      BoxShadow(color: Colors.black54, blurRadius: 18, offset: Offset(0, 6)),
    ],
    borderColor: Colors.white24,
    borderWidth: 1,
    isDismissible: true,
    forwardAnimationCurve: Curves.easeOutCubic,
  );
}
