import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF2F5D9F);
  static const Color secondary = Color(0xFF2C8E83);
  static const Color accent = Color(0xFF3A9D8F);
  static const Color background = Color(0xFFF2F6FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color error = Color(0xFFB42318);

  static const Color success = Color(0xFF1F8A4C);
  static const Color warning = Color(0xFFC77800);
  static const Color danger = Color(0xFFC23A2B);

  static const Color darkBackground = Color(0xFF0F1724);
  static const Color darkSurface = Color(0xFF182334);
  static const Color darkPrimary = Color(0xFF88B4FF);
  static const Color darkSecondary = Color(0xFF79C6BD);
  static const Color darkError = Color(0xFFFF8A80);

  static Color eventStatus(String status) {
    switch (status) {
      case 'approved':
        return success;
      case 'rejected':
        return danger;
      case 'pending':
      default:
        return warning;
    }
  }
}
