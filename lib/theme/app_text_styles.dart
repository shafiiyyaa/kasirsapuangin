import 'package:flutter/material.dart';

/// Tipografi bersama untuk aplikasi Kasir Sapuangin.
/// Warna sengaja diwariskan dari ThemeData agar teks tidak terkunci ke
/// warna mode terang ketika aplikasi memakai mode gelap.
class AppTextStyles {
  AppTextStyles._();

  static const String _fontJudul = 'Fraunces';

  static const TextStyle displayLarge = TextStyle(
    fontFamily: _fontJudul,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.15,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: _fontJudul,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  static const TextStyle displaySmall = TextStyle(
    fontFamily: _fontJudul,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.25,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    height: 1.45,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    height: 1.45,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    height: 1.4,
  );

  static const TextStyle price = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    fontFamily: _fontJudul,
  );

  static const TextStyle priceLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    fontFamily: _fontJudul,
  );

  static const TextStyle priceSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    fontFamily: _fontJudul,
  );

  static const TextStyle button = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
  );

  static const TextStyle label = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.1,
  );
}
