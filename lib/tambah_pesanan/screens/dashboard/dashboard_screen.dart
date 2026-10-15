import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../menu_board/providers/menu_provider.dart';
import '../../../menu_board/providers/order_provider.dart';
import '../../../theme/app_theme.dart';
import '../../widgets/order_detail_sheet.dart';
import '../../widgets/order_list_tile.dart';
import '../../widgets/stat_card.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
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
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: jumlahKolom == 4 ? 1.3 : 1.6,
                  children: [
                    StatCard(
                      label: 'Pesanan Hari Ini',
                      value: '${orderProvider.ringkasanJumlahPesanan}',
                      icon: Icons.receipt_long_outlined,
                    ),
                    StatCard(
                      label: 'Pendapatan Hari Ini',
                      value:
                          _formatRupiah(orderProvider.ringkasanTotalPendapatan),
                      icon: Icons.payments_outlined,
                    ),
                    StatCard(
                      label: 'Menu Tersedia',
                      value: '$jumlahMenuTersedia',
                      icon: Icons.restaurant_menu_outlined,
                    ),
                    StatCard(
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