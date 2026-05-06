import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';
import 'text_theme.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.white,
    fontFamily: GoogleFonts.interTight().fontFamily,
    textTheme: GoogleFonts.interTightTextTheme(AppTextTheme.lightTextTheme),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.white,
      elevation: 1,
      titleTextStyle: GoogleFonts.interTight(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: GoogleFonts.interTight().fontFamily,
    textTheme: GoogleFonts.interTightTextTheme(AppTextTheme.darkTextTheme),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background,
      elevation: 1,
      titleTextStyle: GoogleFonts.interTight(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.white),
    ),
  );
}
