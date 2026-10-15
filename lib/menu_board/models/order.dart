import 'order_item.dart';

/// Status pesanan, disimpan sebagai text di kolom `status` tabel `orders`.
enum OrderStatus { baru, diproses, selesai, batal }

extension OrderStatusX on OrderStatus {
  String get dbValue {
    switch (this) {
      case OrderStatus.baru:
        return 'baru';
      case OrderStatus.diproses:
        return 'diproses';
      case OrderStatus.selesai:
        return 'selesai';
      case OrderStatus.batal:
        return 'batal';
    }
  }

  String get label {
    switch (this) {
      case OrderStatus.baru:
        return 'Baru';
      case OrderStatus.diproses:
        return 'Diproses';
      case OrderStatus.selesai:
        return 'Selesai';
      case OrderStatus.batal:
        return 'Dibatalkan';
    }
  }

  static OrderStatus fromDb(String value) {
    switch (value) {
      case 'baru':
        return OrderStatus.baru;
      case 'diproses':
        return OrderStatus.diproses;
      case 'selesai':
        return OrderStatus.selesai;
      case 'batal':
        return OrderStatus.batal;
      default:
        return OrderStatus.baru;
    }
  }
}

/// Model untuk satu pesanan (tabel `orders`).
/// `items` diisi terpisah lewat join/query ke `order_items`.
class Order {
  final String id;
  final String? namaPelanggan; // opsional, bisa kosong buat walk-in
  final String? meja; // opsional, nomor meja pelanggan
  final int totalHarga;
  final OrderStatus status;
  final DateTime createdAt;
  final List<OrderItem> items;

  Order({
    required this.id,
    this.namaPelanggan,
    this.meja,
    required this.totalHarga,
    required this.status,
    required this.createdAt,
    this.items = const [],
  });

  factory Order.fromMap(Map<String, dynamic> map, {List<OrderItem>? items}) {
    return Order(
      id: map['id'] as String,
      namaPelanggan: map['nama_pelanggan'] as String?,
      meja: map['meja'] as String?,
      totalHarga: map['total_harga'] as int,
      status: OrderStatusX.fromDb(map['status'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      items: items ?? const [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama_pelanggan': namaPelanggan,
      'meja': meja,
      'total_harga': totalHarga,
      'status': status.dbValue,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Dipakai saat insert pesanan baru (tanpa id & created_at).
  Map<String, dynamic> toInsertMap() {
    return {
      'nama_pelanggan': namaPelanggan,
      'meja': meja,
      'total_harga': totalHarga,
      'status': status.dbValue,
    };
  }

  Order copyWith({
    String? namaPelanggan,
    String? meja,
    int? totalHarga,
    OrderStatus? status,
    List<OrderItem>? items,
  }) {
    return Order(
      id: id,
      namaPelanggan: namaPelanggan ?? this.namaPelanggan,
      meja: meja ?? this.meja,
      totalHarga: totalHarga ?? this.totalHarga,
      status: status ?? this.status,
      createdAt: createdAt,
      items: items ?? this.items,
    );
  }
}
