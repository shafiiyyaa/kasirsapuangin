// Pengaturan khusus halaman pelanggan (website yang dibuka dari QR).
// File ini SENGAJA terpisah dari main.dart kasir, supaya kode kasir
// tidak ikut terbawa saat build web.

const String kSupabaseUrlPelanggan = 'https://nbsemkswjlvnzwwlyhhg.supabase.co';
const String kSupabaseKeyPelanggan =
    'sb_publishable_K1QMR9WNPheN5IaWY4gMLQ_3uOw8p3l';

const String kNamaToko = 'Sapuangin Coffee & Farm';

/// Lebar maksimum tampilan (portrait). Di laptop, tampilan tetap berbentuk HP.
const double kBatasLebar = 480;

// ====== EDIT BAGIAN INI SESUAI TOKOMU ======
const String kInfoCash = 'Bayar langsung ke kasir ya.';
const String kInfoQris =
    'Pembayaran QRIS dilakukan di kasir. Tunjukkan bukti bayar ke kasir.';
const String kInfoTransfer =
    'Transfer ke: ISI NAMA BANK - ISI NOMOR REKENING a.n. ISI NAMA. '
    'Tunjukkan bukti transfer ke kasir.';
// ===========================================

/// 15000 -> "Rp15.000"
String rupiah(int nilai) {
  final angka = nilai.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < angka.length; i++) {
    if (i > 0 && (angka.length - i) % 3 == 0) buffer.write('.');
    buffer.write(angka[i]);
  }
  final minus = nilai < 0 ? '-' : '';
  return '${minus}Rp$buffer';
}