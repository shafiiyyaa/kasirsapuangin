
import 'package:flutter/material.dart';

import '../models/order.dart';
import '../services/supabase_service.dart';

class OrderProvider extends ChangeNotifier {
  final List<CartItem> _cart = [];

  String _namaPelanggan = '';
  String _meja = '';
  String _metodePembayaran = 'cash';
  String _kasir = '';

  String _jenisPesanan = 'dine_in';
  String _statusPembayaran = 'belum_dibayar';

  bool _isSubmitting = false;
  String? _pesanError;

  List<Order> _orders = [];
  bool _isLoadingOrders = false;
  String? _ordersError;

  int _ringkasanJumlahPesanan = 0;
  int _ringkasanTotalPendapatan = 0;
  bool _isLoadingRingkasan = false;

  List<CartItem> get cart => List.unmodifiable(_cart);
  String get namaPelanggan => _namaPelanggan;
  String get meja => _meja;
  String get metodePembayaran => _metodePembayaran;
  String get kasir => _kasir;
  String get jenisPesanan => _jenisPesanan;
  String get statusPembayaran => _statusPembayaran;

  bool get isSubmitting => _isSubmitting;
  String? get pesanError => _pesanError;

  List<Order> get orders => List.unmodifiable(_orders);
  bool get isLoadingOrders => _isLoadingOrders;
  String? get ordersError => _ordersError;

  int get ringkasanJumlahPesanan => _ringkasanJumlahPesanan;
  int get ringkasanTotalPendapatan => _ringkasanTotalPendapatan;
  bool get isLoadingRingkasan => _isLoadingRingkasan;

  int get totalKeranjang =>
      _cart.fold(0, (total, item) => total + item.subtotal);

  int get jumlahItemKeranjang =>
      _cart.fold(0, (total, item) => total + item.jumlah);

  bool get keranjangKosong => _cart.isEmpty;

  void setNamaPelanggan(String value) {
    _namaPelanggan = value;
    notifyListeners();
  }

  void setMeja(String value) {
    _meja = value;
    notifyListeners();
  }

  void setMetodePembayaran(String value) {
    _metodePembayaran = value;
    notifyListeners();
  }

  void setKasir(String value) {
    _kasir = value;
    notifyListeners();
  }

  void setJenisPesanan(String value) {
    if (value != 'dine_in' && value != 'takeaway') return;

    _jenisPesanan = value;

    if (value == 'takeaway') {
      _meja = '';
    }

    notifyListeners();
  }

  void setStatusPembayaran(String value) {
    if (value != 'belum_dibayar' && value != 'dibayar') return;

    _statusPembayaran = value;
    notifyListeners();
  }

  void tambahKeKeranjang({
    required String menuItemId,
    required String namaMenu,
    required int hargaSatuan,
    String? catatan,
  }) {
    final index =
        _cart.indexWhere((item) => item.menuItemId == menuItemId);

    if (index >= 0) {
      _cart[index].jumlah++;
    } else {
      _cart.add(
        CartItem(
          menuItemId: menuItemId,
          namaMenu: namaMenu,
          hargaSatuan: hargaSatuan,
          jumlah: 1,
          catatan: catatan,
        ),
      );
    }

    notifyListeners();
  }

  void ubahJumlah(String menuItemId, int delta) {
    final index =
        _cart.indexWhere((item) => item.menuItemId == menuItemId);

    if (index < 0) return;

    final jumlahBaru = _cart[index].jumlah + delta;

    if (jumlahBaru <= 0) {
      _cart.removeAt(index);
    } else {
      _cart[index].jumlah = jumlahBaru;
    }

    notifyListeners();
  }

  void ubahCatatan(String menuItemId, String? catatan) {
    final index =
        _cart.indexWhere((item) => item.menuItemId == menuItemId);

    if (index < 0) return;

    _cart[index].catatan =
        (catatan == null || catatan.trim().isEmpty)
            ? null
            : catatan.trim();

    notifyListeners();
  }

