import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../menu_board/models/order.dart';
import '../../menu_board/providers/order_provider.dart';
import '../../theme/app_theme.dart';
import '../services/receipt_service.dart';
import 'order_status.dart';

void showOrderDetail(BuildContext context, Order order) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => OrderDetailSheet(order: order),
  );
}

class OrderDetailSheet extends StatefulWidget {
  final Order order;

  const OrderDetailSheet({super.key, required this.order});

  @override
  State<OrderDetailSheet> createState() => _OrderDetailSheetState();
}

class _OrderDetailSheetState extends State<OrderDetailSheet> {
  bool _sibuk = false;

  Order get order => widget.order;

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
        backgroundColor:
            sukses ? const Color(0xFFF0F8F1) : const Color(0xFFFFF2F2),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: sukses ? const Color(0xFFB8DCC0) : const Color(0xFFE8B8B8),
            width: 1,
          ),
        ),
      ),
    );
  }

  /// Menjalankan satu aksi status dengan tombol terkunci selama proses.
  Future<void> _jalankan(
    Future<void> Function() aksi,
    String pesanSukses,
  ) async {
    if (_sibuk) return;
    setState(() => _sibuk = true);

    try {
      await aksi();
      if (!mounted) return;
      _notifikasi(context, pesan: pesanSukses);
    } catch (error) {
      if (!mounted) return;
      _notifikasi(
        context,
        pesan: 'Gagal memperbarui status: $error',
        sukses: false,
      );
    } finally {
      if (mounted) setState(() => _sibuk = false);
    }
  }

  Future<void> _batalkan(Order sekarang) async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Batalkan pesanan?'),
        content: Text(
          'Pesanan ${sekarang.namaPelanggan ?? '-'} akan ditandai dibatalkan. '
          'Pelanggan akan melihat statusnya berubah.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Tidak'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Ya, batalkan'),
          ),
        ],
      ),
    );

    if (konfirmasi != true || !mounted) return;

    await _jalankan(
      () => batalkanPesanan(context, sekarang),
      'Pesanan dibatalkan.',
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
      if (!context.mounted) return;
      _notifikasi(
        context,
        pesan: 'Gagal menghapus pesanan: $error',
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

  Widget _info(IconData ikon, String teks, ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ikon, size: 14, color: scheme.primary),
          const SizedBox(width: 6),
          Text(teks, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Consumer<OrderProvider>(
      builder: (context, provider, _) {
        final currentOrder =
            provider.orders.where((item) => item.id == order.id).firstOrNull ??
                order;

        final sudahDibayar = currentOrder.statusPembayaran == 'dibayar';
        final langkah = langkahDari(currentOrder);
        final takeaway = apakahTakeaway(currentOrder);
        final labelMaju = labelAksi(langkah, takeaway: takeaway);

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Rincian Pesanan',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          currentOrder.namaPelanggan?.trim().isNotEmpty == true
                              ? currentOrder.namaPelanggan!.trim()
                              : 'Pelanggan',
                          style: TextStyle(
                            fontSize: 13,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
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
              const SizedBox(height: 6),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ===== STATUS PESANAN =====
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(12, 16, 12, 14),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHighest
                              .withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            if (langkah == LangkahPesanan.batal)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.cancel_rounded,
                                      color: AppColors.statusBatal,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Pesanan ini dibatalkan',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              PelacakStatus(
                                langkah: langkah,
                                takeaway: takeaway,
                              ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                if (langkah != LangkahPesanan.diterima)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: OutlinedButton.icon(
                                      onPressed: _sibuk
                                          ? null
                                          : () => _jalankan(
                                                () => mundurSatuLangkah(
                                                  context,
                                                  currentOrder,
                                                ),
                                                langkah == LangkahPesanan.batal
                                                    ? 'Pesanan diaktifkan kembali.'
                                                    : 'Status dikembalikan satu langkah.',
                                              ),
                                      style: OutlinedButton.styleFrom(
                                        minimumSize: const Size(0, 46),
                                      ),
                                      icon: const Icon(
                                        Icons.undo_rounded,
                                        size: 18,
                                      ),
                                      label: Text(
                                        langkah == LangkahPesanan.batal
                                            ? 'Aktifkan'
                                            : 'Kembali',
                                      ),
                                    ),
                                  ),
                                if (labelMaju != null)
                                  Expanded(
                                    child: FilledButton.icon(
                                      onPressed: _sibuk
                                          ? null
                                          : () => _jalankan(
                                                () => majuSatuLangkah(
                                                  context,
                                                  currentOrder,
                                                ),
                                                pesanSetelahMaju(
                                                  langkah,
                                                  takeaway: takeaway,
                                                ),
                                              ),
                                      style: FilledButton.styleFrom(
                                        minimumSize: const Size.fromHeight(46),
                                      ),
                                      icon: _sibuk
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : Icon(ikonAksi(langkah)),
                                      label: Text(labelMaju),
                                    ),
                                  )
                                else if (langkah == LangkahPesanan.diantar)
                                  Expanded(
                                    child: Container(
                                      height: 46,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: AppColors.statusSelesai
                                            .withValues(alpha: 0.14),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        takeaway
                                            ? 'Pesanan selesai diambil'
                                            : 'Pesanan selesai diantar',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.statusSelesai,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            if (langkah != LangkahPesanan.batal &&
                                langkah != LangkahPesanan.diantar)
                              TextButton(
                                onPressed:
                                    _sibuk ? null : () => _batalkan(currentOrder),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                child: const Text('Batalkan pesanan'),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ===== INFO RINGKAS =====
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _info(
                            takeaway
                                ? Icons.shopping_bag_outlined
                                : Icons.restaurant_rounded,
                            takeaway ? 'Takeaway' : 'Dine-in',
                            scheme,
                          ),
                          if (!takeaway)
                            _info(
                              Icons.event_seat_outlined,
                              'Meja ${currentOrder.meja ?? '-'}',
                              scheme,
                            ),
                          _info(
                            currentOrder.sumberPesanan == 'qr'
                                ? Icons.qr_code_2_rounded
                                : Icons.point_of_sale_rounded,
                            currentOrder.sumberPesanan == 'qr'
                                ? 'QR pelanggan'
                                : 'Kasir',
                            scheme,
                          ),
                          _info(
                            Icons.payments_outlined,
                            ReceiptService.metodeLabel(
                              currentOrder.metodePembayaran,
                            ),
                            scheme,
                          ),
                          if ((currentOrder.kasir ?? '').trim().isNotEmpty)
                            _info(
                              Icons.badge_outlined,
                              'Kasir: ${currentOrder.kasir}',
                              scheme,
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // ===== PEMBAYARAN =====
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Pembayaran sudah diterima'),
                        subtitle: Text(
                          sudahDibayar ? 'Sudah dibayar' : 'Belum dibayar',
                        ),
                        value: sudahDibayar,
                        onChanged: (value) => _ubahPembayaran(context, value),
                      ),
                      const SizedBox(height: 8),

                      // ===== ITEM =====
                      const Text(
                        'Detail item',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (var i = 0; i < currentOrder.items.length; i++) ...[
                        if (i > 0) const Divider(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    currentOrder.items[i].namaMenu,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '${currentOrder.items[i].jumlah} × '
                                    'Rp${_rupiah(currentOrder.items[i].hargaSatuan)}',
                                    style: TextStyle(
                                      color: scheme.onSurfaceVariant,
                                      fontSize: 12,
                                    ),
                                  ),
                                  if ((currentOrder.items[i].catatan ?? '')
                                      .trim()
                                      .isNotEmpty)
                                    Text(
                                      'Catatan: ${currentOrder.items[i].catatan}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Rp${_rupiah(currentOrder.items[i].subtotal)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
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