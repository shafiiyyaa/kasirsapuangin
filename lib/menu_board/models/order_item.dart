/// Model untuk satu baris item di dalam pesanan
/// (mewakili tabel `order_items`, relasi many-to-one ke `orders`).
class OrderItem {
  final String id;
  final String orderId;
  final String menuItemId;
  final String namaMenu; // disalin saat pesanan dibuat, biar nama tetap
  // muncul di riwayat walau menu aslinya diubah/dihapus belakangan
  final int hargaSatuan; // harga jual per item saat pesanan dibuat
  final int jumlah;
  final String? catatan; // mis. "pedas", "tanpa es"

  /// Harga modal (HPP) per item saat pesanan dibuat.
  /// null = pesanan lama (belum tercatat); statistik memakai modal menu saat ini.
  final int? hargaModal;

  const OrderItem({
    required this.id,
    required this.orderId,
    required this.menuItemId,
    required this.namaMenu,
    required this.hargaSatuan,
    required this.jumlah,
    this.catatan,
    this.hargaModal,
  });

  int get subtotal => hargaSatuan * jumlah;

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id'] as String,
      orderId: map['order_id'] as String,
      menuItemId: map['menu_item_id'] as String,
      namaMenu: map['nama_menu'] as String,
      hargaSatuan: map['harga_satuan'] as int,
      jumlah: map['jumlah'] as int,
      catatan: map['catatan'] as String?,
      hargaModal: (map['harga_modal'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'order_id': orderId,
      'menu_item_id': menuItemId,
      'nama_menu': namaMenu,
      'harga_satuan': hargaSatuan,
      'jumlah': jumlah,
      'catatan': catatan,
      'harga_modal': hargaModal,
    };
  }

  /// Dipakai saat insert baru sebagai bagian dari pembuatan pesanan.
  /// `orderId` disisipkan belakangan setelah baris `orders` dibuat.
  Map<String, dynamic> toInsertMap(String orderId) {
    return {
      'order_id': orderId,
      'menu_item_id': menuItemId,
      'nama_menu': namaMenu,
      'harga_satuan': hargaSatuan,
      'jumlah': jumlah,
      'catatan': catatan,
      if (hargaModal != null) 'harga_modal': hargaModal,
    };
  }

  OrderItem copyWith({int? jumlah, String? catatan, int? hargaModal}) {
    return OrderItem(
      id: id,
      orderId: orderId,
      menuItemId: menuItemId,
      namaMenu: namaMenu,
      hargaSatuan: hargaSatuan,
      jumlah: jumlah ?? this.jumlah,
      catatan: catatan ?? this.catatan,
      hargaModal: hargaModal ?? this.hargaModal,
    );
  }
}

/// Item sementara di "keranjang" sebelum pesanan disimpan ke Supabase.
/// Dipakai di layar Tambah Pesanan sebelum ada `order_id` & `id` asli.
class CartItem {
  final String menuItemId;
  final String namaMenu;
  final int hargaSatuan;
  int jumlah;
  String? catatan;

  CartItem({
    required this.menuItemId,
    required this.namaMenu,
    required this.hargaSatuan,
    this.jumlah = 1,
    this.catatan,
  });

  int get subtotal => hargaSatuan * jumlah;
}