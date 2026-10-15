import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_theme.dart';
import 'app_drawer.dart';

/// Shell navigasi utama: bottom nav 3 menu + FAB tambah pesanan
/// (hanya Dashboard) + drawer menu samping. Halaman-halaman dalam
/// bisa membuka drawer lewat [AppScaffold.openMenu].
class AppScaffold extends StatelessWidget {
  /// 0 = Beranda, 1 = Menu, 2 = Riwayat
  final int currentIndex;
  final Widget child;

  const AppScaffold({
    super.key,
    required this.currentIndex,
    required this.child,
  });

  /// Dipanggil dari AppBar halaman dalam (Dashboard/Menu/Riwayat)
  /// untuk membuka drawer milik AppScaffold.
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
      bottomNavigationBar: BottomAppBar(
        color: AppColors.surface,
        elevation: 4,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavButton(
              icon: Icons.space_dashboard_outlined,
              label: 'Beranda',
              selected: currentIndex == 0,
              onTap: () => context.go('/'),
            ),
            _NavButton(
              icon: Icons.restaurant_menu_outlined,
              label: 'Menu',
              selected: currentIndex == 1,
              onTap: () => context.go('/menu'),
            ),
            _NavButton(
              icon: Icons.receipt_long_outlined,
              label: 'Riwayat',
              selected: currentIndex == 2,
              onTap: () => context.go('/riwayat'),
            ),
          ],
        ),
      ),
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

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.forestGreen : AppColors.textSecondary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: color,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}