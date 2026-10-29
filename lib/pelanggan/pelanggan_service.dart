import 'package:supabase_flutter/supabase_flutter.dart';

import '../menu_board/models/menu_item.dart';

/// Error yang pesannya aman ditampilkan ke pelanggan.
class PelangganException implements Exception {
  final String pesan;
  const PelangganException(this.pesan);

  @override
  String toString() => pesan;
}

/// Status pesanan yang dilihat pelanggan (hasil fungsi status_pesanan_qr).
class StatusPesanan {
  final String status; // baru | diproses | selesai | batal
  final String statusPembayaran; // belum_dibayar | dibayar
  final String statusPengantaran; // belum_diantar | sudah_diantar
  final String? meja; // null = take away
  final int total;

  const StatusPesanan({
    required this.status,
    required this.statusPembayaran,
    required this.statusPengantaran,
    required this.meja,
    required this.total,
  });

  factory StatusPesanan.fromMap(Map<String, dynamic> map) {
    return StatusPesanan(
      status: (map['status'] as String?) ?? 'baru',
      statusPembayaran:
          (map['status_pembayaran'] as String?) ?? 'belum_dibayar',
      statusPengantaran:
          (map['status_pengantaran'] as String?) ?? 'belum_diantar',
      meja: map['meja'] as String?,
      total: ((map['total_harga'] as num?) ?? 0).toInt(),
    );
  }

  bool get batal => status == 'batal';
  bool get sudahDiantar => statusPengantaran == 'sudah_diantar';
  bool get sudahBayar => statusPembayaran == 'dibayar';

  /// 0 = diterima, 1 = disiapkan, 2 = siap diantar, 3 = sudah diantar
  int get langkahAktif {
    if (sudahDiantar) return 3;
    if (status == 'selesai') return 2;
    if (status == 'diproses') return 1;
    return 0;
  }
}

/// Hanya berisi hal yang BOLEH dilakukan pelanggan:
/// membaca menu, membuat pesanan, melihat status pesanannya sendiri.
class PelangganService {
  PelangganService._();

  static SupabaseClient get _client => Supabase.instance.client;

  static String _pesanDari(Object error) {
    if (error is PostgrestException) return error.message;
    return 'Tidak bisa terhubung. Periksa internet lalu coba lagi.';
  }

  static Future<List<MenuItem>> ambilMenu() async {
    try {
      final data = await _client
          .from('menu_items')
          .select()
          .order('kategori')
          .order('nama');

      return (data as List)
          .map((e) => MenuItem.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw PelangganException(_pesanDari(e));
    }
  }

  /// Mengembalikan ID pesanan yang baru dibuat.
  static Future<String> buatPesanan({
    required String namaPelanggan,
    required String? meja,
    required String jenisPesanan,
    required String metodePembayaran,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final hasil = await _client.rpc(
        'buat_pesanan_qr',
        params: {
          'p_nama_pelanggan': namaPelanggan,
          'p_meja': meja,
          'p_jenis_pesanan': jenisPesanan,
          'p_metode_pembayaran': metodePembayaran,
          'p_items': items,
        },
      );
      return hasil.toString();
    } catch (e) {
      throw PelangganException(_pesanDari(e));
    }
  }

  /// null = pesanan tidak ditemukan.
  static Future<StatusPesanan?> ambilStatus(String orderId) async {
    try {
      final hasil = await _client.rpc(
        'status_pesanan_qr',
        params: {'p_order_id': orderId},
      );
      final daftar = hasil as List;
      if (daftar.isEmpty) return null;
      return StatusPesanan.fromMap(daftar.first as Map<String, dynamic>);
    } catch (e) {
      throw PelangganException(_pesanDari(e));
    }
  }
}