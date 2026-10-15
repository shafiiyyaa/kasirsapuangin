import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../menu_board/models/order.dart';
import '../../menu_board/providers/order_provider.dart';
import '../services/receipt_service.dart';

void showOrderDetail(BuildContext context, Order order) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => OrderDetailSheet(order: order),
  );
}

class OrderDetailSheet extends StatelessWidget {
  final Order order;
  const OrderDetailSheet({super.key, required this.order});

  String _rupiah(int n) =>
      n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.');

  Future<void> _hapus(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus pesanan?'),
        content: Text(
          'Pesanan atas nama ${order.namaPelanggan ?? "-"} '
          '(${_rupiah(order.totalHarga)}) akan dihapus permanen. Lanjutkan?',
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
    );
    if (ok != true || !context.mounted) return;

    // Context dipakai SEBELUM async gap, hasilnya disimpan dulu.
    final provider = context.read<OrderProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await provider.hapusPesanan(order.id);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Gagal menghapus pesanan: $e')),
      );
      return;
    }
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final items = order.items;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Rincian Pesanan',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              IconButton(
                icon: const Icon(Icons.print_outlined),
                tooltip: 'Cetak Struk',
                onPressed: () => ReceiptService.cetakStruk(order),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                tooltip: 'Hapus Pesanan',
                onPressed: () => _hapus(context),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Atas nama: ${order.namaPelanggan ?? '-'}'),
          Text('Meja: ${order.meja ?? '-'}'),
          Text(
              'Pembayaran: ${ReceiptService.metodeLabel(order.metodePembayaran)}'),
          Text('Status: ${order.status.label}'),
          const Divider(height: 24),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('(tidak ada rincian item)'),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final it = items[i];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text('${it.jumlah}x ${it.namaMenu}'),
                    subtitle: (it.catatan == null || it.catatan!.isEmpty)
                        ? null
                        : Text(it.catatan!),
                    trailing: Text('Rp${_rupiah(it.hargaSatuan * it.jumlah)}'),
                  );
                },
              ),
            ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Rp${_rupiah(order.totalHarga)}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}