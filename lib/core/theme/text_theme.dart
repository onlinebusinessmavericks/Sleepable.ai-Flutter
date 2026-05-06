import 'package:flutter/material.dart';
import '../constants/colors.dart';

class AppTextTheme {
  static TextTheme lightTextTheme =  TextTheme(
    headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.white, letterSpacing: 0.25),
    headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.white, letterSpacing: 0.25),
    bodyLarge: TextStyle(fontSize: 16, color: AppColors.textSecondary, letterSpacing: 0.25),
    bodyMedium: TextStyle(fontSize: 14, color: AppColors.textSecondary, letterSpacing: 0.25),
    labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.white, letterSpacing: 0.25),
    titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.white, letterSpacing: 0.25),
  );

  static TextTheme darkTextTheme = const TextTheme(
    headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.white),
    headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.white),
    bodyLarge: TextStyle(fontSize: 16, color: AppColors.white),
    bodyMedium: TextStyle(fontSize: 14, color: Colors.grey),
    labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.white),
  );
}

// class SizeConfigs {
//   static late double screenWidth;
//   static late double screenHeight;
//   static late double textScale;
//   static late double paddingScale;
//
//   static void init(BuildContext context) {
//     final size = MediaQuery.of(context).size;
//     screenWidth = size.width;
//     screenHeight = size.height;
//
//     textScale = ((screenWidth / 390) + (screenHeight / 844)) / 2;
//     paddingScale = screenWidth / 400;
//
//   }
// }
class SizeConfigs {
  static late double screenWidth;
  static late double screenHeight;
  static late double textScale;
  static late double paddingScale;

  static void init(BuildContext context) {
    final size = MediaQuery.of(context).size;
    screenWidth = size.width;
    screenHeight = size.height;

    final baseTextScale = ((screenWidth / 390) + (screenHeight / 844)) / 2;

    // 🔹 Clamp to prevent extreme scaling
    textScale = baseTextScale.clamp(0.85, 1.25);

    // 🔹 Padding scaling (also safe range)
    paddingScale = (screenWidth / 400).clamp(0.85, 1.3);
  }
}
class SizeConfigs2 {
  static late double screenWidth;
  static late double screenHeight;

  static late double textScale;
  static late double paddingScale;
  static late double scale; // master scale

  static void init(BuildContext context) {
    final size = MediaQuery.of(context).size;

    screenWidth = size.width;
    screenHeight = size.height;

    // Base design size (iPhone 12 / Pixel 5)
    const baseWidth = 390.0;
    const baseHeight = 844.0;

    // Master scale (balanced)
    scale = (screenWidth / baseWidth)
        .clamp(0.85, 1.25);

    // Text scale (slightly more controlled)
    textScale = scale.clamp(0.9, 1.2);

    // Padding scale (a bit more flexible)
    paddingScale = scale.clamp(0.9, 1.3);
  }
}
double sp(double v) => v * SizeConfigs2.textScale;
double pad(double v) => v * SizeConfigs2.paddingScale;
double sw(double v) => v * SizeConfigs2.scale;
double sh(double v) => v * SizeConfigs2.scale;
