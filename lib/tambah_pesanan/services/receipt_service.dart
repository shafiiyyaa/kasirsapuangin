// ignore_for_file: prefer_const_constructors

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../menu_board/models/order.dart';

/// Generate & cetak struk pesanan (kertas 80mm thermal,
/// tapi bisa ke printer apa pun lewat dialog print OS).
class ReceiptService {
  ReceiptService._();

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

  static String _rupiah(int n) => n
      .toString()
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.');

  static Future<void> cetakStruk(Order order) async {
    final pdf = pw.Document();

    final t = order.createdAt.toLocal();
    final waktu =
        '${t.day}/${t.month}/${t.year} ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (_) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  'Sapuangin Coffee & Farm',
                  style: pw.TextStyle(
                      fontSize: 12, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Center(
                child: pw.Text(waktu, style: pw.TextStyle(fontSize: 8)),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Nama  : ${order.namaPelanggan ?? '-'}',
                style: pw.TextStyle(fontSize: 9),
              ),
              pw.Text(
                'Meja    : ${order.meja ?? '-'}',
                style: pw.TextStyle(fontSize: 9),
              ),
              // ===== BARU: NAMA KASIR DI STRUK =====
              pw.Text(
                'Kasir   : -',
                style: pw.TextStyle(fontSize: 9),
              ),
              pw.Text(
                'Bayar  : ${metodeLabel(order.metodePembayaran)}',
                style: pw.TextStyle(fontSize: 9),
              ),
              pw.Divider(),
              ...order.items.map(
                (it) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 3),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            '${it.jumlah}x ',
                            style: pw.TextStyle(fontSize: 9),
                          ),
                          pw.Expanded(
                            child: pw.Text(
                              it.namaMenu,
                              style: pw.TextStyle(fontSize: 9),
                            ),
                          ),
                          pw.Text(
                            'Rp${_rupiah(it.hargaSatuan * it.jumlah)}',
                            style: pw.TextStyle(fontSize: 9),
                          ),
                        ],
                      ),
                      if (it.catatan != null && it.catatan!.isNotEmpty)
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(left: 14),
                          child: pw.Text(
                            'catatan: ${it.catatan}',
                            style: pw.TextStyle(
                              fontSize: 7,
                              fontStyle: pw.FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'TOTAL',
                    style: pw.TextStyle(
                        fontSize: 10, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    'Rp${_rupiah(order.totalHarga)}',
                    style: pw.TextStyle(
                        fontSize: 10, fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text(
                  'Terima kasih, selamat menikmati!',
                  style: pw.TextStyle(fontSize: 8),
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }
}