import 'package:flutter/foundation.dart';

import '../models/order.dart';
import '../models/order_item.dart';
import '../services/supabase_service.dart';

/// State management untuk pesanan: keranjang sementara (layar Tambah
/// Pesanan), riwayat pesanan yang sudah tersimpan, dan ringkasan dashboard.
class OrderProvider extends ChangeNotifier {
  // ---------- Keranjang (Tambah Pesanan) ----------
  final List<CartItem> _cart = [];
  String? _namaPelanggan;
  String? _meja;
  String _metodePembayaran = 'cash';

  List<CartItem> get cart => List.unmodifiable(_cart);
  String? get namaPelanggan => _namaPelanggan;
  String? get meja => _meja;
  String get metodePembayaran => _metodePembayaran;
  int get totalCart => _cart.fold(0, (sum, e) => sum + e.subtotal);
  int get jumlahItemCart => _cart.fold(0, (sum, e) => sum + e.jumlah);

  void setNamaPelanggan(String? nama) {
    _namaPelanggan = nama;
    notifyListeners();
  }

  void setMeja(String? value) {
    _meja = (value == null || value.isEmpty) ? null : value;
    notifyListeners();
  }

  void setMetodePembayaran(String value) {
    _metodePembayaran = value;
    notifyListeners();
  }

  /// Menambah item ke keranjang. Kalau item+catatan yang sama sudah ada,
  /// jumlahnya ditambah, bukan bikin baris baru.
  void tambahKeKeranjang(CartItem item) {
    final existingIndex = _cart.indexWhere(
      (e) => e.menuItemId == item.menuItemId && e.catatan == item.catatan,
    );
    if (existingIndex != -1) {
      _cart[existingIndex].jumlah += item.jumlah;
    } else {
      _cart.add(item);
    }
    notifyListeners();
  }

  void ubahJumlah(int index, int jumlahBaru) {
    if (jumlahBaru <= 0) {
      _cart.removeAt(index);
    } else {
      _cart[index].jumlah = jumlahBaru;
    }
    notifyListeners();
  }

  void hapusDariKeranjang(int index) {
    _cart.removeAt(index);
    notifyListeners();
  }

  void kosongkanKeranjang() {
    _cart.clear();
    _namaPelanggan = null;
    _meja = null;
    _metodePembayaran = 'cash';
    notifyListeners();
  }

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  /// Simpan isi keranjang saat ini jadi pesanan baru di Supabase.
  /// Mengembalikan null kalau keranjang kosong.
  Future<Order?> simpanPesanan() async {
    if (_cart.isEmpty) return null;

    _isSubmitting = true;
    notifyListeners();

    try {
      final order = await SupabaseService.createOrder(
        namaPelanggan: _namaPelanggan,
        meja: _meja,
        metodePembayaran: _metodePembayaran,
        items: _cart,
      );
      kosongkanKeranjang();
      return order;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  // ---------- Riwayat Pesanan ----------
  List<Order> _orders = [];
  bool _isLoadingOrders = false;
  String? _ordersError;

  List<Order> get orders => _orders;
  bool get isLoadingOrders => _isLoadingOrders;
  String? get ordersError => _ordersError;

  Future<void> loadOrders() async {
    _isLoadingOrders = true;
    _ordersError = null;
    notifyListeners();

    try {
      _orders = await SupabaseService.fetchOrders();
    } catch (e) {
      _ordersError = 'Gagal memuat pesanan: $e';
    } finally {
      _isLoadingOrders = false;
      notifyListeners();
    }
  }

  Future<void> ubahStatusPesanan(String orderId, OrderStatus status) async {
    await SupabaseService.updateOrderStatus(orderId, status);
    _orders = _orders
        .map((o) => o.id == orderId ? o.copyWith(status: status) : o)
        .toList();
    notifyListeners();
  }

  /// Hapus pesanan permanen (beserta item-itemnya) dari Supabase.
  Future<void> hapusPesanan(String orderId) async {
    await SupabaseService.hapusOrder(orderId);
    _orders = _orders.where((o) => o.id != orderId).toList();
    notifyListeners();
    // Ringkasan dashboard ikut di-refresh (jumlah/pendapatan hari ini).
    loadRingkasanHariIni();
  }

  // ---------- Dashboard ----------
  int ringkasanJumlahPesanan = 0;
  int ringkasanTotalPendapatan = 0;
  bool isLoadingRingkasan = false;

  Future<void> loadRingkasanHariIni() async {
    isLoadingRingkasan = true;
    notifyListeners();
    try {
      final hasil = await SupabaseService.fetchRingkasanHariIni();
      ringkasanJumlahPesanan = hasil.jumlahPesanan;
      ringkasanTotalPendapatan = hasil.totalPendapatan;
    } finally {
      isLoadingRingkasan = false;
      notifyListeners();
    }
  }
}