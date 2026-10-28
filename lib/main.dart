import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'menu_board/providers/menu_provider.dart';
import 'menu_board/providers/order_provider.dart';
import 'menu_board/providers/pengeluaran_provider.dart';
import 'menu_board/providers/theme_provider.dart';

import 'theme/app_theme.dart';

import 'tambah_pesanan/widgets/app_scaffold.dart';
import 'tambah_pesanan/screens/login/login_screen.dart';
import 'tambah_pesanan/screens/dashboard/dashboard_screen.dart';
import 'tambah_pesanan/screens/menu/menu_screen.dart';
import 'tambah_pesanan/screens/order/add_order_screen.dart';
import 'tambah_pesanan/screens/order_history/order_history_screen.dart';
import 'tambah_pesanan/screens/pengaturan/pengaturan_screen.dart';
import 'tambah_pesanan/screens/pengeluaran/pengeluaran_screen.dart';
import 'tambah_pesanan/screens/statistik/statistik_screen.dart';

const String kSupabaseUrl = 'https://nbsemkswjlvnzwwlyhhg.supabase.co';
const String kSupabasePublishableKey =
    'sb_publishable_K1QMR9WNPheN5IaWY4gMLQ_3uOw8p3l';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Supabase satu kali sebelum aplikasi dan provider dibuat.
  await Supabase.initialize(
    url: kSupabaseUrl,
    publishableKey: kSupabasePublishableKey,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MenuProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => PengeluaranProvider()),
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
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();

    // Setiap kali kasir BERHASIL login, muat ulang data yang butuh akses kasir.
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn && data.session != null) {
        _muatDataKasir();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // Menu boleh dibaca siapa saja.
      context.read<MenuProvider>().loadMenu();

      // Pesanan & pengeluaran hanya untuk kasir yang sudah login
      // (misalnya aplikasi dibuka lagi dan sesi login masih tersimpan).
      if (Supabase.instance.client.auth.currentSession != null) {
        _muatDataKasir();
      }
    });
  }

  void _muatDataKasir() {
    if (!mounted) return;
    context.read<OrderProvider>().loadOrders();
    context.read<OrderProvider>().loadRingkasanHariIni();
    context.read<PengeluaranProvider>().loadPengeluaran();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
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

/// Memberi tahu router setiap kali status login berubah (login / logout),
/// supaya halaman otomatis pindah ke /login atau ke dashboard.
class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier() {
    _sub = Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<AuthState> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final _AuthNotifier _authNotifier = _AuthNotifier();

final GoRouter _router = GoRouter(
  initialLocation: '/',
  refreshListenable: _authNotifier,
  redirect: (context, state) {
    final sudahLogin = Supabase.instance.client.auth.currentSession != null;
    final diHalamanLogin = state.matchedLocation == '/login';

    if (!sudahLogin && !diHalamanLogin) return '/login';
    if (sudahLogin && diHalamanLogin) return '/';
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
        child: MenuScreen(),
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
      path: '/pengeluaran',
      name: 'pengeluaran',
      builder: (context, state) => const AppScaffold(
        currentIndex: 4,
        child: PengeluaranScreen(),
      ),
    ),
    GoRoute(
      path: '/pengaturan',
      name: 'pengaturan',
      builder: (context, state) => const AppScaffold(
        currentIndex: 5,
        child: PengaturanScreen(),
      ),
    ),
  ],
);