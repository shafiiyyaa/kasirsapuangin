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
import '../../services/receipt_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _kasirController = TextEditingController();
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _mejaController = TextEditingController();
  String _query = '';
  String? _selectedCategory;
  String _metodePembayaran = 'cash';
  bool _gridView = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final order = context.read<OrderProvider>();
      _kasirController.text = order.kasir;
      _namaController.text = order.namaPelanggan;
      _mejaController.text = order.meja;
      _metodePembayaran = order.metodePembayaran;
      _loadData();
    });
    _searchController.addListener(() {
      final next = _searchController.text.trim().toLowerCase();
      if (next != _query && mounted) setState(() => _query = next);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _kasirController.dispose();
    _namaController.dispose();
    _mejaController.dispose();
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
          content: Text(item.tersedia
              ? '${item.nama} ditandai habis.'
              : '${item.nama} tersedia kembali.'),
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

  void _addToCart(MenuItem item) {
    if (!item.tersedia) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${item.nama} sedang habis.')),
      );
      return;
    }
    context.read<OrderProvider>().tambahKeKeranjang(
          menuItemId: item.id,
          namaMenu: item.nama,
          hargaSatuan: item.harga,
          catatan: item.catatan,
        );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.nama} ditambahkan ke pesanan'),
        duration: const Duration(milliseconds: 900),
        behavior: SnackBarBehavior.floating,
      ),
    );
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

  Future<void> _checkout({bool closeSheet = false}) async {
    final provider = context.read<OrderProvider>();
    if (provider.keranjangKosong) return;
    if (_kasirController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Isi dulu nama kasirnya ya.')),
      );
      return;
    }

    provider.setKasir(_kasirController.text);
    provider.setNamaPelanggan(_namaController.text);
    provider.setMeja(
      provider.jenisPesanan == 'takeaway' ? '' : _mejaController.text,
    );
    provider.setMetodePembayaran(_metodePembayaran);

    final pesanan = await provider.simpanPesanan();
    if (!mounted) return;
    if (pesanan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(provider.pesanError ?? 'Gagal menyimpan pesanan')),
      );
      return;
    }

    await Future.wait<void>([
      provider.loadOrders(),
      provider.loadRingkasanHariIni(),
    ]);
    if (!mounted) return;

    // Pertahankan nama kasir dan metode bayar untuk transaksi berikutnya.
    _namaController.clear();
    _mejaController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('Pesanan tersimpan • ${_formatRupiah(pesanan.totalHarga)}'),
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: 'Cetak struk',
          onPressed: () => ReceiptService.cetakStruk(pesanan),
        ),
      ),
    );
    if (closeSheet) Navigator.of(context).pop();
  }

  void _openCartSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.82,
        minChildSize: 0.45,
        maxChildSize: 0.96,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _buildCartPanel(inSheet: true),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wideScreen = AppScaffold.isWide(context);

    return AppScaffold(
      currentIndex: 0,
      child: Scaffold(
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
        floatingActionButton: wideScreen
            ? null
            : Consumer<OrderProvider>(
                builder: (context, provider, _) =>
                    FloatingActionButton.extended(
                  onPressed: _openCartSheet,
                  icon: const Icon(Icons.shopping_bag_outlined),
                  label: Text(
                    provider.jumlahItemKeranjang == 0
                        ? 'Tambah pesanan'
                        : 'Pesanan (${provider.jumlahItemKeranjang}) • ${_formatRupiah(provider.totalKeranjang)}',
                  ),
                ),
              ),
        body: RefreshIndicator(
          onRefresh: _loadData,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final horizontalPadding = width < 420 ? 12.0 : 20.0;
              final desktopContent = width >= 820;

              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  wideScreen ? 18 : 12,
                  horizontalPadding,
                  100,
                ),
                children: [
                  if (desktopContent)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 7, child: _buildMenuSection()),
                        const SizedBox(width: 18),
                        Expanded(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildCartPanel(),
                              const SizedBox(height: 18),
                              _buildOrdersSection(),
                            ],
                          ),
                        ),
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
              const SizedBox(height: 14),
              Text(
                'Kategori',
                style: AppTextStyles.displaySmall
                    .copyWith(color: scheme.onSurface),
              ),
              const SizedBox(height: 9),
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
                          onTap: () =>
                              setState(() => _selectedCategory = category),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),
            _SectionHeading(
              title: 'Menu hari ini',
              subtitle: 'Pilih menu dan atur ketersediaannya',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Tampilan grid',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => setState(() => _gridView = true),
                    style: IconButton.styleFrom(
                      backgroundColor: _gridView
                          ? scheme.primary.withOpacity(0.12)
                          : Colors.transparent,
                      foregroundColor:
                          _gridView ? scheme.primary : scheme.onSurfaceVariant,
                    ),
                    icon: const Icon(Icons.grid_view_rounded),
                  ),
                  IconButton(
                    tooltip: 'Tampilan list',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => setState(() => _gridView = false),
                    style: IconButton.styleFrom(
                      backgroundColor: !_gridView
                          ? scheme.primary.withOpacity(0.12)
                          : Colors.transparent,
                      foregroundColor:
                          !_gridView ? scheme.primary : scheme.onSurfaceVariant,
                    ),
                    icon: const Icon(Icons.view_list_rounded),
                  ),
                ],
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
            else if (_gridView)
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth < 350
                      ? 1
                      : constraints.maxWidth < 520
                          ? 2
                          : 3;
                  return GridView.builder(
                    itemCount: filtered.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 9,
                      mainAxisSpacing: 9,
                      mainAxisExtent: 164,
                    ),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return _MenuPreviewCard(
                        item: item,
                        onToggle: () => _toggleAvailability(item),
                        onAdd: () => _addToCart(item),
                      );
                    },
                  );
                },
              )
            else
              Column(
                children: [
                  for (final item in filtered)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _MenuListRow(
                        item: item,
                        onToggle: () => _toggleAvailability(item),
                        onAdd: () => _addToCart(item),
                      ),
                    ),
                ],
              ),
          ],
        );
      },
    );
  }

  Widget _buildCartPanel({bool inSheet = false}) {
    final scheme = Theme.of(context).colorScheme;
    return Consumer<OrderProvider>(
      builder: (context, provider, _) {
        final cart = provider.cart;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: _SectionHeading(
                      title: 'Tambah Pesanan',
                      subtitle: 'Pilih menu lalu cek pesanan',
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${provider.jumlahItemKeranjang} item',
                      style: AppTextStyles.label
                          .copyWith(color: scheme.onPrimaryContainer),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _CartTextField(
                controller: _kasirController,
                label: 'Nama kasir *',
                hint: 'Nama kasir',
                icon: Icons.badge_outlined,
              ),
              const SizedBox(height: 8),
              _CartTextField(
                controller: _namaController,
                label: 'Nama pelanggan (opsional)',
                hint: 'Nama pelanggan',
                icon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<String>(
                  showSelectedIcon: false,
                  style: SegmentedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    selectedBackgroundColor: scheme.primaryContainer,
                    selectedForegroundColor: scheme.onPrimaryContainer,
                  ),
                  segments: const [
                    ButtonSegment(
                      value: 'dine_in',
                      icon: Icon(Icons.table_restaurant_rounded, size: 18),
                      label: Text('Dine-in'),
                    ),
                    ButtonSegment(
                      value: 'takeaway',
                      icon: Icon(Icons.takeout_dining_rounded, size: 18),
                      label: Text('Take away'),
                    ),
                  ],
                  selected: {provider.jenisPesanan},
                  onSelectionChanged: (selection) {
                    final value = selection.first;
                    if (value == 'takeaway') _mejaController.clear();
                    provider.setJenisPesanan(value);
                  },
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (provider.jenisPesanan == 'dine_in') ...[
                    Expanded(
                      child: _CartTextField(
                        controller: _mejaController,
                        label: 'Meja',
                        hint: 'No. meja',
                        icon: Icons.table_restaurant_outlined,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      key: const ValueKey('dropdown_pembayaran'),
                      initialValue: _metodePembayaran,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Pembayaran',
                        prefixIcon: Icon(Icons.payments_outlined),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'cash', child: Text('Cash')),
                        DropdownMenuItem(value: 'qris', child: Text('QRIS')),
                        DropdownMenuItem(
                            value: 'transfer', child: Text('Transfer')),
                      ],
                      onChanged: (value) {
                        if (value != null)
                          setState(() => _metodePembayaran = value);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Expanded(
                    child: Text('Daftar pesanan',
                        style: AppTextStyles.titleMedium),
                  ),
                  if (cart.isNotEmpty)
                    TextButton(
                      onPressed: provider.kosongkanKeranjang,
                      child: const Text('Kosongkan'),
                    ),
                ],
              ),
              if (cart.isEmpty)
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.shopping_basket_outlined,
                          size: 28, color: scheme.onSurfaceVariant),
                      const SizedBox(height: 5),
                      Text('Belum ada menu dipilih',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: scheme.onSurfaceVariant)),
                      Text('Tekan tombol + pada menu untuk menambahkan.',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: scheme.onSurfaceVariant),
                          textAlign: TextAlign.center),
                    ],
                  ),
                )
              else
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: inSheet ? 260 : 235),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const ClampingScrollPhysics(),
                    itemCount: cart.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: scheme.outlineVariant),
                    itemBuilder: (context, index) {
                      final item = cart[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.namaMenu,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.titleSmall),
                                  const SizedBox(height: 2),
                                  Text(
                                      '${_formatRupiah(item.hargaSatuan)} × ${item.jumlah}',
                                      style: AppTextStyles.bodySmall.copyWith(
                                          color: scheme.onSurfaceVariant)),
                                  if (item.catatan?.isNotEmpty == true)
                                    Text('Catatan: ${item.catatan}',
                                        style: AppTextStyles.bodySmall.copyWith(
                                            color: scheme.onSurfaceVariant)),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Kurangi jumlah',
                              visualDensity: VisualDensity.compact,
                              onPressed: () =>
                                  provider.ubahJumlah(item.menuItemId, -1),
                              icon: const Icon(
                                  Icons.remove_circle_outline_rounded),
                            ),
                            Text('${item.jumlah}',
                                style: AppTextStyles.titleSmall),
                            IconButton(
                              tooltip: 'Tambah jumlah',
                              visualDensity: VisualDensity.compact,
                              onPressed: () =>
                                  provider.ubahJumlah(item.menuItemId, 1),
                              icon: const Icon(Icons.add_circle_rounded),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Expanded(
                      child: Text('Total', style: AppTextStyles.titleMedium)),
                  Text(_formatRupiah(provider.totalKeranjang),
                      style: AppTextStyles.priceLarge),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: provider.isSubmitting || provider.keranjangKosong
                      ? null
                      : () => _checkout(closeSheet: inSheet),
                  icon: provider.isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.point_of_sale_rounded),
                  label: Text(provider.isSubmitting
                      ? 'Menyimpan...'
                      : 'Checkout & Simpan Pesanan'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOrdersSection() {
    final scheme = Theme.of(context).colorScheme;
    return Consumer<OrderProvider>(
      builder: (context, provider, _) {
        final now = DateTime.now();
        final orders = provider.orders
            .where((order) {
              final created = order.createdAt.toLocal();
              return created.year == now.year &&
                  created.month == now.month &&
                  created.day == now.day;
            })
            .take(6)
            .toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeading(
              title: 'Pesanan Hari Ini',
              subtitle:
                  '${provider.ringkasanJumlahPesanan} pesanan • ${_formatRupiah(provider.ringkasanTotalPendapatan)}',
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
                  Icon(Icons.tips_and_updates_outlined,
                      color: scheme.secondary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tips: tekan lama pesanan untuk menghapusnya.',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: scheme.onSurfaceVariant),
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

  const _SectionHeading(
      {required this.title, required this.subtitle, this.trailing});

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
              Text(title,
                  style: AppTextStyles.displaySmall
                      .copyWith(color: scheme.onSurface)),
              const SizedBox(height: 3),
              Text(subtitle,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: scheme.onSurfaceVariant)),
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

class _MenuPreviewCard extends StatelessWidget {
  final MenuItem item;
  final VoidCallback onToggle;
  final VoidCallback onAdd;

  const _MenuPreviewCard({
    required this.item,
    required this.onToggle,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final available = item.tersedia;
    final itemIcon = item.tipe.toLowerCase() == 'minuman'
        ? Icons.local_cafe_rounded
        : Icons.restaurant_rounded;

    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: item.gambarUrl != null &&
                            item.gambarUrl!.trim().isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              item.gambarUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Center(
                                child: Icon(itemIcon,
                                    size: 34, color: scheme.primary),
                              ),
                            ),
                          )
                        : Center(
                            child:
                                Icon(itemIcon, size: 34, color: scheme.primary),
                          ),
                  ),
                  Positioned(
                    top: 5,
                    right: 5,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onToggle,
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 4),
                          decoration: BoxDecoration(
                            color: available
                                ? scheme.tertiaryContainer
                                : scheme.errorContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            available ? 'Tersedia' : 'Habis',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: available
                                  ? scheme.onTertiaryContainer
                                  : scheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 7),
          Text(item.nama,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  AppTextStyles.titleSmall.copyWith(color: scheme.onSurface)),
          Text(item.kategori,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall
                  .copyWith(color: scheme.onSurfaceVariant, fontSize: 10)),
          const SizedBox(height: 5),
          Row(
            children: [
              Expanded(
                child: Text(_formatRupiah(item.harga),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.price.copyWith(fontSize: 12)),
              ),
              _SmallActionButton(
                tooltip: 'Tambah ke pesanan',
                icon: Icons.add_rounded,
                color: const Color(0xFF218653),
                onPressed: available ? onAdd : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MenuListRow extends StatelessWidget {
  final MenuItem item;
  final VoidCallback onToggle;
  final VoidCallback onAdd;

  const _MenuListRow({
    required this.item,
    required this.onToggle,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final available = item.tersedia;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.nama,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.titleSmall),
                const SizedBox(height: 2),
                Text(item.kategori,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: scheme.onSurfaceVariant)),
                const SizedBox(height: 3),
                Text(_formatRupiah(item.harga), style: AppTextStyles.price),
              ],
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
              decoration: BoxDecoration(
                color: available
                    ? scheme.tertiaryContainer
                    : scheme.errorContainer,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                available ? 'Tersedia' : 'Habis',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: available
                      ? scheme.onTertiaryContainer
                      : scheme.onErrorContainer,
                ),
              ),
            ),
          ),
          const SizedBox(width: 5),
          _SmallActionButton(
            tooltip: 'Tambah ke pesanan',
            icon: Icons.add_rounded,
            color: const Color(0xFF218653),
            onPressed: available ? onAdd : null,
          ),
        ],
      ),
    );
  }
}

