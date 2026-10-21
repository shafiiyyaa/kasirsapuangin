import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_theme.dart';

/// Menu samping (drawer) gaya aplikasi kasir: daftar semua halaman.
class AppDrawer extends StatelessWidget {
  final int currentIndex;

  const AppDrawer({super.key, required this.currentIndex});

  void _pindah(BuildContext context, String route, {bool push = false}) {
    Navigator.pop(context); // tutup drawer dulu
    if (push) {
      context.push(route);
    } else {
      context.go(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.background,
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Kasir Sapuangin',
                      style: AppTextStyles.displayMedium),
                  const SizedBox(height: 2),
                  Text(
                    'Sapuangin Coffee & Farm',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            _MenuItem(
              icon: Icons.space_dashboard_outlined,
              label: 'Beranda',
              selected: currentIndex == 0,
              onTap: () => _pindah(context, '/'),
            ),
            _MenuItem(
              icon: Icons.restaurant_menu_outlined,
              label: 'Menu',
              selected: currentIndex == 1,
              onTap: () => _pindah(context, '/menu'),
            ),
            _MenuItem(
              icon: Icons.receipt_long_outlined,
              label: 'Riwayat Pesanan',
              selected: currentIndex == 2,
              onTap: () => _pindah(context, '/riwayat'),
            ),
            const Divider(),
            _MenuItem(
              icon: Icons.bar_chart_outlined,
              label: 'Statistik',
              selected: false,
              onTap: () => _pindah(context, '/statistik', push: true),
            ),
            _MenuItem(
              icon: Icons.shopping_basket_outlined,
              label: 'Pengeluaran',
              selected: false,
              onTap: () => _pindah(context, '/pengeluaran', push: true),
            ),
            const Divider(),
            const _MenuItem(
              icon: Icons.settings_outlined,
              label: 'Pengaturan',
              selected: false,
              onTap: null, // menyusul
              trailing: 'Segera',
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final String? trailing;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.forestGreen : AppColors.textSecondary;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: AppTextStyles.bodyLarge.copyWith(
          color: selected ? AppColors.forestGreen : AppColors.textPrimary,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
      trailing: trailing == null
          ? null
          : Text(
              trailing!,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
      onTap: onTap,
    );
  }
}