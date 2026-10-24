import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

// Re-export supaya halaman lama yang mengimpor app_theme.dart tetap bisa
// mengakses AppColors dan AppTextStyles tanpa mengubah semua import sekaligus.
export 'app_colors.dart';
export 'app_text_styles.dart';

/// Konfigurasi tema tunggal. Seluruh halaman sebaiknya mengambil warna dari
/// Theme.of(context).colorScheme, bukan menulis warna langsung di tiap screen.
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => _buildTheme(dark: false);
  static ThemeData get darkTheme => _buildTheme(dark: true);

  // Alias untuk kompatibilitas dengan kode yang masih memakai AppTheme.theme.
  static ThemeData get theme => lightTheme;

  static ThemeData _buildTheme({required bool dark}) {
    final background =
        dark ? AppColors.darkBackground : AppColors.lightBackground;
    final surface = dark ? AppColors.darkSurface : AppColors.lightSurface;
    final surfaceAlt =
        dark ? AppColors.darkSurfaceAlt : AppColors.lightSurfaceAlt;
    final border = dark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary =
        dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        dark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final brightness = dark ? Brightness.dark : Brightness.light;

    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.forestGreen,
      brightness: brightness,
    ).copyWith(
      primary: AppColors.forestGreen,
      onPrimary: AppColors.putih,
      secondary: AppColors.gold,
      onSecondary: dark ? AppColors.darkBackground : AppColors.forestGreenDark,
      error: AppColors.statusBatal,
      onError: AppColors.putih,
      surface: surface,
      onSurface: textPrimary,
      surfaceContainerHighest: surfaceAlt,
      outline: border,
      outlineVariant: border,
      primaryContainer:
          dark ? AppColors.forestGreenDark : const Color(0xFFE0EAE3),
      onPrimaryContainer:
          dark ? AppColors.darkTextPrimary : AppColors.forestGreenDark,
      secondaryContainer: dark ? const Color(0xFF4B432A) : AppColors.goldMuda,
      onSecondaryContainer:
          dark ? const Color(0xFFF7EAC0) : AppColors.forestGreenDark,
      errorContainer: dark ? const Color(0xFF512D2D) : const Color(0xFFF5E2E0),
      onErrorContainer:
          dark ? const Color(0xFFFFDAD6) : const Color(0xFF5D1717),
      tertiary: dark ? const Color(0xFF91B6A1) : AppColors.forestGreenMuda,
      onTertiary: dark ? AppColors.darkBackground : AppColors.putih,
      tertiaryContainer:
          dark ? const Color(0xFF294638) : const Color(0xFFDCE9DF),
      onTertiaryContainer:
          dark ? AppColors.darkTextPrimary : AppColors.forestGreenDark,
      inverseSurface: dark ? AppColors.lightSurface : AppColors.darkSurface,
      onInverseSurface:
          dark ? AppColors.lightTextPrimary : AppColors.darkTextPrimary,
      inversePrimary:
          dark ? const Color(0xFF9BC8B1) : AppColors.forestGreenMuda,
      surfaceTint: AppColors.forestGreen,
    );

    final baseTextTheme = ThemeData(brightness: brightness).textTheme;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      dividerColor: border,
      textTheme: baseTextTheme.copyWith(
        displayLarge: AppTextStyles.displayLarge.copyWith(color: textPrimary),
        displayMedium: AppTextStyles.displayMedium.copyWith(color: textPrimary),
        displaySmall: AppTextStyles.displaySmall.copyWith(color: textPrimary),
        titleLarge: AppTextStyles.titleLarge.copyWith(color: textPrimary),
        titleMedium: AppTextStyles.titleMedium.copyWith(color: textPrimary),
        titleSmall: AppTextStyles.titleSmall.copyWith(color: textPrimary),
        bodyLarge: AppTextStyles.bodyLarge.copyWith(color: textPrimary),
        bodyMedium: AppTextStyles.bodyMedium.copyWith(color: textPrimary),
        bodySmall: AppTextStyles.bodySmall.copyWith(color: textSecondary),
        labelLarge: AppTextStyles.button.copyWith(color: textPrimary),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.forestGreenDark,
        foregroundColor: AppColors.textOnGreen,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: AppColors.textOnGreen),
        titleTextStyle:
            AppTextStyles.displaySmall.copyWith(color: AppColors.textOnGreen),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: border),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: dark ? AppColors.goldSoft : AppColors.forestGreen,
        textColor: textPrimary,
        subtitleTextStyle: TextStyle(color: textSecondary, fontSize: 12),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: TextStyle(color: textSecondary),
        labelStyle: TextStyle(color: textSecondary),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.forestGreen,
          foregroundColor: AppColors.putih,
          disabledBackgroundColor: surfaceAlt,
          disabledForegroundColor: textSecondary,
          elevation: 0,
          textStyle: AppTextStyles.button.copyWith(color: AppColors.putih),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: dark ? AppColors.goldSoft : AppColors.forestGreen,
          side: BorderSide(
              color: dark ? AppColors.goldSoft : AppColors.forestGreen),
          textStyle: AppTextStyles.button,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      // Switch: thumb putih, track hijau saat aktif (tersedia) dan abu saat
      // mati (habis). Ganti AppColors.putih di thumbColor dengan
      // AppColors.gold kalau mau thumb emas.
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(AppColors.putih),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return dark ? AppColors.forestGreenMuda : AppColors.forestGreen;
          }
          return dark ? AppColors.darkBorder : AppColors.abu;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
        thumbIcon: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Icon(Icons.check_rounded,
                color: AppColors.forestGreen);
          }
          return const Icon(Icons.close_rounded, color: AppColors.abu);
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            dark ? AppColors.darkSurfaceAlt : AppColors.forestGreenDark,
        contentTextStyle: TextStyle(
            color: dark ? AppColors.darkTextPrimary : AppColors.putih),
        actionTextColor: AppColors.goldSoft,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.forestGreenDark,
      ),
      progressIndicatorTheme:
          const ProgressIndicatorThemeData(color: AppColors.forestGreenMuda),
    );
  }
}
