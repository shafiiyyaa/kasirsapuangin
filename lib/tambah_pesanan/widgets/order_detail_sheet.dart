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

  void _notifikasi(
    BuildContext context, {
    required String pesan,
    bool sukses = true,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              sukses
                  ? Icons.check_circle_outline_rounded
                  : Icons.error_outline_rounded,
              color: sukses
                  ? const Color(0xFF347A45)
                  : const Color(0xFFB64D4D),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                pesan,
                style: TextStyle(
                  color: sukses
                      ? const Color(0xFF285B3A)
                      : const Color(0xFF963D3D),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: sukses
            ? const Color(0xFFF0F8F1)
            : const Color(0xFFFFF2F2),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: sukses
                ? const Color(0xFFB8DCC0)
                : const Color(0xFFE8B8B8),
            width: 1,
          ),
        ),
      ),
    );
  }

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

      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: const Text(
            'Pesanan berhasil dihapus.',
            style: TextStyle(color: Color(0xFF285B3A)),
          ),
          backgroundColor: const Color(0xFFF0F8F1),
          behavior: SnackBarBehavior.floating,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFB8DCC0)),
          ),
        ),
      );
    } catch (error) {
      _notifikasi(
        context,
        pesan: 'Gagal menghapus pesanan: $error',
        sukses: false,
      );
    }
  }

  Future<void> _ubahPengantaran(
    BuildContext context,
    bool sudahDiantar,
  ) async {
    final provider = context.read<OrderProvider>();

    try {
      await provider.updateStatusPengantaran(
        order.id,
        sudahDiantar: sudahDiantar,
      );

      if (!context.mounted) return;

      _notifikasi(
        context,
        pesan: sudahDiantar
            ? 'Pesanan berhasil ditandai sudah diantar.'
            : 'Status pengantaran berhasil dikembalikan.',
      );
    } catch (error) {
      if (!context.mounted) return;

      _notifikasi(
        context,
        pesan: 'Gagal memperbarui pengantaran: $error',
        sukses: false,
      );
    }
  }

  Future<void> _ubahPembayaran(
    BuildContext context,
    bool sudahDibayar,
  ) async {
    final provider = context.read<OrderProvider>();

    try {
      await provider.updateStatusPembayaran(
        order.id,
        sudahDibayar: sudahDibayar,
      );

      if (!context.mounted) return;

      _notifikasi(
        context,
        pesan: sudahDibayar
            ? 'Pembayaran berhasil ditandai sudah diterima.'
            : 'Status pembayaran berhasil dikembalikan.',
      );
    } catch (error) {
      if (!context.mounted) return;

      _notifikasi(
        context,
        pesan: 'Gagal memperbarui pembayaran: $error',
        sukses: false,
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
                    onPressed: () async {
                      try {
                        await ReceiptService.cetakStruk(currentOrder);

                        if (!context.mounted) return;

                        _notifikasi(
                          context,
                          pesan: 'Proses cetak struk selesai.',
                        );
                      } catch (error) {
                        if (!context.mounted) return;

                        _notifikasi(
                          context,
                          pesan: 'Gagal mencetak struk: $error',
                          sukses: false,
                        );
                      }
                    },
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
                    tooltip: 'Tutup',
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
              Text(
                'Sumber: ${currentOrder.sumberPesanan == 'qr' ? 'QR pelanggan' : 'Kasir'}',
              ),
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
                onChanged: (value) => _ubahPembayaran(context, value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Pesanan sudah diantar'),
                subtitle: Text(
                  sudahDiantar ? 'Sudah diantar' : 'Belum diantar',
                ),
                value: sudahDiantar,
                onChanged: (value) => _ubahPengantaran(context, value),
              ),
              const SizedBox(height: 12),
              const Text(
                'Detail item',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: currentOrder.items.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 16),
                  itemBuilder: (context, index) {
                    final item = currentOrder.items[index];

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.namaMenu,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${item.jumlah} × Rp${_rupiah(item.hargaSatuan)}',
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 12,
                                ),
                              ),
                              if ((item.catatan ?? '').trim().isNotEmpty)
                                Text(
                                  'Catatan: ${item.catatan}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Rp${_rupiah(item.subtotal)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const Divider(height: 24),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    'Rp${_rupiah(currentOrder.totalHarga)}',
                    style: const TextStyle(
                      fontSize: 17,
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