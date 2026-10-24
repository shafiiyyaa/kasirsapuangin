
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

  String _rupiah(int angka) => angka
      .toString()
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.');

  Future<void> _hapus(BuildContext context) async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus pesanan?'),
        content: Text(
          'Pesanan ${order.namaPelanggan ?? '-'} '
          '(Rp${_rupiah(order.totalHarga)}) akan dihapus permanen. '
          'Lanjutkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (konfirmasi != true || !context.mounted) return;

    final provider = context.read<OrderProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await provider.hapusPesanan(order.id);

      if (navigator.mounted) navigator.pop();
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Gagal menghapus pesanan: $error')),
      );
    }
  }

  Future<void> _ubahPengantaran(
    BuildContext context,
    bool sudahDiantar,
  ) async {
    final provider = context.read<OrderProvider>();
    final messenger = ScaffoldMessenger.of(context);

    try {
      await provider.updateStatusPengantaran(
        order.id,
        sudahDiantar: sudahDiantar,
      );

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            sudahDiantar
                ? 'Pesanan ditandai sudah diantar.'
                : 'Status pengantaran dikembalikan.',
          ),
        ),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Gagal memperbarui pengantaran: $error'),
        ),
      );
    }
  }

  Future<void> _ubahPembayaran(
    BuildContext context,
    bool sudahDibayar,
  ) async {
    final provider = context.read<OrderProvider>();
    final messenger = ScaffoldMessenger.of(context);

    try {
      await provider.updateStatusPembayaran(
        order.id,
        sudahDibayar: sudahDibayar,
      );

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            sudahDibayar
                ? 'Pembayaran ditandai sudah diterima.'
                : 'Status pembayaran dikembalikan.',
          ),
        ),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Gagal memperbarui pembayaran: $error'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderProvider>(
      builder: (context, provider, _) {
        final currentOrder = provider.orders
            .where((item) => item.id == order.id)
            .firstOrNull ?? order;

        final sudahDiantar =
            currentOrder.statusPengantaran == 'sudah_diantar';
        final sudahDibayar =
            currentOrder.statusPembayaran == 'dibayar';

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Rincian Pesanan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cetak struk',
                    icon: const Icon(Icons.print_outlined),
                    onPressed: () =>
                        ReceiptService.cetakStruk(currentOrder),
                  ),
                  IconButton(
                    tooltip: 'Hapus pesanan',
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                    ),
                    onPressed: () => _hapus(context),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text('Pelanggan: ${currentOrder.namaPelanggan ?? '-'}'),
              Text(
                'Jenis: ${currentOrder.jenisPesanan == 'takeaway' ? 'Takeaway' : 'Dine-in'}',
              ),
              if (currentOrder.jenisPesanan != 'takeaway')
                Text('Meja: ${currentOrder.meja ?? '-'}'),
              Text('Sumber: ${currentOrder.sumberPesanan == 'qr' ? 'QR pelanggan' : 'Kasir'}'),
              Text('Kasir: ${currentOrder.kasir ?? '-'}'),
              Text(
                'Metode pembayaran: '
                '${ReceiptService.metodeLabel(currentOrder.metodePembayaran)}',
              ),
              Text('Status pesanan: ${currentOrder.status.label}'),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Pembayaran sudah diterima'),
                subtitle: Text(
                  sudahDibayar ? 'Sudah dibayar' : 'Belum dibayar',
                ),
                value: sudahDibayar,
                onChanged: (value) =>
                    _ubahPembayaran(context, value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Pesanan sudah diantar'),
                subtitle: Text(
                  sudahDiantar ? 'Sudah diantar' : 'Belum diantar',
                ),
                value: sudahDiantar,
                onChanged: (value) =>
                    _ubahPengantaran(context, value),
              ),
              const Divider(height: 24),
              if (currentOrder.items.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('(tidak ada rincian item)'),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: currentOrder.items.length,
                    itemBuilder: (_, index) {
                      final item = currentOrder.items[index];

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: Text(
                          '${item.jumlah}x ${item.namaMenu}',
                        ),
                        subtitle: (item.catatan == null ||
                                item.catatan!.isEmpty)
                            ? null
                            : Text(item.catatan!),
                        trailing: Text(
                          'Rp${_rupiah(item.subtotal)}',
                        ),
                      );
                    },
                  ),
                ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Rp${_rupiah(currentOrder.totalHarga)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
