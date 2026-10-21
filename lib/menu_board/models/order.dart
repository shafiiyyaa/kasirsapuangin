import 'order_item.dart';

/// Re-export: class OrderItem & CartItem aslinya cukup satu di
/// order_item.dart. Baris ini bikin file yang import order.dart
/// tetap otomatis dapat OrderItem & CartItem — tanpa duplikat,
/// tanpa bentrok import.
export 'order_item.dart';

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
class Order {
  final String id;
  final String? namaPelanggan;
  final String? meja;
  final String? kasir;
  final String metodePembayaran; // 'cash' | 'qris' | 'transfer'
  final int totalHarga;
  final OrderStatus status;
  final DateTime createdAt;
  final List<OrderItem> items;

  Order({
    required this.id,
    this.namaPelanggan,
    this.meja,
    this.kasir,
    this.metodePembayaran = 'cash',
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
      kasir: map['kasir'] as String?,
      metodePembayaran: (map['metode_pembayaran'] as String?) ?? 'cash',
      totalHarga: map['total_harga'] as int,
      status: OrderStatusX.fromDb(map['status'] as String),
      // Supabase menyimpan UTC -> konversi ke zona waktu perangkat (WIB)
      // di sini, biar semua layar otomatis tampil jam lokal.
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
      items: items ?? const [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama_pelanggan': namaPelanggan,
      'meja': meja,
      'kasir': kasir,
      'metode_pembayaran': metodePembayaran,
      'total_harga': totalHarga,
      'status': status.dbValue,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'nama_pelanggan': namaPelanggan,
      'meja': meja,
      'kasir': kasir,
      'metode_pembayaran': metodePembayaran,
      'total_harga': totalHarga,
      'status': status.dbValue,
    };
  }

  Order copyWith({
    String? namaPelanggan,
    String? meja,
    String? kasir,
    String? metodePembayaran,
    int? totalHarga,
    OrderStatus? status,
    List<OrderItem>? items,
  }) {
    return Order(
      id: id,
      namaPelanggan: namaPelanggan ?? this.namaPelanggan,
      meja: meja ?? this.meja,
      kasir: kasir ?? this.kasir,
      metodePembayaran: metodePembayaran ?? this.metodePembayaran,
      totalHarga: totalHarga ?? this.totalHarga,
      status: status ?? this.status,
      createdAt: createdAt,
      items: items ?? this.items,
    );
  }
}