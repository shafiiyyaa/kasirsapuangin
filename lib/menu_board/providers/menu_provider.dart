import 'package:flutter/foundation.dart';

import '../models/menu_item.dart';
import '../services/supabase_service.dart';

/// State management untuk data menu — dipakai di layar Menu & Tambah Pesanan.
class MenuProvider extends ChangeNotifier {
  List<MenuItem> _items = [];
  bool _isLoading = false;
  String? _error;

  List<MenuItem> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Daftar kategori unik, urut sesuai kemunculan pertama di data
  /// (mis. "Manual Brew", "Milk Based", "Coffee Based", dst).
  List<String> get kategoriList {
    final set = <String>{};
    for (final item in _items) {
      set.add(item.kategori);
    }
    return set.toList();
  }

  List<MenuItem> itemsByKategori(String kategori) {
    return _items.where((e) => e.kategori == kategori).toList();
  }

  /// tipe: "makanan" atau "minuman"
  List<MenuItem> itemsByTipe(String tipe) {
    return _items.where((e) => e.tipe == tipe).toList();
  }

  Future<void> loadMenu() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _items = await SupabaseService.fetchMenuItems();
    } catch (e) {
      _error = 'Gagal memuat menu: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> tambahMenu(MenuItem item) async {
    final baru = await SupabaseService.addMenuItem(item);
    _items = [..._items, baru];
    notifyListeners();
  }

  Future<void> updateMenu(MenuItem item) async {
    await SupabaseService.updateMenuItem(item);
    _items = _items.map((e) => e.id == item.id ? item : e).toList();
    notifyListeners();
  }

  Future<void> ubahStatusTersedia(String id, bool tersedia) async {
    await SupabaseService.setMenuTersedia(id, tersedia);
    _items = _items
        .map((e) => e.id == id ? e.copyWith(tersedia: tersedia) : e)
        .toList();
    notifyListeners();
  }

  Future<void> hapusMenu(String id) async {
    await SupabaseService.deleteMenuItem(id);
    _items = _items.where((e) => e.id != id).toList();
    notifyListeners();
  }
}