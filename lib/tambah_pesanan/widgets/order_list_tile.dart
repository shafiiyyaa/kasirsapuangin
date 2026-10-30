import 'package:flutter/material.dart';

import '../../menu_board/models/order.dart';
import '../../theme/app_theme.dart';
import 'order_status.dart';

class OrderListTile extends StatelessWidget {
  final Order order;
  final VoidCallback? onTap;

  const OrderListTile({
    super.key,
    required this.order,
    this.onTap,
  });

  String _jenisPesananLabel() {
    return order.jenisPesanan == 'takeaway'
        ? 'Takeaway'
        : 'Dine-in';
  }

  @override
  Widget build(BuildContext context) {
    final jam =
        '${order.createdAt.hour.toString().padLeft(2, '0')}:'
        '${order.createdAt.minute.toString().padLeft(2, '0')}';

    final namaTampil =
        (order.namaPelanggan?.isNotEmpty ?? false)
            ? order.namaPelanggan!
            : 'Pelanggan';

    final sumber = order.sumberPesanan == 'qr' ? 'QR' : 'Kasir';
    final sudahBayar = order.statusPembayaran == 'dibayar';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 6,
        ),
        title: Text(namaTampil, style: AppTextStyles.bodyLarge),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${order.items.length} item • $jam',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 3),
              Text(
                '$sumber • ${_jenisPesananLabel()}'
                '${order.meja == null || order.meja!.isEmpty ? '' : ' • Meja ${order.meja}'}',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 3),
              Text(
                sudahBayar ? 'Sudah dibayar' : 'Belum dibayar',
                style: AppTextStyles.bodySmall.copyWith(
                  color: sudahBayar
                      ? Colors.green
                      : Colors.orange.shade800,
                ),
              ),
            ],
          ),
        ),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _formatRupiah(order.totalHarga),
              style: AppTextStyles.price,
            ),
            const SizedBox(height: 4),
            StatusPill(order: order),
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
    final posisiDariKanan = str.length - i;
    buffer.write(str[i]);

    if (posisiDariKanan > 1 && posisiDariKanan % 3 == 1) {
      buffer.write('.');
    }
  }

  return 'Rp$buffer';
}