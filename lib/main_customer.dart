import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'pelanggan/config_pelanggan.dart';
import 'pelanggan/pelanggan_provider.dart';
import 'pelanggan/screens/menu_pelanggan_screen.dart';
import 'pelanggan/screens/status_pesanan_screen.dart';
import 'theme/app_theme.dart';

// PENTING: file ini TIDAK boleh meng-import main.dart (kasir) atau apa pun dari
// folder tambah_pesanan/, supaya kode kasir tidak ikut ter-build ke website.

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: kSupabaseUrlPelanggan,
    publishableKey: kSupabaseKeyPelanggan,
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => PelangganProvider(),
      child: const SapuanginPelangganApp(),
    ),
  );
}

final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const MenuPelangganScreen(),
    ),
    GoRoute(
      path: '/pesanan/:id',
      builder: (context, state) => StatusPesananScreen(
        orderId: state.pathParameters['id'] ?? '',
      ),
    ),
  ],
);

class SapuanginPelangganApp extends StatelessWidget {
  const SapuanginPelangganApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: kNamaToko,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      routerConfig: _router,
      // Tampilan selalu berbentuk HP (portrait), rapi juga saat dibuka di laptop.
      builder: (context, child) {
        return ColoredBox(
          color: AppColors.lightSurfaceAlt,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: kBatasLebar),
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        );
      },
    );
  }
}