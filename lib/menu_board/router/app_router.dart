import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../tambah_pesanan/screens/dashboard/dashboard_screen.dart';
import '../../tambah_pesanan/screens/menu/menu_screen.dart';
import '../../tambah_pesanan/screens/order/add_order_screen.dart';
import '../../tambah_pesanan/widgets/app_scaffold.dart';

/// Konfigurasi rute aplikasi.
/// Dashboard, Menu, dan Riwayat dibungkus AppScaffold (bottom nav +
/// tombol tambah pesanan di tengah). Tambah Pesanan sengaja TIDAK
/// dibungkus AppScaffold — dia full-screen, dibuka lewat tombol "+"
/// dan ditutup lagi setelah pesanan disimpan.
class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'dashboard',
        builder: (context, state) => const AppScaffold(
          currentIndex: 0,
          child: DashboardScreen(),
        ),
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
          child: _PlaceholderScreen(judul: 'Riwayat Pesanan'),
        ),
      ),
      GoRoute(
        path: '/tambah-pesanan',
        name: 'tambah-pesanan',
        builder: (context, state) => const AddOrderScreen(),
      ),
    ],
  );
}

class _PlaceholderScreen extends StatelessWidget {
  final String judul;
  const _PlaceholderScreen({required this.judul});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(judul)),
      body: Center(
        child: Text('Halaman $judul menyusul.'),
      ),
    );
  }
}