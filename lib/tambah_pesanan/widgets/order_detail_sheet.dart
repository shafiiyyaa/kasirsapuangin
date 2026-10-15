import 'package:flutter/material.dart';

import '../../menu_board/models/order.dart';
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
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Atas nama: ${order.namaPelanggan ?? '-'}'),
          Text('Meja: ${order.meja ?? '-'}'),
          Text('Pembayaran: ${ReceiptService.metodeLabel(order.metodePembayaran)}'),
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