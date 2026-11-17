import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/pengeluaran.dart';

/// Akses tabel `pengeluaran` di Supabase (CRUD per periode).
class PengeluaranService {
  PengeluaranService._();

  static SupabaseClient get _client => Supabase.instance.client;

  static String _tgl(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Ambil pengeluaran dengan tanggal di [awal] (termasuk) sampai [akhir]
  /// (tidak termasuk), urut dari tanggal terbaru.
  static Future<List<Pengeluaran>> fetchPeriode(
    DateTime awal,
    DateTime akhir,
  ) async {
    final data = await _client
        .from('pengeluaran')
        .select()
        .gte('tanggal', _tgl(awal))
        .lt('tanggal', _tgl(akhir))
        .order('tanggal', ascending: false);

    return (data as List)
        .map((e) => Pengeluaran.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  static Future<Pengeluaran> tambah(Pengeluaran item) async {
    final data = await _client
        .from('pengeluaran')
        .insert(item.toInsertMap())
        .select()
        .single();
    return Pengeluaran.fromMap(data);
  }

  static Future<void> ubah(String id, Pengeluaran item) async {
    await _client.from('pengeluaran').update(item.toInsertMap()).eq('id', id);
  }

  static Future<void> hapus(String id) async {
    await _client.from('pengeluaran').delete().eq('id', id);
  }
}