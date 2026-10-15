import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_theme.dart';
import 'app_drawer.dart';

/// Shell utama: drawer menu samping (navigasi utama) + FAB tambah
/// pesanan (hanya di Beranda). Tidak ada bottom nav lagi.
class AppScaffold extends StatelessWidget {
  /// 0 = Beranda, 1 = Menu, 2 = Riwayat
  final int currentIndex;
  final Widget child;

  const AppScaffold({
    super.key,
    required this.currentIndex,
    required this.child,
  });

  /// Dipanggil dari AppBar halaman dalam untuk membuka drawer.
  static void openMenu(BuildContext context) {
    context.findAncestorWidgetOfExactType<_MenuHook>()?.onOpen();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(currentIndex: currentIndex),
      body: Builder(
        builder: (bodyContext) => _MenuHook(
          onOpen: () => Scaffold.of(bodyContext).openDrawer(),
          child: child,
        ),
      ),
      floatingActionButton: currentIndex == 0
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

/// Penghubung antara halaman dalam dan drawer AppScaffold.
class _MenuHook extends InheritedWidget {
  final VoidCallback onOpen;

  const _MenuHook({required this.onOpen, required super.child});

  @override
  bool updateShouldNotify(_MenuHook oldWidget) => false;
}