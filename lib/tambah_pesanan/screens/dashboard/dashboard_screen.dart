import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../menu_board/models/menu_item.dart';
import '../../../menu_board/models/order.dart';
import '../../../menu_board/providers/menu_provider.dart';
import '../../../menu_board/providers/order_provider.dart';
import '../../../theme/app_theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/order_detail_sheet.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadData();
    });
    _searchController.addListener(() {
      final next = _searchController.text.trim().toLowerCase();
      if (next != _query && mounted) setState(() => _query = next);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final menu = context.read<MenuProvider>();
    final orders = context.read<OrderProvider>();
    await Future.wait<void>([
      menu.loadMenu(),
      orders.loadRingkasanHariIni(),
      orders.loadOrders(),
    ]);
  }

  List<MenuItem> _filterMenu(List<MenuItem> items) {
    return items.where((item) {
      final matchesQuery = _query.isEmpty ||
          item.nama.toLowerCase().contains(_query) ||
          item.kategori.toLowerCase().contains(_query);
      final matchesCategory =
          _selectedCategory == null || item.kategori == _selectedCategory;
      return matchesQuery && matchesCategory;
    }).toList();
  }

  Future<void> _toggleAvailability(MenuItem item) async {
    try {
      await context
          .read<MenuProvider>()
          .ubahStatusTersedia(item.id, !item.tersedia);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            item.tersedia
                ? '${item.nama} ditandai habis.'
                : '${item.nama} tersedia kembali.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengubah status menu: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<bool> _confirmDelete(Order order) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Hapus pesanan?'),
            content: Text(
              'Pesanan ${order.namaPelanggan?.trim().isNotEmpty == true ? order.namaPelanggan : 'Tanpa nama'} '
              '(${_formatRupiah(order.totalHarga)}) akan dihapus permanen. Lanjutkan?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Batal'),
              ),
              FilledButton.tonal(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Hapus'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _deleteOrder(Order order) async {
    if (!await _confirmDelete(order) || !mounted) return;
    try {
      await context.read<OrderProvider>().hapusPesanan(order.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pesanan berhasil dihapus.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus pesanan: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final wideScreen = AppScaffold.isWide(context);

    return AppScaffold(
      currentIndex: 0,
      child: Scaffold(
        // Desktop langsung masuk ke pencarian/kategori, tanpa judul Dashboard.
        // Di layar sempit tetap ada tombol drawer.
        appBar: wideScreen
            ? null
            : AppBar(
                title: const Text('Sapuangin Coffee & Farm'),
                leading: IconButton(
                  icon: const Icon(Icons.menu_rounded),
                  tooltip: 'Buka menu',
                  onPressed: () => AppScaffold.openMenu(context),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: 'Muat ulang data',
                    onPressed: _loadData,
                  ),
                  const SizedBox(width: 6),
                ],
              ),
        body: RefreshIndicator(
          onRefresh: _loadData,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final horizontalPadding = width < 420 ? 12.0 : 20.0;
              final desktopContent = width >= 900;

              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  wideScreen ? 18 : 12,
                  horizontalPadding,
                  100,
                ),
                children: [
                  // Search + kategori menjadi fokus pertama dashboard.
                  if (desktopContent)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 7, child: _buildMenuSection()),
                        const SizedBox(width: 20),
                        Expanded(flex: 4, child: _buildOrdersSection()),
                      ],
                    )
                  else ...[
                    _buildMenuSection(),
                    const SizedBox(height: 26),
                    _buildOrdersSection(),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMenuSection() {
    final scheme = Theme.of(context).colorScheme;
    return Consumer<MenuProvider>(
      builder: (context, provider, _) {
        final categories = provider.kategoriList;
        final filtered = _filterMenu(provider.items);
        final columns = _menuColumns(MediaQuery.sizeOf(context).width);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari nama atau kategori menu...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Hapus pencarian',
                        onPressed: () => _searchController.clear(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                filled: true,
                fillColor: scheme.surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            if (categories.isNotEmpty) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 76,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _CategoryChip(
                      label: 'Semua',
                      icon: Icons.grid_view_rounded,
                      selected: _selectedCategory == null,
                      onTap: () => setState(() => _selectedCategory = null),
                    ),
                    for (final category in categories)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: _CategoryChip(
                          label: category,
                          icon: _iconForCategory(category),
                          selected: _selectedCategory == category,
                          onTap: () => setState(() => _selectedCategory = category),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),
            _SectionHeading(
              title: 'Menu hari ini',
              subtitle: 'Pilih kategori dan atur ketersediaan menu',
              trailing: TextButton.icon(
                onPressed: () => context.go('/menu'),
                icon: const Icon(Icons.arrow_forward_rounded, size: 17),
                label: const Text('Kelola menu'),
              ),
            ),
            const SizedBox(height: 12),
            if (provider.isLoading && provider.items.isEmpty)
              const _LoadingPanel(label: 'Memuat menu...')
            else if (provider.error != null && provider.items.isEmpty)
              _MessagePanel(
                icon: Icons.cloud_off_rounded,
                message: 'Menu belum bisa dimuat.',
                detail: provider.error,
                actionLabel: 'Coba lagi',
                onAction: provider.loadMenu,
              )
            else if (filtered.isEmpty)
              const _MessagePanel(
                icon: Icons.search_off_rounded,
                message: 'Menu tidak ditemukan.',
                detail: 'Coba kata kunci atau kategori lain.',
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final actualColumns = constraints.maxWidth < 340
                      ? 1
                      : (constraints.maxWidth < 720 ? 2 : 3);
                  return GridView.builder(
                    itemCount: filtered.length > 8 ? 8 : filtered.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: actualColumns,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      mainAxisExtent: 150,
                    ),
                    itemBuilder: (context, index) => _MenuPreviewCard(
                      item: filtered[index],
                      onToggle: () => _toggleAvailability(filtered[index]),
                    ),
                  );
                },
              ),
            if (filtered.length > 8) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => context.go('/menu'),
                  icon: const Icon(Icons.grid_view_rounded, size: 17),
                  label: Text('Lihat semua ${filtered.length} menu'),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  int _menuColumns(double screenWidth) {
    if (screenWidth >= 1400) return 3;
    if (screenWidth >= 1000) return 3;
    return 2;
  }

  Widget _buildOrdersSection() {
    final scheme = Theme.of(context).colorScheme;
    return Consumer<OrderProvider>(
      builder: (context, provider, _) {
        final orders = provider.orders.take(6).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeading(
              title: 'Pesanan terbaru',
              subtitle: 'Pantau pesanan yang baru masuk',
              trailing: TextButton(
                onPressed: () => context.go('/riwayat'),
                child: const Text('Lihat semua'),
              ),
            ),
            const SizedBox(height: 12),
            if (provider.isLoadingOrders && orders.isEmpty)
              const _LoadingPanel(label: 'Memuat pesanan...')
            else if (provider.ordersError != null && orders.isEmpty)
              _MessagePanel(
                icon: Icons.cloud_off_rounded,
                message: 'Pesanan belum bisa dimuat.',
                detail: provider.ordersError,
                actionLabel: 'Coba lagi',
                onAction: provider.loadOrders,
              )
            else if (orders.isEmpty)
              const _MessagePanel(
                icon: Icons.receipt_long_outlined,
                message: 'Belum ada pesanan.',
                detail: 'Pesanan yang masuk akan muncul di sini.',
              )
            else
              ...orders.map(
                (order) => Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: _RecentOrderCard(
                    order: order,
                    onTap: () => showOrderDetail(context, order),
                    onLongPress: () => _deleteOrder(order),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withOpacity(0.65),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Row(
                children: [
                  Icon(Icons.tips_and_updates_outlined, color: scheme.secondary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tips: tekan lama pesanan untuk menghapusnya.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;

  const _SectionHeading({required this.title, required this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.displaySmall.copyWith(color: scheme.onSurface)),
              const SizedBox(height: 3),
              Text(subtitle, style: AppTextStyles.bodySmall.copyWith(color: scheme.onSurfaceVariant)),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 6),
          trailing!,
        ],
      ],
    );
  }
}

IconData _iconForCategory(String category) {
  final value = category.toLowerCase();
  if (value.contains('coffee')) return Icons.coffee_rounded;
  if (value.contains('non coffee') || value.contains('non-coffee')) {
    return Icons.local_drink_rounded;
  }
  if (value.contains('milk')) return Icons.local_cafe_rounded;
  if (value.contains('manual brew') || value.contains('brew')) {
    return Icons.coffee_maker_rounded;
  }
  if (value.contains('snack')) return Icons.lunch_dining_rounded;
  if (value.contains('camilan')) return Icons.bakery_dining_rounded;
  if (value.contains('food') || value.contains('makanan')) {
    return Icons.restaurant_rounded;
  }
  if (value.contains('dessert') || value.contains('roti')) {
    return Icons.cake_rounded;
  }
  return Icons.restaurant_menu_rounded;
}

class _CategoryChip extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_CategoryChip> createState() => _CategoryChipState();
}

class _CategoryChipState extends State<_CategoryChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selected = widget.selected;
    final background = selected
        ? scheme.primary
        : (_hovered ? scheme.primary.withOpacity(0.08) : scheme.surface);
    final foreground = selected ? scheme.onPrimary : scheme.primary;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        width: 88,
        height: 72,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
          ),
          boxShadow: _hovered && !selected
              ? [
                  BoxShadow(
                    color: scheme.primary.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : const [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(widget.icon, size: 23, color: foreground),
                  const SizedBox(height: 5),
                  Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w700,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuPreviewCard extends StatefulWidget {
  final MenuItem item;
  final VoidCallback onToggle;
  const _MenuPreviewCard({required this.item, required this.onToggle});

  @override
  State<_MenuPreviewCard> createState() => _MenuPreviewCardState();
}

class _MenuPreviewCardState extends State<_MenuPreviewCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final item = widget.item;
    final available = item.tersedia;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 170),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _hovered ? -2 : 0, 0),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: _hovered ? scheme.primary.withOpacity(0.55) : scheme.outlineVariant,
          ),
          boxShadow: _hovered
              ? [BoxShadow(color: scheme.primary.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))]
              : const [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    item.tipe.toLowerCase() == 'minuman'
                        ? Icons.local_cafe_rounded
                        : Icons.restaurant_rounded,
                    color: scheme.primary,
                    size: 19,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                  decoration: BoxDecoration(
                    color: available
                        ? scheme.tertiaryContainer
                        : scheme.errorContainer,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    available ? 'Tersedia' : 'Habis',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: available ? scheme.onTertiaryContainer : scheme.onErrorContainer,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            Text(
              item.nama,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.titleSmall.copyWith(color: scheme.onSurface),
            ),
            const SizedBox(height: 2),
            Text(
              item.kategori,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall.copyWith(color: scheme.onSurfaceVariant),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _formatRupiah(item.harga),
                      style: AppTextStyles.price.copyWith(color: scheme.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Tooltip(
                  message: available ? 'Tandai habis' : 'Aktifkan kembali',
                  child: IconButton(
                    onPressed: widget.onToggle,
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints.tightFor(width: 34, height: 34),
                    padding: EdgeInsets.zero,
                    style: IconButton.styleFrom(
                      backgroundColor: available ? scheme.primary : scheme.error,
                      foregroundColor: scheme.onPrimary,
                    ),
                    icon: Icon(
                      available ? Icons.check_rounded : Icons.refresh_rounded,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentOrderCard extends StatefulWidget {
  final Order order;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  const _RecentOrderCard({required this.order, required this.onTap, required this.onLongPress});

  @override
  State<_RecentOrderCard> createState() => _RecentOrderCardState();
}

class _RecentOrderCardState extends State<_RecentOrderCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final order = widget.order;
    final statusColor = _statusColor(order.status, scheme);
    final name = order.namaPelanggan?.trim().isNotEmpty == true
        ? order.namaPelanggan!.trim()
        : 'Pelanggan';
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: Matrix4.translationValues(_hovered ? 2 : 0, 0, 0),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: _hovered ? scheme.primary.withOpacity(0.45) : scheme.outlineVariant),
        ),
        child: InkWell(
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          borderRadius: BorderRadius.circular(13),
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.receipt_long_rounded, color: scheme.primary, size: 20),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.titleSmall.copyWith(color: scheme.onSurface)),
                      const SizedBox(height: 3),
                      Text(
                        '${order.items.length} item • ${_formatTime(order.createdAt)}',
                        style: AppTextStyles.bodySmall.copyWith(color: scheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.13),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          order.status.label,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    _formatRupiah(order.totalHarga),
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.price.copyWith(color: scheme.primary),
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

Color _statusColor(OrderStatus status, ColorScheme scheme) {
  switch (status) {
    case OrderStatus.baru:
      return AppColors.statusBaru;
    case OrderStatus.diproses:
      return AppColors.statusDiproses;
    case OrderStatus.selesai:
      return AppColors.statusSelesai;
    case OrderStatus.batal:
      return scheme.error;
  }
}

class _LoadingPanel extends StatelessWidget {
  final String label;
  const _LoadingPanel({required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(width: 12),
          Text(label, style: AppTextStyles.bodyMedium.copyWith(color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _MessagePanel extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? detail;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _MessagePanel({
    required this.icon,
    required this.message,
    this.detail,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(icon, size: 27, color: scheme.onSurfaceVariant),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center,
              style: AppTextStyles.titleSmall.copyWith(color: scheme.onSurface)),
          if (detail != null) ...[
            const SizedBox(height: 5),
            Text(detail!, textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(color: scheme.onSurfaceVariant),
                maxLines: 3, overflow: TextOverflow.ellipsis),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 10),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

String _formatRupiah(int value) {
  final digits = value.toString();
  final output = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    output.write(digits[i]);
    final remaining = digits.length - i - 1;
    if (remaining > 0 && remaining % 3 == 0) output.write('.');
  }
  return 'Rp$output';
}

String _formatTime(DateTime dateTime) {
  final local = dateTime.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
