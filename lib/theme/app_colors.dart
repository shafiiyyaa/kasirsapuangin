import 'package:flutter/material.dart';

/// Satu sumber warna resmi Kasir Sapuangin.
/// Token utama brand dipakai di mode terang dan gelap; alias di bawah
/// menjaga kompatibilitas dengan kode lama selama migrasi halaman.
class AppColors {
  AppColors._();

  // Brand Sapuangin
  static const Color forestGreen = Color(0xFF155744);
  static const Color forestGreenDark = Color(0xFF0D4035);
  static const Color forestGreenMuda = Color(0xFF2B705A);
  static const Color gold = Color(0xFFC9A94E);
  static const Color goldSoft = Color(0xFFE0CD86);
  static const Color goldMuda = Color(0xFFF4E9C8);

  // Mode terang
  static const Color lightBackground = Color(0xFFFBF7EF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceAlt = Color(0xFFF4EFE4);
  static const Color lightBorder = Color(0xFFE4DCC8);
  static const Color lightTextPrimary = Color(0xFF24312B);
  static const Color lightTextSecondary = Color(0xFF6E7B74);

  // Mode gelap: hijau arang, bukan hitam pekat atau hijau neon.
  static const Color darkBackground = Color(0xFF101D18);
  static const Color darkSurface = Color(0xFF192A22);
  static const Color darkSurfaceAlt = Color(0xFF22372D);
  static const Color darkBorder = Color(0xFF354A3E);
  static const Color darkTextPrimary = Color(0xFFF4F0E6);
  static const Color darkTextSecondary = Color(0xFFB8C5BA);

  // Status tetap mudah dibedakan pada kedua mode.
  static const Color statusBaru = Color(0xFFC9A227);
  static const Color statusDiproses = Color(0xFF4E8CB8);
  static const Color statusSelesai = Color(0xFF3E8A61);
  static const Color statusBatal = Color(0xFFA14C4C);
  static const Color success = Color(0xFF3E7C4F);
  static const Color warning = Color(0xFFD98A2B);

  static const Color putih = Color(0xFFFFFFFF);
  static const Color abu = Color(0xFF9AA5A0);

  // Alias kompatibilitas: kode lama yang memakai AppColors.background,
  // surface, border, textPrimary, dan seterusnya tetap dapat dikompilasi.
  // Ini adalah token mode terang; halaman akan dimigrasikan ke Theme.of(context).
  static const Color background = lightBackground;
  static const Color surface = lightSurface;
  static const Color surfaceAlt = lightSurfaceAlt;
  static const Color border = lightBorder;
  static const Color textPrimary = lightTextPrimary;
  static const Color textSecondary = lightTextSecondary;
  static const Color textOnGreen = Color(0xFFFBF7EF);
}
