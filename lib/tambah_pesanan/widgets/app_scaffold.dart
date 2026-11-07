import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../menu_board/providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class AppScaffold extends StatefulWidget {
  /// 0 = Dashboard, 1 = Kelola Menu, 2 = Riwayat,
  /// 3 = Statistik, 4 = Pengaturan.
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
    final dark = Theme.of(context).brightness == Brightness.dark;

    final background =
        dark ? AppColors.darkBackground : AppColors.lightBackground;

    final sidebar = dark ? AppColors.darkSidebar : AppColors.lightSidebar;

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= AppScaffold.desktopBreakpoint;

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: background,
          drawer: wide
              ? null
              : Drawer(
                  backgroundColor: sidebar,
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
                      width: 260,
                      child: _SidebarContent(
                        currentIndex: widget.currentIndex,
                        isDrawer: false,
                      ),
                    ),
                    VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color:
                          dark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                    Expanded(child: widget.child),
                  ],
                )
              : widget.child,
        );
      },
    );
  }
}

class _SidebarContent extends StatelessWidget {
  final int currentIndex;
  final bool isDrawer;

  const _SidebarContent({
    required this.currentIndex,
    required this.isDrawer,
  });

  void _navigate(
    BuildContext context,
    String route, {
    bool push = false,
  }) {
    if (isDrawer) {
      Navigator.of(context).pop();
    }

    if (push) {
      context.push(route);
    } else {
      context.go(route);
    }
  }

