import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../l10n/bahasa.dart';
import '../../menu_board/models/order.dart';

class ReceiptService {
  ReceiptService._();

  static const String _namaToko = 'Sapuangin Coffee & Farm';
  static const String _pathLogo = 'assets/images/logo.png';

  static String metodeLabel(String value) {
    switch (value) {
      case 'qris':
        return 'QRIS';
      case 'transfer':
        return 'Transfer';
      default:
        return 'Cash';
    }
  }

  static String _rupiah(int angka) => angka
      .toString()
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.');

  /// Mencetak SATU struk untuk pelanggan.
  /// Bahasa struk mengikuti bahasa yang dipilih di Pengaturan.
  static Future<void> cetakStruk(Order order) async {
    final logo = await _muatLogo();
    final pdf = pw.Document();

    pdf.addPage(_halaman(order, logo));

    await Printing.layoutPdf(
      onLayout: (_) async => pdf.save(),
    );
  }

  // ------------------------------------------------------------
  // Data pendukung
  // ------------------------------------------------------------

  /// Logo opsional. Kalau file belum ada, struk tetap tercetak tanpa logo.
  static Future<pw.MemoryImage?> _muatLogo() async {
    try {
      final data = await rootBundle.load(_pathLogo);
      return pw.MemoryImage(data.buffer.asUint8List());
    } catch (e) {
      debugPrint('Logo struk gagal dimuat ($_pathLogo): $e');
      return null;
    }
  }

  static String _tanggal(Order order) {
    final w = order.createdAt.toLocal();
    return '${w.day.toString().padLeft(2, '0')}/'
        '${w.month.toString().padLeft(2, '0')}/'
        '${w.year} '
        '${w.hour.toString().padLeft(2, '0')}:'
        '${w.minute.toString().padLeft(2, '0')}';
  }

  /// Kode pendek pesanan (4 karakter pertama id).
  static String _kode(Order order) {
    final id = order.id;
    return id.length >= 4 ? id.substring(0, 4).toUpperCase() : id;
  }

  // ------------------------------------------------------------
  // Komponen kecil
  // ------------------------------------------------------------

  static pw.Widget _teks(
    String isi, {
    double ukuran = 9,
    bool tebal = false,
  }) =>
      pw.Text(
        isi,
        style: pw.TextStyle(
          fontSize: ukuran,
          fontWeight: tebal ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      );

  static pw.Widget _baris(
    String kiri,
    String kanan, {
    double ukuran = 9,
    bool tebal = false,
  }) =>
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(child: _teks(kiri, ukuran: ukuran, tebal: tebal)),
          _teks(kanan, ukuran: ukuran, tebal: tebal),
        ],
      );

  static pw.Widget _kop(pw.MemoryImage? logo) => pw.Column(
        children: [
          if (logo != null) ...[
            pw.Center(child: pw.Image(logo, height: 40)),
            pw.SizedBox(height: 4),
          ],
          pw.Center(child: _teks(_namaToko, ukuran: 12, tebal: true)),
        ],
      );

  static pw.Widget _barisItem(OrderItem item) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 3),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _teks('${item.jumlah}x '),
                pw.Expanded(child: _teks(item.namaMenu)),
                _teks('Rp${_rupiah(item.subtotal)}'),
              ],
            ),
            if (item.catatan != null && item.catatan!.isNotEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.only(left: 14),
                child: pw.Text(
                  '${tr('Catatan')}: ${item.catatan}',
                  style: pw.TextStyle(
                    fontSize: 7,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      );

  // ------------------------------------------------------------
  // Halaman struk
  // ------------------------------------------------------------

  static pw.Page _halaman(Order order, pw.MemoryImage? logo) {
    final takeaway = order.jenisPesanan == 'takeaway';
    final sudahBayar = order.statusPembayaran == 'dibayar';
    final kasir = (order.kasir ?? '').trim();
    final pelanggan = (order.namaPelanggan ?? '').trim();

    return pw.Page(
      pageFormat: PdfPageFormat.roll80,
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _kop(logo),
          pw.Center(child: _teks(_tanggal(order), ukuran: 8)),
          pw.SizedBox(height: 8),
          _teks('${tr('No')}: #${_kode(order)}'),
          _teks('${tr('Pelanggan')}: ${pelanggan.isEmpty ? '-' : pelanggan}'),
          _teks('${tr('Jenis')}: ${takeaway ? 'Takeaway' : 'Dine-in'}'),
          if (!takeaway) _teks('${tr('Meja')}: ${order.meja ?? '-'}'),
          _teks('${tr('Kasir')}: ${kasir.isEmpty ? '-' : kasir}'),
          _teks('${tr('Bayar')}: ${metodeLabel(order.metodePembayaran)}'),
          _teks(
            '${tr('Status')}: '
            '${sudahBayar ? tr('Sudah dibayar') : tr('Belum dibayar')}',
          ),
          pw.Divider(),
          ...order.items.map(_barisItem),
          pw.Divider(),
          if (order.diskon > 0) ...[
            _baris(tr('Harga asli'), 'Rp${_rupiah(order.subtotalAsli)}'),
            _baris(
              (order.diskonLabel == null || order.diskonLabel!.isEmpty)
                  ? tr('Diskon')
                  : order.diskonLabel!,
              '-Rp${_rupiah(order.diskon)}',
            ),
            pw.SizedBox(height: 2),
          ],
          _baris(
            'TOTAL',
            'Rp${_rupiah(order.totalHarga)}',
            ukuran: 10,
            tebal: true,
          ),
          pw.SizedBox(height: 12),
          pw.Center(
            child: _teks(
              tr('Selamat menikmati hidangan kami!'),
              ukuran: 9,
              tebal: true,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Center(
            child: _teks(
              tr('Semoga bahagia selalu (^_^)/'),
              ukuran: 9,
            ),
          ),
        ],
      ),
    );
  }
}