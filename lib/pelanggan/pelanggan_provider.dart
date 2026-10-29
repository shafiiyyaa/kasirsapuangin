import 'package:flutter/material.dart';

import '../menu_board/models/menu_item.dart';
import 'pelanggan_service.dart';

class ItemKeranjang {
  final MenuItem menu;
  int jumlah;
  String? catatan;

  ItemKeranjang({required this.menu, this.jumlah = 1, this.catatan});

  int get subtotal => menu.harga * jumlah;
}

class PelangganProvider extends ChangeNotifier {
  PelangganProvider() {
    meja = _bacaMejaDariUrl();
    mejaDariQr = meja.isNotEmpty;
  }

  // ---------- menu ----------
  List<MenuItem> _menu = [];
  bool loadingMenu = false;
  String? errorMenu;

  List<MenuItem> get menu => _menu;

  List<String> get daftarKategori {
    final hasil = <String>[];
    for (final item in _menu) {
      if (!hasil.contains(item.kategori)) hasil.add(item.kategori);
    }
    return hasil;
  }

  Future<void> loadMenu({bool diam = false}) async {
    if (!diam) {
      loadingMenu = true;
      errorMenu = null;
      notifyListeners();
    }

    try {
      _menu = await PelangganService.ambilMenu();
      errorMenu = null;
    } on PelangganException catch (e) {
      if (!diam) errorMenu = e.pesan;
    }

    loadingMenu = false;
    notifyListeners();
  }

  // ---------- keranjang ----------
  final List<ItemKeranjang> _keranjang = [];

  List<ItemKeranjang> get keranjang => List.unmodifiable(_keranjang);

  int get jumlahItem => _keranjang.fold(0, (sum, e) => sum + e.jumlah);
  int get total => _keranjang.fold(0, (sum, e) => sum + e.subtotal);

  int jumlahDi(String menuId) {
    for (final e in _keranjang) {
      if (e.menu.id == menuId) return e.jumlah;
    }
    return 0;
  }

  void tambah(MenuItem menu) {
    if (!menu.tersedia) return;
    for (final e in _keranjang) {
      if (e.menu.id == menu.id) {
        if (e.jumlah < 50) e.jumlah++;
        notifyListeners();
        return;
      }
    }
    _keranjang.add(ItemKeranjang(menu: menu));
    notifyListeners();
  }

  void kurang(String menuId) {
    for (var i = 0; i < _keranjang.length; i++) {
      if (_keranjang[i].menu.id == menuId) {
        if (_keranjang[i].jumlah > 1) {
          _keranjang[i].jumlah--;
        } else {
          _keranjang.removeAt(i);
        }
        notifyListeners();
        return;
      }
    }
  }

  void ubahCatatan(String menuId, String catatan) {
    for (final e in _keranjang) {
      if (e.menu.id == menuId) {
        final bersih = catatan.trim();
        e.catatan = bersih.isEmpty ? null : bersih;
        notifyListeners();
        return;
      }
    }
  }

  // ---------- data pemesan ----------
  String namaPemesan = '';
  String meja = '';
  late final bool mejaDariQr;
  String jenisPesanan = 'dine_in'; // dine_in | takeaway
  String metodePembayaran = 'cash'; // cash | qris | transfer

  bool mengirim = false;
  String? errorKirim;

  void setNama(String nilai) => namaPemesan = nilai;
  void setMeja(String nilai) => meja = nilai;

  void setJenis(String nilai) {
    jenisPesanan = nilai;
    errorKirim = null;
    notifyListeners();
  }

  void setMetode(String nilai) {
    metodePembayaran = nilai;
    notifyListeners();
  }

  /// Membaca nomor meja dari link QR, mis. https://situs.netlify.app/?meja=5
  String _bacaMejaDariUrl() {
    try {
      final mentah = (Uri.base.queryParameters['meja'] ?? '').trim();
      if (mentah.isEmpty || mentah.length > 10) return '';
      if (!RegExp(r'^[A-Za-z0-9 \-]+$').hasMatch(mentah)) return '';
      return mentah;
    } catch (_) {
      return '';
    }
  }

  /// Mengembalikan ID pesanan jika berhasil, null jika gagal
  /// (pesan kesalahan ada di [errorKirim]).
  Future<String?> kirimPesanan() async {
    errorKirim = null;

    final nama = namaPemesan.trim();
    final nomorMeja = meja.trim();

    if (_keranjang.isEmpty) {
      errorKirim = 'Keranjang masih kosong.';
      notifyListeners();
      return null;
    }
    if (nama.isEmpty) {
      errorKirim = 'Nama pemesan wajib diisi.';
      notifyListeners();
      return null;
    }
    if (jenisPesanan == 'dine_in' && nomorMeja.isEmpty) {
      errorKirim = 'Nomor meja wajib diisi.';
      notifyListeners();
      return null;
    }

    mengirim = true;
    notifyListeners();

    try {
      final id = await PelangganService.buatPesanan(
        namaPelanggan: nama,
        meja: jenisPesanan == 'dine_in' ? nomorMeja : null,
        jenisPesanan: jenisPesanan,
        metodePembayaran: metodePembayaran,
        items: _keranjang
            .map((e) => {
                  'menu_item_id': e.menu.id,
                  'jumlah': e.jumlah,
                  'catatan': e.catatan,
                })
            .toList(),
      );

      _keranjang.clear();
      mengirim = false;
      notifyListeners();
      return id;
    } on PelangganException catch (e) {
      errorKirim = e.pesan;
      mengirim = false;
      notifyListeners();
      // Menu mungkin baru saja habis; segarkan daftar menu diam-diam.
      await loadMenu(diam: true);
      return null;
    }
  }
}