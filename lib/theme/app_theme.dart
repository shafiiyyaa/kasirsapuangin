import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Palet warna aplikasi, diambil dari logo Sapuangin Merapi
/// (hijau tua + emas), dengan background layar putih krem yang lembut
/// supaya nyaman dipakai lama oleh kasir — bukan tema gelap.
class AppColors {
  AppColors._();

  // Warna inti dari logo
  static const Color forestGreen = Color(0xFF1F4D3D); // hijau tua logo
  static const Color forestGreenDark = Color(0xFF16392C); // untuk tekanan/hover
  static const Color gold = Color(0xFFC9A227); // emas logo
  static const Color goldSoft = Color(0xFFE3C878); // emas lebih muda, buat aksen halus

  // Background & permukaan
  static const Color background = Color(0xFFFBF7EF); // krem lembut, bukan putih polos
  static const Color surface = Color(0xFFFFFFFF); // kartu/panel
  static const Color surfaceAlt = Color(0xFFF3ECDD); // panel sekunder, sedikit lebih krem

  // Teks
  static const Color textPrimary = Color(0xFF20241F); // hampir hitam, sedikit hijau
  static const Color textSecondary = Color(0xFF6B7066);
  static const Color textOnGreen = Color(0xFFFBF7EF);

  // Status pesanan
  static const Color statusBaru = Color(0xFFC9A227); // emas = baru/pending
  static const Color statusDiproses = Color(0xFF3B6E99); // biru tenang = diproses
  static const Color statusSelesai = Color(0xFF1F4D3D); // hijau = selesai
  static const Color statusBatal = Color(0xFFA14C4C); // merah redup = dibatalkan

  // Border & divider
  static const Color border = Color(0xFFE4DCC8);
}

/// Kumpulan TextStyle aplikasi.
/// Dipilih supaya tampilannya khas (bukan Material default) tapi tetap
/// rapi dibaca untuk layar kasir yang padat.
class AppTextStyles {
  AppTextStyles._();

  // Font display untuk judul/angka besar — sedikit unik, serif modern
  static TextStyle get displayLarge => GoogleFonts.fraunces(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.1,
      );

  static TextStyle get displayMedium => GoogleFonts.fraunces(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.15,
      );

  // Font body — sans-serif bersih, enak dibaca di layar padat
  static TextStyle get bodyLarge => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyMedium => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodySmall => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );

  static TextStyle get label => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 0.4,
      );

  // Khusus harga — dibuat tebal & jelas, warna emas
  static TextStyle get price => GoogleFonts.fraunces(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.forestGreenDark,
      );

  static TextStyle get priceLarge => GoogleFonts.fraunces(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.forestGreenDark,
      );

  static TextStyle get button => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textOnGreen,
        letterSpacing: 0.2,
      );
}

/// ThemeData utama aplikasi.
class AppTheme {
  AppTheme._();

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.forestGreen,
        primary: AppColors.forestGreen,
        secondary: AppColors.gold,
        surface: AppColors.surface,
        error: AppColors.statusBatal,
        brightness: Brightness.light,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.displayMedium,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.forestGreen,
          foregroundColor: AppColors.textOnGreen,
          textStyle: AppTextStyles.button,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.forestGreen,
          side: const BorderSide(color: AppColors.forestGreen, width: 1.2),
          textStyle: AppTextStyles.button.copyWith(color: AppColors.forestGreen),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.forestGreen, width: 1.5),
        ),
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayLarge,
        displayMedium: AppTextStyles.displayMedium,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,
        labelLarge: AppTextStyles.label,
      ),
    );
  }
}