import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_theme.dart';

/// Shell navigasi aplikasi.
/// Layar sempit menggunakan drawer; layar lebar menampilkan sidebar permanen.
class AppScaffold extends StatefulWidget {
  /// 0 = Dashboard, 1 = Menu, 2 = Riwayat, 3 = Statistik, 4 = Pengeluaran, 5 = Pengaturan.
  final int currentIndex;
  final Widget child;

  const AppScaffold({
    super.key,
    required this.currentIndex,
    required this.child,
  });

  static const double desktopBreakpoint = 1000;

  static bool isWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktopBreakpoint;

  static void openMenu(BuildContext context) {
    final state = _AppScaffoldState.active;
    if (state != null) {
      state.openDrawer();
      return;
    }
    Scaffold.maybeOf(context)?.openDrawer();
  }

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  static final List<_AppScaffoldState> _livingStates = [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static _AppScaffoldState? get active =>
      _livingStates.isEmpty ? null : _livingStates.last;

  @override
  void initState() {
    super.initState();
    _livingStates.add(this);
  }

  @override
  void dispose() {
    _livingStates.remove(this);
    super.dispose();
  }

  void openDrawer() => _scaffoldKey.currentState?.openDrawer();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= AppScaffold.desktopBreakpoint;
        final scheme = Theme.of(context).colorScheme;

        return Scaffold(
          key: _scaffoldKey,
          drawer: wide ? null : Drawer(
            backgroundColor: scheme.surface,
            child: SafeArea(
              child: _SidebarContent(
                currentIndex: widget.currentIndex,
                isDrawer: true,
              ),
            ),
          ),
          body: wide
              ? Row(
                  children: [
                    SizedBox(
                      width: 252,
                      child: _SidebarContent(
                        currentIndex: widget.currentIndex,
                        isDrawer: false,
                      ),
                    ),
                    VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: scheme.outlineVariant,
                    ),
                    Expanded(child: widget.child),
                  ],
                )
              : widget.child,
          floatingActionButton: widget.currentIndex == 0
              ? FloatingActionButton(
                  onPressed: () => context.push('/tambah-pesanan'),
                  backgroundColor: scheme.secondary,
                  foregroundColor: scheme.onSecondary,
                  elevation: 3,
                  shape: const CircleBorder(),
                  tooltip: 'Tambah pesanan',
                  child: const Icon(Icons.add_rounded, size: 28),
                )
              : null,
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        );
      },
    );
  }
}

class _SidebarContent extends StatelessWidget {
  final int currentIndex;
  final bool isDrawer;

  const _SidebarContent({required this.currentIndex, required this.isDrawer});

  void _navigate(BuildContext context, String route, {bool push = false}) {
    if (isDrawer) Navigator.of(context).pop();
    if (push) {
      context.push(route);
    } else {
      context.go(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final sidebarColor = dark ? scheme.surface : AppColors.forestGreenDark;
    final primaryText = dark ? scheme.onSurface : AppColors.textOnGreen;
    final secondaryText = dark ? scheme.onSurfaceVariant : const Color(0xFFD8E2D9);
    final accent = dark ? AppColors.goldSoft : AppColors.gold;

    return Material(
      color: sidebarColor,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 22, 14, 17),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: accent.withOpacity(0.8)),
                    ),
                    child: Icon(Icons.landscape_rounded, color: accent, size: 26),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kasir Sapuangin',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.titleLarge.copyWith(color: primaryText),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Sapuangin Coffee & Farm',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall.copyWith(color: secondaryText),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Container(height: 1, color: accent.withOpacity(0.6)),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 2),
                children: [
                  _SidebarItem(
                    icon: Icons.space_dashboard_rounded,
                    label: 'Dashboard',
                    selected: currentIndex == 0,
                    onTap: () => _navigate(context, '/'),
                  ),
                  _SidebarItem(
                    icon: Icons.restaurant_menu_rounded,
                    label: 'Menu',
                    selected: currentIndex == 1,
                    onTap: () => _navigate(context, '/menu'),
                  ),
                  _SidebarItem(
                    icon: Icons.receipt_long_rounded,
                    label: 'Riwayat Pesanan',
                    selected: currentIndex == 2,
                    onTap: () => _navigate(context, '/riwayat'),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(13, 20, 12, 8),
                    child: Text(
                      'OPERASIONAL',
                      style: AppTextStyles.label.copyWith(
                        color: secondaryText,
                        fontSize: 10,
                        letterSpacing: 1.3,
                      ),
                    ),
                  ),
                  _SidebarItem(
                    icon: Icons.bar_chart_rounded,
                    label: 'Statistik',
                    selected: currentIndex == 3,
                    onTap: () => _navigate(context, '/statistik'),
                  ),
                  _SidebarItem(
                    icon: Icons.shopping_basket_rounded,
                    label: 'Pengeluaran',
                    selected: currentIndex == 4,
                    onTap: () => _navigate(context, '/pengeluaran'),
                  ),
                  _SidebarItem(
                    icon: Icons.settings_rounded,
                    label: 'Pengaturan',
                    selected: currentIndex == 5,
                    onTap: () => _navigate(context, '/pengaturan'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryText.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: primaryText.withOpacity(0.10)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.local_cafe_outlined, color: accent, size: 20),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        'Racik dengan hati.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: secondaryText,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final accent = dark ? AppColors.goldSoft : AppColors.gold;
    final inactive = dark ? scheme.onSurfaceVariant : const Color(0xFFD8E2D9);

    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Material(
        color: selected
            ? (dark ? scheme.surfaceContainerHighest : AppColors.forestGreen.withOpacity(0.72))
            : Colors.transparent,
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(11),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: selected ? accent.withOpacity(0.65) : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 19, color: selected ? accent : inactive),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: selected
                          ? (dark ? scheme.onSurface : AppColors.textOnGreen)
                          : inactive,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