class _SmallActionButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  const _SmallActionButton({
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: 30,
        height: 30,
        child: IconButton.filled(
          onPressed: onPressed,
          tooltip: tooltip,
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          style: IconButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            disabledBackgroundColor:
                Theme.of(context).colorScheme.surfaceContainerHighest,
            disabledForegroundColor:
                Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          icon: Icon(icon, size: 17),
        ),
      ),
    );
  }
}

class _CartTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;

  const _CartTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 19),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      ),
    );
  }
}

class _RecentOrderCard extends StatefulWidget {
  final Order order;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  const _RecentOrderCard(
      {required this.order, required this.onTap, required this.onLongPress});

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
          border: Border.all(
              color: _hovered
                  ? scheme.primary.withOpacity(0.45)
                  : scheme.outlineVariant),
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
                  child: Icon(Icons.receipt_long_rounded,
                      color: scheme.primary, size: 20),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.titleSmall
                              .copyWith(color: scheme.onSurface)),
                      const SizedBox(height: 3),
                      Text(
                        '${order.items.length} item • ${_formatTime(order.createdAt)}',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: scheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
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
          const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(width: 12),
          Text(label,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: scheme.onSurfaceVariant)),
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
          Text(message,
              textAlign: TextAlign.center,
              style:
                  AppTextStyles.titleSmall.copyWith(color: scheme.onSurface)),
          if (detail != null) ...[
            const SizedBox(height: 5),
            Text(detail!,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall
                    .copyWith(color: scheme.onSurfaceVariant),
                maxLines: 3,
                overflow: TextOverflow.ellipsis),
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
