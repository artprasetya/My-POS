import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ─── Primary Palette ───
  static const Color primary = Color(0xFF6C5CE7);
  static const Color primaryLight = Color(0xFF9B8FEF);
  static const Color primaryDark = Color(0xFF4A3DB8);
  static const Color primarySurface = Color(0xFFF0EDFF);

  // ─── Secondary / Accent ───
  static const Color accent = Color(0xFF00D2D3);
  static const Color accentLight = Color(0xFF55E6E6);
  static const Color accentDark = Color(0xFF00A8A9);

  // ─── Semantic Colors ───
  static const Color success = Color(0xFF00C48C);
  static const Color successLight = Color(0xFFE6FAF3);
  static const Color warning = Color(0xFFFFAA2C);
  static const Color warningLight = Color(0xFFFFF5E6);
  static const Color error = Color(0xFFFF6B6B);
  static const Color errorLight = Color(0xFFFFECEC);
  static const Color info = Color(0xFF54A0FF);
  static const Color infoLight = Color(0xFFEBF3FF);

  // ─── Neutral / Gray Scale ───
  static const Color black = Color(0xFF1A1A2E);
  static const Color darkGray = Color(0xFF2D2D44);
  static const Color gray = Color(0xFF6B7280);
  static const Color mediumGray = Color(0xFF9CA3AF);
  static const Color lightGray = Color(0xFFE5E7EB);
  static const Color extraLightGray = Color(0xFFF3F4F6);
  static const Color white = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF8F9FD);

  // ─── Dark Mode ───
  static const Color darkBackground = Color(0xFF0F0F23);
  static const Color darkSurface = Color(0xFF1A1A2E);
  static const Color darkCard = Color(0xFF222244);
  static const Color darkBorder = Color(0xFF2D2D55);
  static const Color darkText = Color(0xFFE8E8F0);
  static const Color darkTextSecondary = Color(0xFF8888AA);
  static const Color darkDivider = Color(0xFF2D2D55);

  // ─── Gradients ───
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6C5CE7), Color(0xFF9B59B6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF00D2D3), Color(0xFF00B894)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF00C48C), Color(0xFF00B894)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── Category Colors ───
  static const List<Color> categoryColors = [
    Color(0xFF6C5CE7),
    Color(0xFF00D2D3),
    Color(0xFFFF6B6B),
    Color(0xFFFFAA2C),
    Color(0xFF00C48C),
    Color(0xFF54A0FF),
    Color(0xFFFF9FF3),
    Color(0xFFFECA57),
    Color(0xFF5F27CD),
    Color(0xFF01A3A4),
  ];

  // ─── Payment Method Colors ───
  static const Color cashColor = Color(0xFF00C48C);
  static const Color qrisColor = Color(0xFF6C5CE7);
  static const Color cardColor = Color(0xFF54A0FF);
  static const Color ewalletColor = Color(0xFFFFAA2C);
}
