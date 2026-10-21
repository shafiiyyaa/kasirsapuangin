import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Gaya teks resmi Kasir Sapuangin.
/// Font judul pake 'Fraunces' — kalau belum ada fontnya di pubspec,
/// otomatis fallback ke font default (aman, nggak error).
class AppTextStyles {
  AppTextStyles._();

  static const String _fontJudul = 'Fraunces';

  // ---- Judul besar ----
  static const TextStyle displayMedium = TextStyle(
    fontFamily: _fontJudul,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.25,
    color: AppColors.forestGreen,
  );

  static const TextStyle displaySmall = TextStyle(
    fontFamily: _fontJudul,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.25,
    color: AppColors.forestGreen,
  );

  // ---- Judul section / kartu ----
  static const TextStyle titleLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  // ---- Isi teks ----
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  // ---- Harga ----
  static const TextStyle price = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.forestGreen,
  );

  static const TextStyle priceLarge = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: AppColors.forestGreen,
  );

  static const TextStyle priceSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.forestGreen,
  );

  // ---- Tombol & label ----
  static const TextStyle button = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.putih,
    letterSpacing: 0.2,
  );

  static const TextStyle label = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppColors.textSecondary,
    letterSpacing: 1.1,
  );
}