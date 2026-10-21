import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ⚠️ PENTING: samain import provider di bawah sama path folder kamu.
// Kalau nggak punya file pengeluaran_provider.dart, hapus import-nya
// + baris ChangeNotifierProvider(create: (_) => PengeluaranProvider()).
import 'menu_board/providers/menu_provider.dart';
import 'menu_board/providers/order_provider.dart';
import 'menu_board/providers/pengeluaran_provider.dart';

// ⚠️ PENTING: samain import screen di bawah sama path folder kamu.
import 'tambah_pesanan/screens/dashboard/dashboard_screen.dart';
import 'tambah_pesanan/screens/order/add_order_screen.dart';
import 'tambah_pesanan/screens/pengaturan/pengaturan_screen.dart';

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
      ],
      child: MaterialApp.router(
        title: 'Kasir Sapuangin',
        debugShowCheckedModeBanner: false,
        theme: _buatTemaKasir(),
        routerConfig: _router,
      ),
    );
  }
}

// ==============================================================
// ⚠️ WAJIB DICEK: daftar route aku bikin dari yang aku tahu.
//    Kalau di main.dart lama kamu path-nya beda, atau ada route
//    statistik/riwayat/detail — copy blok GoRoute dari main lama
//    kamu ke sini.
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
      path: '/pengaturan',
      builder: (context, state) => const PengaturanScreen(),
    ),
    // Contoh route tambahan (uncomment + samain import-nya):
    // GoRoute(
    //   path: '/statistik',
    //   builder: (context, state) => const StatistikScreen(),
    // ),
  ],
);

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
