import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'menu_board/providers/auth_provider.dart';
import 'menu_board/providers/menu_provider.dart';
import 'menu_board/providers/order_provider.dart';
import 'menu_board/providers/theme_provider.dart';

import 'theme/app_theme.dart';

import 'tambah_pesanan/widgets/app_scaffold.dart';
import 'tambah_pesanan/screens/dashboard/dashboard_screen.dart';
import 'tambah_pesanan/screens/login/login_screen.dart';
import 'tambah_pesanan/screens/order/add_order_screen.dart';
import 'tambah_pesanan/screens/order_history/order_history_screen.dart';
import 'tambah_pesanan/screens/pengaturan/kelola_menu_screen.dart';
import 'tambah_pesanan/screens/pengaturan/pengaturan_screen.dart';
import 'tambah_pesanan/screens/statistik/statistik_screen.dart';

const String kSupabaseUrl = 'https://nbsemkswjlvnzwwlyhhg.supabase.co';
const String kSupabasePublishableKey =
    'sb_publishable_K1QMR9WNPheN5IaWY4gMLQ_3uOw8p3l';

/// Satu instance dipakai bersama oleh router dan Provider.
final AuthProvider authProvider = AuthProvider();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Supabase satu kali sebelum aplikasi dan provider dibuat.
  await Supabase.initialize(
    url: kSupabaseUrl,
    publishableKey: kSupabasePublishableKey,
  );

  // Pulihkan sesi login yang tersimpan (kalau ada).
  await authProvider.pulihkanSesi();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => MenuProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const KasirSapuanginApp(),
    ),
  );
}

class KasirSapuanginApp extends StatefulWidget {
  const KasirSapuanginApp({super.key});

  @override
  State<KasirSapuanginApp> createState() => _KasirSapuanginAppState();
}

class _KasirSapuanginAppState extends State<KasirSapuanginApp> {
  String? _idTerakhir;

  @override
  void initState() {
    super.initState();
    authProvider.addListener(_onAuthBerubah);

    // Kalau sesi tersimpan sudah ada, langsung isi nama kasir dan muat data.
    WidgetsBinding.instance.addPostFrameCallback((_) => _onAuthBerubah());
  }

  @override
  void dispose() {
    authProvider.removeListener(_onAuthBerubah);
    super.dispose();
  }

  void _onAuthBerubah() {
    if (!mounted) return;

    final profil = authProvider.profil;
    if (profil?.id == _idTerakhir) return;
    _idTerakhir = profil?.id;

    final order = context.read<OrderProvider>();

    if (profil == null) {
      // Logout: bersihkan sisa data akun sebelumnya.
      order.kosongkanKeranjang();
      order.setKasir('');
      return;
    }

    // Login: nama kasir otomatis dari akun, lalu muat data.
    order.setKasir(profil.nama);
    _muatData();
  }

  void _muatData() {
    if (!mounted) return;
    context.read<MenuProvider>().loadMenu();
    context.read<OrderProvider>().loadOrders();
    context.read<OrderProvider>().loadRingkasanHariIni();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp.router(
          title: 'Kasir Sapuangin',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          routerConfig: _router,
        );
      },
    );
  }
}

/// Halaman yang boleh dibuka role kasir.
const Set<String> _halamanKasir = {'/', '/riwayat'};

final GoRouter _router = GoRouter(
  initialLocation: '/',
  refreshListenable: authProvider,
  redirect: (context, state) {
    final lokasi = state.matchedLocation;

    // Belum login -> wajib ke halaman login.
    if (!authProvider.sudahMasuk) {
      return lokasi == '/login' ? null : '/login';
    }

    // Sudah login tapi membuka halaman login -> ke dashboard.
    if (lokasi == '/login') return '/';

    // Kasir hanya boleh dashboard (dan riwayat lewat tombol di dashboard).
    if (!authProvider.isAdmin && !_halamanKasir.contains(lokasi)) {
      return '/';
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/',
      name: 'dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/tambah-pesanan',
      name: 'tambah-pesanan',
      builder: (context, state) => const AddOrderScreen(),
    ),
    GoRoute(
      path: '/menu',
      name: 'menu',
      builder: (context, state) => const AppScaffold(
        currentIndex: 1,
        child: KelolaMenuScreen(),
      ),
    ),
    GoRoute(
      path: '/riwayat',
      name: 'riwayat',
      builder: (context, state) => const AppScaffold(
        currentIndex: 2,
        child: OrderHistoryScreen(),
      ),
    ),
    GoRoute(
      path: '/statistik',
      name: 'statistik',
      builder: (context, state) => const AppScaffold(
        currentIndex: 3,
        child: StatistikScreen(),
      ),
    ),
    GoRoute(
      path: '/pengaturan',
      name: 'pengaturan',
      builder: (context, state) => const AppScaffold(
        currentIndex: 4,
        child: PengaturanScreen(),
      ),
    ),
  ],
);