import 'package:flutter/material.dart';

class AppColors {
  // Primary colors - Teal/Green theme
  static const Color primary = Color(0xFF00897B);
  static const Color primaryVariant = Color(0xFF00695C);
  static const Color secondary = Color(0xFF26A69A);
  static const Color secondaryVariant = Color(0xFF004D40);

  // Background colors
  static const Color background = Color(0xFFFFFFFF);
  static const Color mintBackground = Color.fromRGBO(222, 250, 233, 1); // User requested background
  static const Color surface = Color(0xFFFFFFFF);

  // Text colors
  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);

  // Status colors
  static const Color error = Color(0xFFB00020);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color info = Color(0xFF2196F3);

  // Dashboard specific colors
  static const Color temperature = Color(0xFFFF9800);
  static const Color humidity = Color(0xFF2196F3);
  static const Color liveRed = Color(0xFFFF5252);
  static const Color darkGreen = Color(0xFF2E7D32);

  // Utility
  static const Color divider = Color(0xFFE0E0E0);
  static const Color disabled = Color(0xFFE0E0E0);

  // Private constructor to prevent instantiation
  AppColors._();
}
