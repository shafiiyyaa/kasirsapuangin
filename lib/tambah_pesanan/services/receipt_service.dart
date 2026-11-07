import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../menu_board/models/divisi.dart.dart';
import '../../menu_board/models/order.dart';
import '../../menu_board/services/supabase_service.dart';

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

  /// Cetak sekaligus: 2 struk pembayaran (pelanggan + arsip kasir)
  /// dan 1 struk dapur untuk tiap divisi yang ada itemnya
  /// (makanan, minuman, snack).
  static Future<void> cetakStruk(Order order) async {
    final logo = await _muatLogo();
    final peta = await _petaDivisi();
    final pdf = pw.Document();

    pdf.addPage(_halamanPembayaran(order, logo, untuk: 'STRUK PELANGGAN'));
    pdf.addPage(_halamanPembayaran(order, logo, untuk: 'ARSIP KASIR'));

    for (final divisi in [Divisi.makanan, Divisi.minuman, Divisi.snack]) {
      final items =
          order.items.where((i) => _divisiItem(i, peta) == divisi).toList();
      if (items.isEmpty) continue;
      pdf.addPage(_halamanDapur(order, logo, divisi, items));
    }

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

  /// Peta id menu -> divisi, diambil dari data menu terkini.
  static Future<Map<String, Divisi>> _petaDivisi() async {
    try {
      final menu = await SupabaseService.fetchMenuItems();
      return {
        for (final m in menu)
          m.id: divisiDari(kategori: m.kategori, tipe: m.tipe),
      };
    } catch (_) {
      return {};
    }
  }

  /// Item yang divisinya tidak dikenal (menu sudah dihapus / kategori
  /// tidak cocok) dialihkan ke dapur Makanan supaya tidak hilang dari struk.
  static Divisi _divisiItem(OrderItem item, Map<String, Divisi> peta) {
    final d = peta[item.menuItemId];
    if (d == null || d == Divisi.lainnya) return Divisi.makanan;
    return d;
  }

  static String _tanggal(Order order) {
    final w = order.createdAt.toLocal();
    return '${w.day.toString().padLeft(2, '0')}/'
        '${w.month.toString().padLeft(2, '0')}/'
        '${w.year} '
        '${w.hour.toString().padLeft(2, '0')}:'
        '${w.minute.toString().padLeft(2, '0')}';
  }

  /// Kode pendek pesanan supaya struk pembayaran dan struk dapur mudah dicocokkan.
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

  // ------------------------------------------------------------
  // Struk pembayaran (pelanggan + arsip kasir)
  // ------------------------------------------------------------

  static pw.Page _halamanPembayaran(
    Order order,
    pw.MemoryImage? logo, {
    required String untuk,
  }) {
    final jenis = order.jenisPesanan == 'takeaway' ? 'Takeaway' : 'Dine-in';
    final statusBayar =
        order.statusPembayaran == 'dibayar' ? 'Sudah dibayar' : 'Belum dibayar';

    return pw.Page(
      pageFormat: PdfPageFormat.roll80,
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _kop(logo),
          pw.Center(child: _teks(_tanggal(order), ukuran: 8)),
          pw.Center(child: _teks(untuk, ukuran: 8, tebal: true)),
          pw.SizedBox(height: 8),
          _teks('No: #${_kode(order)}'),
          _teks('Pelanggan: ${order.namaPelanggan ?? '-'}'),
          _teks('Jenis: $jenis'),
          if (order.jenisPesanan != 'takeaway')
            _teks('Meja: ${order.meja ?? '-'}'),
          _teks(
            'Kasir: ${order.kasir?.isNotEmpty == true ? order.kasir! : '-'}',
          ),
          _teks('Bayar: ${metodeLabel(order.metodePembayaran)}'),
          _teks('Status: $statusBayar'),
          pw.Divider(),
          ...order.items.map(_barisItem),
          pw.Divider(),
          if (order.diskon > 0) ...[
            _baris('Harga asli', 'Rp${_rupiah(order.subtotalAsli)}'),
            _baris(
              (order.diskonLabel == null || order.diskonLabel!.isEmpty)
                  ? 'Diskon'
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
          pw.SizedBox(height: 10),
          pw.Center(
            child: _teks('Terima kasih, selamat menikmati!', ukuran: 8),
          ),
        ],
      ),
    );
  }

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
                  'Catatan: ${item.catatan}',
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
  // Struk dapur per divisi (tanpa harga)
  // ------------------------------------------------------------

  static pw.Page _halamanDapur(
    Order order,
    pw.MemoryImage? logo,
    Divisi divisi,
    List<OrderItem> items,
  ) {
    final jenis = order.jenisPesanan == 'takeaway' ? 'Takeaway' : 'Dine-in';
    final porsi = items.fold<int>(0, (s, i) => s + i.jumlah);
    final nama = order.namaPelanggan?.trim() ?? '';

    return pw.Page(
      pageFormat: PdfPageFormat.roll80,
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _kop(logo),
          pw.SizedBox(height: 6),
          pw.Center(
            child: _teks(
              'DAPUR ${divisi.label.toUpperCase()}',
              ukuran: 14,
              tebal: true,
            ),
          ),
          pw.Center(child: _teks(_tanggal(order), ukuran: 8)),
          pw.SizedBox(height: 6),
          _teks('No: #${_kode(order)}', ukuran: 11, tebal: true),
          _teks('Jenis: $jenis', ukuran: 10),
          if (order.jenisPesanan != 'takeaway')
            _teks('Meja: ${order.meja ?? '-'}', ukuran: 12, tebal: true),
          if (nama.isNotEmpty) _teks('Pelanggan: $nama', ukuran: 10),
          pw.Divider(),
          ...items.map(_barisDapur),
          pw.Divider(),
          _baris('Total porsi', '$porsi', ukuran: 11, tebal: true),
        ],
      ),
    );
  }

  static pw.Widget _barisDapur(OrderItem item) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 5),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _teks('${item.jumlah}x ', ukuran: 12, tebal: true),
                pw.Expanded(
                  child: _teks(item.namaMenu, ukuran: 12, tebal: true),
                ),
              ],
            ),
            if (item.catatan != null && item.catatan!.isNotEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.only(left: 18),
                child: _teks('Catatan: ${item.catatan}', ukuran: 9, tebal: true),
              ),
          ],
        ),
      );
}