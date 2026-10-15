import 'package:flutter/foundation.dart';

import '../models/pengeluaran.dart';
import '../services/supabase_service.dart';

/// State management catatan pengeluaran (belanja kebutuhan cafe).
class PengeluaranProvider extends ChangeNotifier {
  List<Pengeluaran> _items = [];
  bool _isLoading = false;
  String? _error;

  List<Pengeluaran> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadPengeluaran() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _items = await SupabaseService.fetchPengeluaran();
    } catch (e) {
      _error = 'Gagal memuat pengeluaran: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> tambah({
    required String keterangan,
    required int jumlah,
    required DateTime tanggal,
  }) async {
    final baru = await SupabaseService.addPengeluaran(
      Pengeluaran(
        id: '',
        keterangan: keterangan,
        jumlah: jumlah,
        tanggal: tanggal,
      ),
    );
    _items = [baru, ..._items];
    notifyListeners();
  }

  Future<void> hapus(String id) async {
    await SupabaseService.hapusPengeluaran(id);
    _items = _items.where((e) => e.id != id).toList();
    notifyListeners();
  }

  /// Total pengeluaran pada bulan tertentu.
  int totalPadaBulan(int tahun, int bulan) {
    return _items
        .where((e) => e.tanggal.year == tahun && e.tanggal.month == bulan)
        .fold(0, (sum, e) => sum + e.jumlah);
  }
}