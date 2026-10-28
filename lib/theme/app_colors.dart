
import 'package:flutter/material.dart';

/// Palet warna utama Kasir Sapuangin.
/// Forest green, warm ivory, dan sage untuk tampilan natural.
class AppColors {
  AppColors._();

  // Brand
  static const Color forestGreen = Color(0xFF286B56);
  static const Color forestGreenDark = Color(0xFF102B23);
  static const Color forestGreenMuda = Color(0xFF4D8B70);

  // Accent
  static const Color gold = Color(0xFFC9A94E);
  static const Color goldSoft = Color(0xFFE0CD86);
  static const Color goldMuda = Color(0xFFF4E9C8);
  static const Color sage = Color(0xFF72B49B);
  static const Color sageLight = Color(0xFFA6D7BD);

  // Light mode
  static const Color lightBackground = Color(0xFFF5F1E6);
  static const Color lightSidebar = Color(0xFFF5F1E6);
  static const Color lightSurface = Color(0xFFFFFEFA);
  static const Color lightSurfaceAlt = Color(0xFFEAE5D5);
  static const Color lightBorder = Color(0xFFD8D2C1);
  static const Color lightTextPrimary = Color(0xFF24312B);
  static const Color lightTextSecondary = Color(0xFF6E7B74);

  // Dark mode: forest green yang hangat dan berlapis
  static const Color darkBackground = Color(0xFF0B211B);
  static const Color darkSidebar = Color(0xFF102A22);
  static const Color darkSurface = Color(0xFF15352C);
  static const Color darkSurfaceAlt = Color(0xFF1B4035);
  static const Color darkBorder = Color(0xFF34584A);
  static const Color darkTextPrimary = Color(0xFFF4F0E6);
  static const Color darkTextSecondary = Color(0xFFB8C9BE);

  // Status
  static const Color statusBaru = Color(0xFFC9A227);
  static const Color statusDiproses = Color(0xFF4E8CB8);
  static const Color statusSelesai = Color(0xFF3E8A61);
  static const Color statusBatal = Color(0xFFA14C4C);

  static const Color success = Color(0xFF3E7C4F);
  static const Color warning = Color(0xFFD98A2B);
  static const Color error = Color(0xFFA14C4C);

  static const Color putih = Color(0xFFFFFFFF);
  static const Color abu = Color(0xFF9AA5A0);

  // Alias agar kode lama tetap kompatibel
  static const Color background = lightBackground;
  static const Color surface = lightSurface;
  static const Color surfaceAlt = lightSurfaceAlt;
  static const Color border = lightBorder;
  static const Color textPrimary = lightTextPrimary;
  static const Color textSecondary = lightTextSecondary;
  static const Color textOnGreen = Color(0xFFFBF7EF);
}
