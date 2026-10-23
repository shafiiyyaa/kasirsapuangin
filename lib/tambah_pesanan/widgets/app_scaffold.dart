import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_theme.dart';
import 'app_drawer.dart';

/// Shell responsif: drawer pada HP portrait, sidebar permanen pada layar lebar.
class AppScaffold extends StatefulWidget {
  final int currentIndex;
  final Widget child;

  const AppScaffold({
    super.key,
    required this.currentIndex,
    required this.child,
  });

  static bool isWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 900;

  static void openMenu(BuildContext context) {
    final state = _AppScaffoldState.aktif;
    if (state != null && !isWide(context)) {
      state.bukaDrawer();
      return;
    }
    Scaffold.maybeOf(context)?.openDrawer();
  }

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
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

  void bukaDrawer() => _scaffoldKey.currentState?.openDrawer();

  Widget _sidebar() => Container(
        width: 280,
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border(right: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Kasir Sapuangin', style: AppTextStyles.displayMedium),
                    const SizedBox(height: 2),
                    Text('Sapuangin Coffee & Farm',
                        style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const Divider(height: 1),
              _navItem(Icons.space_dashboard_outlined, 'Beranda',
                  widget.currentIndex == 0, () => context.go('/')),
              _navItem(Icons.restaurant_menu_outlined, 'Menu',
                  widget.currentIndex == 1, () => context.go('/menu')),
              _navItem(Icons.receipt_long_outlined, 'Riwayat Pesanan',
                  widget.currentIndex == 2, () => context.go('/riwayat')),
              const Divider(),
              _navItem(Icons.bar_chart_outlined, 'Statistik', false,
                  () => context.push('/statistik')),
              _navItem(Icons.shopping_basket_outlined, 'Pengeluaran', false,
                  () => context.push('/pengeluaran')),
              const Divider(),
              _navItem(Icons.settings_outlined, 'Pengaturan',
                  widget.currentIndex == 3, () => context.push('/pengaturan')),
            ],
          ),
        ),
      );

  Widget _navItem(IconData icon, String label, bool selected, VoidCallback onTap) {
    final color = selected ? AppColors.forestGreen : AppColors.textSecondary;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: AppTextStyles.bodyLarge.copyWith(
        color: selected ? AppColors.forestGreen : AppColors.textPrimary,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
      )),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide = AppScaffold.isWide(context);
    final content = Scaffold(
      key: _scaffoldKey,
      drawer: wide ? null : AppDrawer(currentIndex: widget.currentIndex),
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

    if (!wide) return content;
    return Row(
      children: [
        _sidebar(),
        Expanded(child: content),
      ],
    );
  }
}
