
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../menu_board/models/order.dart';

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

  static String _rupiah(int angka) => angka
      .toString()
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.');

  static Future<void> cetakStruk(Order order) async {
    final pdf = pw.Document();

    final waktu = order.createdAt.toLocal();

    final tanggal =
        '${waktu.day.toString().padLeft(2, '0')}/'
        '${waktu.month.toString().padLeft(2, '0')}/'
        '${waktu.year} '
        '${waktu.hour.toString().padLeft(2, '0')}:'
        '${waktu.minute.toString().padLeft(2, '0')}';

    final jenisPesanan =
        order.jenisPesanan == 'takeaway' ? 'Takeaway' : 'Dine-in';

    final statusBayar =
        order.statusPembayaran == 'dibayar'
            ? 'Sudah dibayar'
            : 'Belum dibayar';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(
              child: pw.Text(
                'Sapuangin Coffee & Farm',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Center(
              child: pw.Text(
                tanggal,
                style: const pw.TextStyle(fontSize: 8),
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Pelanggan: ${order.namaPelanggan ?? '-'}',
              style: const pw.TextStyle(fontSize: 9),
            ),
            pw.Text(
              'Jenis: $jenisPesanan',
              style: const pw.TextStyle(fontSize: 9),
            ),
            if (order.jenisPesanan != 'takeaway')
              pw.Text(
                'Meja: ${order.meja ?? '-'}',
                style: const pw.TextStyle(fontSize: 9),
              ),
            pw.Text(
              'Kasir: ${order.kasir?.isNotEmpty == true ? order.kasir! : '-'}',
              style: const pw.TextStyle(fontSize: 9),
            ),
            pw.Text(
              'Bayar: ${metodeLabel(order.metodePembayaran)}',
              style: const pw.TextStyle(fontSize: 9),
            ),
            pw.Text(
              'Status: $statusBayar',
              style: const pw.TextStyle(fontSize: 9),
            ),
            pw.Divider(),
            ...order.items.map(
              (item) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 3),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          '${item.jumlah}x ',
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                        pw.Expanded(
                          child: pw.Text(
                            item.namaMenu,
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                        ),
                        pw.Text(
                          'Rp${_rupiah(item.subtotal)}',
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ],
                    ),
                    if (item.catatan != null &&
                        item.catatan!.isNotEmpty)
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
              ),
            ),
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'TOTAL',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'Rp${_rupiah(order.totalHarga)}',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Center(
              child: pw.Text(
                'Terima kasih, selamat menikmati!',
                style: const pw.TextStyle(fontSize: 8),
              ),
            ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (_) async => pdf.save(),
    );
  }
}
