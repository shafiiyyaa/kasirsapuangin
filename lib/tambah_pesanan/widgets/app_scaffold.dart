import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_theme.dart';

/// Shell navigasi utama aplikasi: bottom nav bar dengan tombol
/// "Tambah Pesanan" menonjol di tengah. Membungkus Dashboard, Menu,
/// dan Riwayat Pesanan — masing-masing tetap punya Scaffold/AppBar
/// sendiri di dalamnya, shell ini cuma nambahin bar navigasi di bawah.
class AppScaffold extends StatelessWidget {
  /// 0 = Dashboard, 1 = Menu, 2 = Riwayat
  final int currentIndex;
  final Widget child;

  const AppScaffold({
    super.key,
    required this.currentIndex,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/tambah-pesanan'),
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.forestGreenDark,
        elevation: 2,
        child: const Icon(Icons.add, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: AppColors.surface,
        elevation: 4,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavButton(
              icon: Icons.space_dashboard_outlined,
              label: 'Dashboard',
              selected: currentIndex == 0,
              onTap: () => context.go('/'),
            ),
            _NavButton(
              icon: Icons.restaurant_menu_outlined,
              label: 'Menu',
              selected: currentIndex == 1,
              onTap: () => context.go('/menu'),
            ),
            // Ruang kosong buat notch tombol tambah di tengah
            const SizedBox(width: 56),
            _NavButton(
              icon: Icons.receipt_long_outlined,
              label: 'Riwayat',
              selected: currentIndex == 2,
              onTap: () => context.go('/riwayat'),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
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