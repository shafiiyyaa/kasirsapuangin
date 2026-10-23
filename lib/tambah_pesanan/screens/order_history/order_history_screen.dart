import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../menu_board/models/order.dart';
import '../../../menu_board/providers/order_provider.dart';
import '../../../theme/app_theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/order_detail_sheet.dart';
import '../../widgets/order_list_tile.dart';

const _hariPendek = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
const _bulan = [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().loadOrders();
    });
  }

  String _rupiah(int n) => n
      .toString()
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.');

  String _labelHari(DateTime d) =>
      '${_hariPendek[d.weekday - 1]}, ${d.day} ${_bulan[d.month - 1]} ${d.year}';

  Future<bool> _konfirmasiHapus(Order order) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Hapus pesanan?'),
            content: Text(
              'Pesanan atas nama ${order.namaPelanggan ?? "-"} '
              '(${_rupiah(order.totalHarga)}) akan dihapus permanen. '
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
    return Scaffold(
      appBar: AppScaffold.isWide(context) ? null : AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Riwayat Pesanan'),
        leading: AppScaffold.isWide(context) ? null : IconButton(
          icon: const Icon(Icons.menu),
          tooltip: 'Buka menu',
          onPressed: () => AppScaffold.openMenu(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat ulang',
            onPressed: () => context.read<OrderProvider>().loadOrders(),
          ),
        ],
      ),
      body: Consumer<OrderProvider>(
        builder: (context, orderProvider, _) {
          if (orderProvider.orders.isEmpty) {
            return const Center(child: Text('Belum ada pesanan.'));
          }

          final bulans = _kelompokkan(orderProvider.orders);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            children: [
              for (final bulan in bulans) ...[
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.forestGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${_bulan[bulan.bulan.month - 1]} ${bulan.bulan.year}',
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        '${bulan.jumlah} pesanan • ${_rupiah(bulan.pendapatan)}',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                for (final hari in bulan.hari) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _labelHari(hari.hari),
                            style: AppTextStyles.bodyLarge
                                .copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Text(
                          '${hari.jumlah} pesanan • ${_rupiah(hari.pendapatan)}',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  for (final o in hari.orders)
                    InkWell(
                      onTap: () => showOrderDetail(context, o),
                      onLongPress: () => _hapusPesanan(o),
                      borderRadius: BorderRadius.circular(12),
                      child: OrderListTile(order: o),
                    ),
                ],
              ],
            ],
          );
        },
      ),
    );
  }

  /// Kelompokkan pesanan: per bulan → per hari. Orders sudah urut
  /// terbaru dulu dari fetchOrders, jadi hasilnya ikut urut ke bawah.
  List<_BulanBucket> _kelompokkan(List<Order> orders) {
    final hariMap = <String, _HariBucket>{};
    final bulanMap = <String, _BulanBucket>{};
    final urutanBulan = <String>[];

    for (final o in orders) {
      final t = o.createdAt.toLocal();
      final hariKey = '${t.year}-${t.month}-${t.day}';
      final bulanKey = '${t.year}-${t.month}';

      final hari = hariMap.putIfAbsent(
        hariKey,
        () => _HariBucket(DateTime(t.year, t.month, t.day)),
      );
      hari.orders.add(o);

      final bulan = bulanMap.putIfAbsent(bulanKey, () {
        urutanBulan.add(bulanKey);
        return _BulanBucket(DateTime(t.year, t.month));
      });
      if (!bulan.hari.contains(hari)) bulan.hari.add(hari);
    }

    return [for (final k in urutanBulan) bulanMap[k]!];
  }
}

class _HariBucket {
  final DateTime hari;
  final List<Order> orders = [];

  _HariBucket(this.hari);

  int get jumlah => orders.length;
  // Pendapatan tidak menghitung pesanan yang dibatalkan.
  int get pendapatan => orders
      .where((o) => o.status.name != 'batal')
      .fold(0, (sum, o) => sum + o.totalHarga);
}

class _BulanBucket {
  final DateTime bulan;
  final List<_HariBucket> hari = [];

  _BulanBucket(this.bulan);

  int get jumlah => hari.fold(0, (sum, h) => sum + h.jumlah);
  int get pendapatan => hari.fold(0, (sum, h) => sum + h.pendapatan);
}