  Future<void> _keluar(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final navigator = Navigator.of(context);

    final yakin = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Keluar dari akun?'),
        content: const Text('Kamu harus login lagi untuk memakai aplikasi.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (yakin != true) return;
    if (isDrawer && navigator.canPop()) navigator.pop();
    await auth.keluar();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    final background = dark ? AppColors.darkSidebar : AppColors.lightSidebar;

    final primaryText =
        dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    final secondaryText =
        dark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final accent = dark ? AppColors.sageLight : AppColors.forestGreen;

    final border = dark ? AppColors.darkBorder : AppColors.lightBorder;

    final auth = context.watch<AuthProvider>();
    final isAdmin = auth.isAdmin;

    return Material(
      color: background,
      child: SafeArea(
        child: Column(
          children: [
            // BRAND
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 16, 18),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: dark
                          ? AppColors.darkSurfaceAlt
                          : AppColors.lightSurfaceAlt,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: dark
                            ? AppColors.darkBorder
                            : AppColors.forestGreenMuda.withOpacity(0.45),
                      ),
                    ),
                    child: Icon(
                      Icons.landscape_rounded,
                      size: 28,
                      color: accent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kasir Sapuangin',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.titleLarge.copyWith(
                            color: primaryText,
                            fontSize: 17,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Sapuangin Coffee & Farm',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: secondaryText,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 19),
              child: Container(
                height: 1,
                color: border,
              ),
            ),

            const SizedBox(height: 17),

            // MENU NAVIGASI
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 2,
                ),
                children: [
                  _SidebarItem(
                    icon: Icons.space_dashboard_rounded,
                    label: 'Dashboard',
                    selected: currentIndex == 0,
                    dark: dark,
                    onTap: () => _navigate(context, '/'),
                  ),
                  if (isAdmin) ...[
                    _SidebarItem(
                      icon: Icons.restaurant_menu_rounded,
                      label: 'Kelola Menu',
                      selected: currentIndex == 1,
                      dark: dark,
                      onTap: () => _navigate(context, '/menu'),
                    ),
                    _SidebarItem(
                      icon: Icons.receipt_long_rounded,
                      label: 'Riwayat Pesanan',
                      selected: currentIndex == 2,
                      dark: dark,
                      onTap: () => _navigate(context, '/riwayat'),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        14,
                        23,
                        12,
                        9,
                      ),
                      child: Text(
                        'OPERASIONAL',
                        style: AppTextStyles.label.copyWith(
                          color: secondaryText,
                          fontSize: 10,
                          letterSpacing: 1.6,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    _SidebarItem(
                      icon: Icons.bar_chart_rounded,
                      label: 'Statistik',
                      selected: currentIndex == 3,
                      dark: dark,
                      onTap: () => _navigate(context, '/statistik'),
                    ),
                    _SidebarItem(
                      icon: Icons.settings_rounded,
                      label: 'Pengaturan',
                      selected: currentIndex == 4,
                      dark: dark,
                      onTap: () => _navigate(context, '/pengaturan'),
                    ),
                  ],
                ],
              ),
            ),

            // AKUN
            Padding(
              padding: const EdgeInsets.fromLTRB(17, 6, 17, 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                decoration: BoxDecoration(
                  color:
                      dark ? AppColors.darkSurface : AppColors.lightSurfaceAlt,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: border),
                ),
                child: Row(
                  children: [
                    Icon(
                      isAdmin
                          ? Icons.admin_panel_settings_rounded
                          : Icons.badge_rounded,
                      color: accent,
                      size: 21,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            auth.profil?.nama ?? '-',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: primaryText,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            isAdmin ? 'Admin' : 'Kasir',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: secondaryText,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Keluar',
                      onPressed: () => _keluar(context),
                      icon: Icon(
                        Icons.logout_rounded,
                        color: secondaryText,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // DOODLE ALAM
            SizedBox(
              height: 128,
              width: double.infinity,
              child: CustomPaint(
                painter: _NatureDoodlePainter(
                  dark: dark,
                ),
                child: const SizedBox.expand(),
              ),
            ),

            // FOOTER
            Padding(
              padding: const EdgeInsets.fromLTRB(
                17,
                0,
                17,
                16,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  color:
                      dark ? AppColors.darkSurface : AppColors.lightSurfaceAlt,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: border),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.local_cafe_outlined,
                      color: accent,
                      size: 21,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Racik dengan hati.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: primaryText,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.eco_outlined,
                      color: accent,
                      size: 20,
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
  final bool dark;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.dark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primaryText =
        dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    final secondaryText =
        dark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final selectedBackground = dark
        ? AppColors.darkSurfaceAlt
        : AppColors.forestGreen.withOpacity(0.12);

    final selectedText = dark ? AppColors.sageLight : AppColors.forestGreen;

    final selectedBorder = dark
        ? AppColors.sage.withOpacity(0.45)
        : AppColors.forestGreen.withOpacity(0.22);

    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Material(
        color: selected ? selectedBackground : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 13,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? selectedBorder : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: selected ? selectedText : secondaryText,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: selected ? selectedText : primaryText,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                if (selected)
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: selectedText,
                      shape: BoxShape.circle,
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

class _NatureDoodlePainter extends CustomPainter {
  final bool dark;

  const _NatureDoodlePainter({required this.dark});

  @override
  void paint(Canvas canvas, Size size) {
    final color = dark ? const Color(0xFF7FAE94) : const Color(0xFF8FA68B);

    final linePaint = Paint()
      ..color = color.withOpacity(dark ? 0.30 : 0.34)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = color.withOpacity(dark ? 0.12 : 0.16)
      ..style = PaintingStyle.fill;

    // Bukit dan gunung di bagian bawah sidebar.
    final mountain = Path()
      ..moveTo(0, size.height * 0.76)
      ..lineTo(size.width * 0.22, size.height * 0.34)
      ..lineTo(size.width * 0.35, size.height * 0.58)
      ..lineTo(size.width * 0.49, size.height * 0.20)
      ..lineTo(size.width * 0.76, size.height * 0.76)
      ..close();

    canvas.drawPath(mountain, fillPaint);
    canvas.drawPath(mountain, linePaint);

    final hill = Path()
      ..moveTo(0, size.height * 0.87)
      ..quadraticBezierTo(
        size.width * 0.34,
        size.height * 0.58,
        size.width * 0.70,
        size.height * 0.86,
      );

    canvas.drawPath(hill, linePaint);

    // Ranting di sisi kanan.
    final branch = Path()
      ..moveTo(size.width * 0.80, size.height)
      ..quadraticBezierTo(
        size.width * 0.84,
        size.height * 0.66,
        size.width,
        size.height * 0.43,
      );

    canvas.drawPath(branch, linePaint);

    void drawLeaf(
      Offset start,
      Offset tip,
      Offset control1,
      Offset control2,
    ) {
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(
          control1.dx,
          control1.dy,
          tip.dx,
          tip.dy,
        )
        ..quadraticBezierTo(
          control2.dx,
          control2.dy,
          start.dx,
          start.dy,
        )
        ..close();

      canvas.drawPath(path, fillPaint);
      canvas.drawPath(path, linePaint);
    }

    drawLeaf(
      Offset(size.width * 0.87, size.height * 0.70),
      Offset(size.width * 0.98, size.height * 0.54),
      Offset(size.width * 0.94, size.height * 0.71),
      Offset(size.width * 0.91, size.height * 0.60),
    );

    drawLeaf(
      Offset(size.width * 0.84, size.height * 0.82),
      Offset(size.width * 0.69, size.height * 0.68),
      Offset(size.width * 0.74, size.height * 0.82),
      Offset(size.width * 0.79, size.height * 0.72),
    );

    drawLeaf(
      Offset(size.width * 0.91, size.height * 0.58),
      Offset(size.width * 0.89, size.height * 0.40),
      Offset(size.width * 0.94, size.height * 0.48),
      Offset(size.width * 0.87, size.height * 0.48),
    );
  }

  @override
  bool shouldRepaint(
    covariant _NatureDoodlePainter oldDelegate,
  ) {
    return oldDelegate.dark != dark;
  }
}
