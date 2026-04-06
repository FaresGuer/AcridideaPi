import 'package:flutter/material.dart';

class AppColors {
  // Primary colors
  static const Color primary = Color(0xFF00897B);

  // Background colors
  static const Color mintBackground = Color.fromRGBO(222, 250, 233, 1);

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

  // Private constructor to prevent instantiation
  AppColors._();
}
