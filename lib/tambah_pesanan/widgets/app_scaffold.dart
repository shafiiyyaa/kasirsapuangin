import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_theme.dart';
import 'app_drawer.dart';

/// Shell utama: drawer menu samping (navigasi utama) + FAB tambah
/// pesanan (hanya di Beranda). Tidak ada bottom nav lagi.
class AppScaffold extends StatefulWidget {
  /// 0 = Beranda, 1 = Menu, 2 = Riwayat
  final int currentIndex;
  final Widget child;

  const AppScaffold({
    super.key,
    required this.currentIndex,
    required this.child,
  });

  /// Dipanggil dari AppBar halaman dalam untuk membuka drawer.
  ///
  /// Sekarang AMAN dipanggil dari context mana pun (termasuk
  /// context build milik screen yang ada DI ATAS AppScaffold),
  /// karena nggak lagi andelin `findAncestorWidgetOfExactType`.
  static void openMenu(BuildContext context) {
    // 1) Ambil AppScaffold yang lagi aktif (paling atas di layar).
    final state = _AppScaffoldState.aktif;
    if (state != null) {
      state.bukaDrawer();
      return;
    }
    // 2) Fallback: kalau caller kebetulan di dalam body AppScaffold,
    //    cara klasik tetap jalan.
    Scaffold.maybeOf(context)?.openDrawer();
  }

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  /// Daftar semua AppScaffold yang masih hidup di tree.
  /// Yang terakhir dibuat = yang lagi tampil di layar.
  /// Pas route di-pop/di-replace, yang mati otomatis keluar dari daftar.
  static final List<_AppScaffoldState> _daftarHidup = [];

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static _AppScaffoldState? get aktif =>
      _daftarHidup.isEmpty ? null : _daftarHidup.last;

  @override
  void initState() {
    super.initState();
    _daftarHidup.add(this);
  }

  @override
  void dispose() {
    _daftarHidup.remove(this);
    super.dispose();
  }

  void bukaDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: AppDrawer(currentIndex: widget.currentIndex),
      body: widget.child,
      floatingActionButton: widget.currentIndex == 0
          ? FloatingActionButton(
              onPressed: () => context.push('/tambah-pesanan'),
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.forestGreenDark,
              elevation: 4,
              shape: const CircleBorder(),
              child: const Icon(Icons.add, size: 28),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}