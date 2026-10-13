import 'package:flutter/material.dart';

import '../../menu_board/models/order.dart';
import '../../theme/app_theme.dart';

/// Baris ringkasan satu pesanan — dipakai di Dashboard (pesanan terbaru)
/// dan nanti di layar Riwayat Pesanan.
class OrderListTile extends StatelessWidget {
  final Order order;
  final VoidCallback? onTap;

  const OrderListTile({super.key, required this.order, this.onTap});

  Color _statusColor() {
    switch (order.status) {
      case OrderStatus.baru:
        return AppColors.statusBaru;
      case OrderStatus.diproses:
        return AppColors.statusDiproses;
      case OrderStatus.selesai:
        return AppColors.statusSelesai;
      case OrderStatus.batal:
        return AppColors.statusBatal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final jam =
        '${order.createdAt.hour.toString().padLeft(2, '0')}:${order.createdAt.minute.toString().padLeft(2, '0')}';
    final namaTampil = (order.namaPelanggan?.isNotEmpty ?? false)
        ? order.namaPelanggan!
        : 'Pelanggan';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        title: Text(namaTampil, style: AppTextStyles.bodyLarge),
        subtitle: Text(
          '${order.items.length} item • $jam',
          style: AppTextStyles.bodySmall,
        ),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_formatRupiah(order.totalHarga), style: AppTextStyles.price),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _statusColor().withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                order.status.label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: _statusColor(),
                  fontWeight: FontWeight.w600,
                ),
              ),
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