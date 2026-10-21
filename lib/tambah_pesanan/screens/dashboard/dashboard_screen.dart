import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../menu_board/models/order.dart';
import '../../../menu_board/providers/menu_provider.dart';
import '../../../menu_board/providers/order_provider.dart';
import '../../../theme/app_theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/order_detail_sheet.dart';
import '../../widgets/order_list_tile.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _muatData());
  }

  Future<void> _muatData() async {
    final menuProvider = context.read<MenuProvider>();
    final orderProvider = context.read<OrderProvider>();
    await Future.wait([
      menuProvider.loadMenu(),
      orderProvider.loadRingkasanHariIni(),
      orderProvider.loadOrders(),
    ]);
  }

  Future<bool> _konfirmasiHapus(Order order) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Hapus pesanan?'),
            content: Text(
              'Pesanan atas nama ${order.namaPelanggan ?? "-"} '
              '(${_formatRupiah(order.totalHarga)}) akan dihapus permanen. '
              'Lanjutkan?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Hapus'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _hapusPesanan(Order order) async {
    final ok = await _konfirmasiHapus(order);
    if (!ok || !mounted) return;

    final provider = context.read<OrderProvider>();
    final messenger = ScaffoldMessenger.of(context);

    try {
      await provider.hapusPesanan(order.id);
      messenger.showSnackBar(
        const SnackBar(content: Text('Pesanan dihapus')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Gagal menghapus pesanan: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      currentIndex: 0, // 0 = Beranda
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Dashboard'),
          leading: IconButton(
            icon: const Icon(Icons.menu),
            tooltip: 'Buka menu',
            onPressed: () => AppScaffold.openMenu(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Muat ulang',
              onPressed: _muatData,
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _muatData,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            children: [
              Consumer2<MenuProvider, OrderProvider>(
                builder: (context, menuProvider, orderProvider, _) {
                  final jumlahMenuTersedia =
                      menuProvider.items.where((e) => e.tersedia).length;

                  final lebarLayar = MediaQuery.sizeOf(context).width;
                  final jumlahKolom = lebarLayar >= 700 ? 4 : 2;

                  return GridView.count(
                    crossAxisCount: jumlahKolom,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    // Tinggi kartu ditetapkan langsung (pixel), gak lagi ikut
                    // rasio lebar layar -> gak akan kepotong di layar manapun.
                    mainAxisExtent: jumlahKolom == 4 ? 84 : 76,
                    children: [
                      _StatMini(
                        label: 'Pesanan Hari Ini',
                        value: '${orderProvider.ringkasanJumlahPesanan}',
                        icon: Icons.receipt_long_outlined,
                      ),
                      _StatMini(
                        label: 'Pendapatan Hari Ini',
                        value: _formatRupiah(
                            orderProvider.ringkasanTotalPendapatan),
                        icon: Icons.payments_outlined,
                      ),
                      _StatMini(
                        label: 'Menu Tersedia',
                        value: '$jumlahMenuTersedia',
                        icon: Icons.restaurant_menu_outlined,
                      ),
                      _StatMini(
                        label: 'Status',
                        value: menuProvider.isLoading ||
                                orderProvider.isLoadingRingkasan
                            ? 'Memuat...'
                            : 'Terkini',
                        icon: Icons.sync_outlined,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              Text('Pesanan Terbaru', style: AppTextStyles.displayMedium),
              const SizedBox(height: 10),
              Consumer<OrderProvider>(
                builder: (context, orderProvider, _) {
                  if (orderProvider.isLoadingOrders &&
                      orderProvider.orders.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (orderProvider.ordersError != null &&
                      orderProvider.orders.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        orderProvider.ordersError!,
                        style: AppTextStyles.bodyMedium,
                      ),
                    );
                  }

                  if (orderProvider.orders.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'Belum ada pesanan.',
                        style: AppTextStyles.bodyMedium,
                      ),
                    );
                  }

                  final terbaru = orderProvider.orders.take(5).toList();

                  return Column(
                    children: terbaru
                        .map(
                          (o) => InkWell(
                            onTap: () => showOrderDetail(context, o),
                            onLongPress: () => _hapusPesanan(o),
                            borderRadius: BorderRadius.circular(12),
                            child: OrderListTile(order: o),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kartu statistik ringkas.
///
/// Anti-overflow: angka dibungkus Flexible + FittedBox, jadi otomatis
/// mengecil kalau ruangnya sempit — gak akan pernah "BOTTOM OVERFLOWED".
class _StatMini extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatMini({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, style: AppTextStyles.priceLarge),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatRupiah(int angka) {
  final str = angka.toString();
  final buffer = StringBuffer();
  for (int i = 0; i < str.length; i++) {
    final posFromRight = str.length - i;
    buffer.write(str[i]);
    if (posFromRight > 1 && posFromRight % 3 == 1) {
      buffer.write('.');
    }
  }
  return 'Rp$buffer';
}