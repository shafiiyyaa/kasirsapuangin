import 'package:go_router/go_router.dart';

import '../../tambah_pesanan/screens/dashboard/dashboard_screen.dart';
import '../../tambah_pesanan/screens/menu/menu_screen.dart';
import '../../tambah_pesanan/screens/order/add_order_screen.dart';
import '../../tambah_pesanan/screens/order_history/order_history_screen.dart';
import '../../tambah_pesanan/screens/pengeluaran/pengeluaran_screen.dart';
import '../../tambah_pesanan/screens/statistik/statistik_screen.dart';
import '../../tambah_pesanan/widgets/app_scaffold.dart';

/// Konfigurasi rute aplikasi.
/// Beranda, Menu, dan Riwayat dibungkus AppScaffold (drawer + FAB).
/// Statistik & Pengeluaran dibuka penuh (punya tombol back sendiri).
/// Tambah Pesanan full-screen, dibuka lewat tombol "+".
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
          child: OrderHistoryScreen(),
        ),
      ),
      GoRoute(
        path: '/statistik',
        name: 'statistik',
        builder: (context, state) => const StatistikScreen(),
      ),
      GoRoute(
        path: '/pengeluaran',
        name: 'pengeluaran',
        builder: (context, state) => const PengeluaranScreen(),
      ),
      GoRoute(
        path: '/tambah-pesanan',
        name: 'tambah-pesanan',
        builder: (context, state) => const AddOrderScreen(),
      ),
    ],
  );
}