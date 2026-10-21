// =============================================================
// ORDER PROVIDER — semua akses database lewat SupabaseService.
// BARU: nama kasir + getter isLoadingOrders / isLoadingRingkasan /
//       ordersError yang dipake dashboard.
// =============================================================

import 'package:flutter/material.dart';

import '../models/order.dart';
import '../services/supabase_service.dart';

class OrderProvider extends ChangeNotifier {
  final List<CartItem> _cart = [];
  String _namaPelanggan = '';
  String _meja = '';
  String _metodePembayaran = 'cash';
  String _kasir = '';
  bool _isSubmitting = false;
  String? _pesanError;

  List<Order> _orders = [];
  bool _isLoadingOrders = false;
  String? _ordersError;

  int _ringkasanJumlahPesanan = 0;
  int _ringkasanTotalPendapatan = 0;
  bool _isLoadingRingkasan = false;

  // ---------- getter ----------
  List<CartItem> get cart => List.unmodifiable(_cart);
  String get namaPelanggan => _namaPelanggan;
  String get meja => _meja;
  String get metodePembayaran => _metodePembayaran;
  String get kasir => _kasir;
  bool get isSubmitting => _isSubmitting;
  String? get pesanError => _pesanError;
  List<Order> get orders => List.unmodifiable(_orders);
  bool get isLoadingOrders => _isLoadingOrders;
  String? get ordersError => _ordersError;
  int get ringkasanJumlahPesanan => _ringkasanJumlahPesanan;
  int get ringkasanTotalPendapatan => _ringkasanTotalPendapatan;
  bool get isLoadingRingkasan => _isLoadingRingkasan;
  int get totalKeranjang => _cart.fold(0, (t, c) => t + c.subtotal);
  int get jumlahItemKeranjang => _cart.fold(0, (t, c) => t + c.jumlah);
  bool get keranjangKosong => _cart.isEmpty;

  // ---------- setter form ----------
  void setNamaPelanggan(String v) {
    _namaPelanggan = v;
    notifyListeners();
  }

  void setMeja(String v) {
    _meja = v;
    notifyListeners();
  }

  void setMetodePembayaran(String v) {
    _metodePembayaran = v;
    notifyListeners();
  }

  void setKasir(String v) {
    _kasir = v;
    notifyListeners();
  }

  // ---------- keranjang ----------
  void tambahKeKeranjang({
    required String menuItemId,
    required String namaMenu,
    required int hargaSatuan,
    String? catatan,
  }) {
    final idx = _cart.indexWhere((c) => c.menuItemId == menuItemId);
    if (idx >= 0) {
      _cart[idx].jumlah += 1;
    } else {
      _cart.add(CartItem(
        menuItemId: menuItemId,
        namaMenu: namaMenu,
        hargaSatuan: hargaSatuan,
        jumlah: 1,
        catatan: catatan,
      ));
    }
    notifyListeners();
  }

  void ubahJumlah(String menuItemId, int delta) {
    final idx = _cart.indexWhere((c) => c.menuItemId == menuItemId);
    if (idx < 0) return;
    final jumlahBaru = _cart[idx].jumlah + delta;
    if (jumlahBaru <= 0) {
      _cart.removeAt(idx);
    } else {
      _cart[idx].jumlah = jumlahBaru;
    }
    notifyListeners();
  }

  void ubahCatatan(String menuItemId, String? catatan) {
    final idx = _cart.indexWhere((c) => c.menuItemId == menuItemId);
    if (idx < 0) return;
    _cart[idx].catatan =
        (catatan == null || catatan.trim().isEmpty) ? null : catatan.trim();
    notifyListeners();
  }

  void hapusDariKeranjang(String menuItemId) {
    _cart.removeWhere((c) => c.menuItemId == menuItemId);
    notifyListeners();
  }

  void kosongkanKeranjang() {
    if (_cart.isEmpty) return;
    _cart.clear();
    notifyListeners();
  }

  // ---------- simpan pesanan (lewat SupabaseService, kasir ikut) ----------
  Future<Order?> simpanPesanan() async {
    if (_cart.isEmpty || _isSubmitting) return null;
    _isSubmitting = true;
    _pesanError = null;
    notifyListeners();
    try {
      final pesanan = await SupabaseService.createOrder(
        namaPelanggan:
            _namaPelanggan.trim().isEmpty ? null : _namaPelanggan.trim(),
        meja: _meja.trim().isEmpty ? null : _meja.trim(),
        metodePembayaran: _metodePembayaran,
        kasir: _kasir.trim(), // ← NAMA KASIR MASUK DATABASE
        items: List<CartItem>.from(_cart),
      );
      _orders.insert(0, pesanan);
      _cart.clear();
      _namaPelanggan = '';
      _meja = '';
      // kasir sengaja nggak direset — ketik sekali, kepake terus
      return pesanan;
    } catch (e) {
      _pesanError = e.toString();
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  // ---------- load data ----------
  Future<void> loadOrders() async {
    _isLoadingOrders = true;
    _ordersError = null;
    notifyListeners();
    try {
      _orders = await SupabaseService.fetchOrders();
    } catch (e) {
      _ordersError = e.toString();
    } finally {
      _isLoadingOrders = false;
      notifyListeners();
    }
  }

  Future<void> loadRingkasanHariIni() async {
    _isLoadingRingkasan = true;
    notifyListeners();
    try {
      final r = await SupabaseService.fetchRingkasanHariIni();
      _ringkasanJumlahPesanan = r.jumlahPesanan;
      _ringkasanTotalPendapatan = r.totalPendapatan;
    } catch (_) {
      // diam aja — angka lama tetep tampil
    } finally {
      _isLoadingRingkasan = false;
      notifyListeners();
    }
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    try {
      await SupabaseService.updateOrderStatus(orderId, status);
      await loadOrders();
    } catch (_) {}
  }

  // Terima dua gaya panggilan: hapusPesanan(order) ATAU hapusPesanan(order.id)
  // Error dilempar ke atas biar pemanggil bisa nampilin SnackBar-nya.
  Future<void> hapusPesanan(dynamic target) async {
    final id = target is Order ? target.id : target.toString();
    try {
      await SupabaseService.hapusOrder(id);
      _orders.removeWhere((o) => o.id == id);
      notifyListeners();
      await loadRingkasanHariIni();
    } catch (e) {
      rethrow;
    }
  }
}