  void hapusDariKeranjang(String menuItemId) {
    _cart.removeWhere((item) => item.menuItemId == menuItemId);
    notifyListeners();
  }

  void kosongkanKeranjang() {
    if (_cart.isEmpty) return;

    _cart.clear();
    notifyListeners();
  }

  Future<Order?> simpanPesanan() async {
    if (_cart.isEmpty || _isSubmitting) return null;

    _isSubmitting = true;
    _pesanError = null;
    notifyListeners();

    try {
      final pesanan = await SupabaseService.createOrder(
        namaPelanggan: _namaPelanggan.trim().isEmpty
            ? null
            : _namaPelanggan.trim(),
        meja: _jenisPesanan == 'takeaway'
            ? null
            : (_meja.trim().isEmpty ? null : _meja.trim()),
        metodePembayaran: _metodePembayaran,
        kasir: _kasir.trim().isEmpty ? null : _kasir.trim(),
        items: List<CartItem>.from(_cart),
        jenisPesanan: _jenisPesanan,
        sumberPesanan: 'kasir',
        statusPembayaran: _statusPembayaran,
        statusPengantaran: 'belum_diantar',
      );

      _orders.removeWhere((order) => order.id == pesanan.id);
      _orders.insert(0, pesanan);

      _cart.clear();
      _namaPelanggan = '';
      _meja = '';
      _jenisPesanan = 'dine_in';
      _statusPembayaran = 'belum_dibayar';

      await loadRingkasanHariIni();

      return pesanan;
    } catch (error) {
      _pesanError = error.toString();
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> loadOrders() async {
    _isLoadingOrders = true;
    _ordersError = null;
    notifyListeners();

    try {
      _orders = await SupabaseService.fetchOrders();
    } catch (error) {
      _ordersError = error.toString();
    } finally {
      _isLoadingOrders = false;
      notifyListeners();
    }
  }

  Future<void> loadRingkasanHariIni() async {
    _isLoadingRingkasan = true;
    notifyListeners();

    try {
      final result = await SupabaseService.fetchRingkasanHariIni();

      _ringkasanJumlahPesanan = result.jumlahPesanan;
      _ringkasanTotalPendapatan = result.totalPendapatan;
    } catch (_) {
      // Pertahankan ringkasan terakhir jika pemuatan gagal.
    } finally {
      _isLoadingRingkasan = false;
      notifyListeners();
    }
  }

  Future<void> updateOrderStatus(
    String orderId,
    OrderStatus status,
  ) async {
    await SupabaseService.updateOrderStatus(orderId, status);
    await loadOrders();
    await loadRingkasanHariIni();
  }

  Future<void> updateStatusPengantaran(
    String orderId, {
    required bool sudahDiantar,
  }) async {
    await SupabaseService.updateStatusPengantaran(
      orderId,
      sudahDiantar: sudahDiantar,
    );

    final index = _orders.indexWhere((order) => order.id == orderId);

    if (index >= 0) {
      _orders[index] = _orders[index].copyWith(
        statusPengantaran:
            sudahDiantar ? 'sudah_diantar' : 'belum_diantar',
      );
      notifyListeners();
    }
  }

  Future<void> updateStatusPembayaran(
    String orderId, {
    required bool sudahDibayar,
  }) async {
    await SupabaseService.updateStatusPembayaran(
      orderId,
      sudahDibayar: sudahDibayar,
    );

    final index = _orders.indexWhere((order) => order.id == orderId);

    if (index >= 0) {
      _orders[index] = _orders[index].copyWith(
        statusPembayaran: sudahDibayar ? 'dibayar' : 'belum_dibayar',
      );
      notifyListeners();
    }

    await loadRingkasanHariIni();
  }

  Future<void> hapusPesanan(dynamic target) async {
    final id = target is Order ? target.id : target.toString();

    await SupabaseService.hapusOrder(id);

    _orders.removeWhere((order) => order.id == id);
    notifyListeners();

    await loadRingkasanHariIni();
  }
}
