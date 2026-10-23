import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'menu_board/providers/menu_provider.dart';
import 'menu_board/providers/order_provider.dart';
import 'menu_board/providers/pengeluaran_provider.dart';
import 'menu_board/providers/theme_provider.dart';

import 'tambah_pesanan/widgets/app_scaffold.dart';

import 'tambah_pesanan/screens/dashboard/dashboard_screen.dart';
import 'tambah_pesanan/screens/menu/menu_screen.dart';
import 'tambah_pesanan/screens/order/add_order_screen.dart';
// ⚠️ PENTING: baris di bawah samain PERSIS sama yang kemarin
//    dibenerin VS Code (quick fix) di main.dart lama kamu.
//    Kalau path-nya beda, pakai punyamu yang itu.
import 'tambah_pesanan/screens/order_history/order_history_screen.dart';
import 'tambah_pesanan/screens/pengaturan/pengaturan_screen.dart';
import 'tambah_pesanan/screens/pengeluaran/pengeluaran_screen.dart';
import 'tambah_pesanan/screens/statistik/statistik_screen.dart';

import 'theme/app_colors.dart';
import 'theme/app_text_styles.dart';

const String kSupabaseUrl = 'https://nbsemkswjlvnzwwlyhhg.supabase.co';
const String kSupabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5ic2Vta3N3amx2bnp3d2x5aGhnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTEwMDY2ODYsImV4cCI6MjEwNjU4MjY4Nn0.ahs4IZEWrj5pyUipNkjfY3YlgjbywgSQeQIjebthqdk';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
      url: kSupabaseUrl, publishableKey: kSupabaseAnonKey);
  runApp(const KasirSapuanginApp());
}

class KasirSapuanginApp extends StatefulWidget {
  const KasirSapuanginApp({super.key});

  @override
  State<KasirSapuanginApp> createState() => _KasirSapuanginAppState();
}

class _KasirSapuanginAppState extends State<KasirSapuanginApp> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<MenuProvider>().loadMenu();
      context.read<OrderProvider>().loadOrders();
      context.read<OrderProvider>().loadRingkasanHariIni();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MenuProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => PengeluaranProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) => MaterialApp.router(
        title: 'Kasir Sapuangin',
        debugShowCheckedModeBanner: false,
        theme: _buatTemaKasir(),
        darkTheme: _buatTemaGelap(),
        themeMode: themeProvider.themeMode,
        routerConfig: _router,
      ),
      ),
    );
  }
}

// ==============================================================
// Route lengkap. Menu & Riwayat dibungkus AppScaffold DI SINI,
// jadi garis 3-nya hidup tanpa perlu utik file screen-nya.
//   Beranda     -> /             AppScaffold di dalam dashboard
//   Menu        -> /menu         dibungkus di sini (index 1)
//   Riwayat     -> /riwayat      dibungkus di sini (index 2)
//   Statistik   -> /statistik    (push, tombol back)
//   Pengeluaran -> /pengeluaran  (push, tombol back)
//   Pengaturan  -> /pengaturan   (push, tombol back)
//   FAB Beranda -> /tambah-pesanan
// ==============================================================
final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/tambah-pesanan',
      builder: (context, state) => const AddOrderScreen(),
    ),
    GoRoute(
      path: '/menu',
      builder: (context, state) => AppScaffold(
        currentIndex: 1, // 1 = Menu
        child: const MenuScreen(),
      ),
    ),
    GoRoute(
      path: '/riwayat',
      builder: (context, state) => AppScaffold(
        currentIndex: 2, // 2 = Riwayat
        child: const OrderHistoryScreen(),
      ),
    ),
    GoRoute(
      path: '/pengaturan',
      builder: (context, state) => const PengaturanScreen(),
    ),
    GoRoute(
      path: '/statistik',
      builder: (context, state) => const StatistikScreen(),
    ),
    GoRoute(
      path: '/pengeluaran',
      builder: (context, state) => const PengeluaranScreen(),
    ),
  ],
);

ThemeData _buatTemaGelap() {
  const latar = Color(0xFF101D18);
  const permukaan = Color(0xFF1B2B24);
  const teks = Color(0xFFF4F0E6);
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.forestGreen,
    brightness: Brightness.dark,
  ).copyWith(
    primary: const Color(0xFF8DB9A2),
    secondary: AppColors.gold,
    surface: permukaan,
    error: AppColors.statusBatal,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: latar,
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF14251D),
      foregroundColor: teks,
      elevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: teks),
      titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: teks),
    ),
    cardTheme: CardThemeData(
      color: permukaan,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFF35483D)),
      ),
      margin: EdgeInsets.zero,
    ),
    dividerColor: const Color(0xFF35483D),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: permukaan,
      hintStyle: const TextStyle(color: Color(0xFFB0BDB5)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}

ThemeData _buatTemaKasir() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.forestGreen,
  ).copyWith(
    primary: AppColors.forestGreen,
    secondary: AppColors.gold,
    surface: AppColors.surface,
    error: AppColors.statusBatal,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.forestGreen,
      foregroundColor: AppColors.putih,
      elevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: AppColors.putih),
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.putih,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.forestGreen,
        foregroundColor: AppColors.putih,
        disabledBackgroundColor: AppColors.border,
        disabledForegroundColor: AppColors.textSecondary,
        minimumSize: const Size.fromHeight(52),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: AppTextStyles.button,
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.forestGreenDark,
      contentTextStyle: TextStyle(color: AppColors.putih, fontSize: 14),
      actionTextColor: AppColors.gold,
    ),
    dividerColor: AppColors.border,
    textTheme: const TextTheme(
      displayMedium: AppTextStyles.displayMedium,
      displaySmall: AppTextStyles.displaySmall,
      titleLarge: AppTextStyles.titleLarge,
      titleMedium: AppTextStyles.titleMedium,
      titleSmall: AppTextStyles.titleSmall,
      bodyLarge: AppTextStyles.bodyLarge,
      bodyMedium: AppTextStyles.bodyMedium,
      bodySmall: AppTextStyles.bodySmall,
    ),
  );
}
