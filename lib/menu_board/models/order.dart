import 'order_item.dart';

export 'order_item.dart';

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

class Order {
  final String id;
  final String? namaPelanggan;
  final String? meja;
  final String? kasir;
  final String metodePembayaran;

  /// Total akhir yang dibayar (SETELAH diskon). Dipakai untuk pendapatan.
  final int totalHarga;

  /// Harga asli sebelum diskon. Null pada pesanan lama.
  final int? subtotalHarga;

  /// Potongan diskon dalam Rupiah (0 jika tanpa diskon).
  final int diskon;

  /// Nama diskon saat pesanan dibuat, mis. "Promo Akhir Tahun (10%)".
  final String? diskonLabel;

  final OrderStatus status;
  final DateTime createdAt;
  final List<OrderItem> items;

  // Jenis pesanan: dine_in atau takeaway.
  final String jenisPesanan;

  // Sumber pesanan: kasir atau qr.
  final String sumberPesanan;

  // Status pembayaran: belum_dibayar atau dibayar.
  final String statusPembayaran;

  // Status pengantaran: belum_diantar atau sudah_diantar.
  final String statusPengantaran;

  Order({
    required this.id,
    this.namaPelanggan,
    this.meja,
    this.kasir,
    this.metodePembayaran = 'cash',
    required this.totalHarga,
    this.subtotalHarga,
    this.diskon = 0,
    this.diskonLabel,
    required this.status,
    required this.createdAt,
    this.items = const [],
    this.jenisPesanan = 'dine_in',
    this.sumberPesanan = 'kasir',
    this.statusPembayaran = 'belum_dibayar',
    this.statusPengantaran = 'belum_diantar',
  });

  /// Harga asli sebelum diskon (aman untuk pesanan lama).
  int get subtotalAsli => subtotalHarga ?? (totalHarga + diskon);

  factory Order.fromMap(
    Map<String, dynamic> map, {
    List<OrderItem>? items,
  }) {
    return Order(
      id: map['id'] as String,
      namaPelanggan: map['nama_pelanggan'] as String?,
      meja: map['meja']?.toString(),
      kasir: map['kasir'] as String?,
      metodePembayaran: (map['metode_pembayaran'] as String?) ?? 'cash',
      totalHarga: (map['total_harga'] as num).toInt(),
      subtotalHarga: (map['subtotal_harga'] as num?)?.toInt(),
      diskon: (map['diskon'] as num?)?.toInt() ?? 0,
      diskonLabel: map['diskon_label'] as String?,
      status: OrderStatusX.fromDb((map['status'] as String?) ?? 'baru'),
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
      items: items ?? const [],
      jenisPesanan: (map['jenis_pesanan'] as String?) ?? 'dine_in',
      sumberPesanan: (map['sumber_pesanan'] as String?) ?? 'kasir',
      statusPembayaran:
          (map['status_pembayaran'] as String?) ?? 'belum_dibayar',
      statusPengantaran:
          (map['status_pengantaran'] as String?) ?? 'belum_diantar',
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
      'subtotal_harga': subtotalHarga,
      'diskon': diskon,
      'diskon_label': diskonLabel,
      'status': status.dbValue,
      'created_at': createdAt.toIso8601String(),
      'jenis_pesanan': jenisPesanan,
      'sumber_pesanan': sumberPesanan,
      'status_pembayaran': statusPembayaran,
      'status_pengantaran': statusPengantaran,
    };
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'nama_pelanggan': namaPelanggan,
      'meja': meja,
      'kasir': kasir,
      'metode_pembayaran': metodePembayaran,
      'total_harga': totalHarga,
      'subtotal_harga': subtotalHarga,
      'diskon': diskon,
      'diskon_label': diskonLabel,
      'status': status.dbValue,
      'jenis_pesanan': jenisPesanan,
      'sumber_pesanan': sumberPesanan,
      'status_pembayaran': statusPembayaran,
      'status_pengantaran': statusPengantaran,
    };
  }

  Order copyWith({
    String? namaPelanggan,
    String? meja,
    String? kasir,
    String? metodePembayaran,
    int? totalHarga,
    int? subtotalHarga,
    int? diskon,
    String? diskonLabel,
    OrderStatus? status,
    List<OrderItem>? items,
    String? jenisPesanan,
    String? sumberPesanan,
    String? statusPembayaran,
    String? statusPengantaran,
  }) {
    return Order(
      id: id,
      namaPelanggan: namaPelanggan ?? this.namaPelanggan,
      meja: meja ?? this.meja,
      kasir: kasir ?? this.kasir,
      metodePembayaran: metodePembayaran ?? this.metodePembayaran,
      totalHarga: totalHarga ?? this.totalHarga,
      subtotalHarga: subtotalHarga ?? this.subtotalHarga,
      diskon: diskon ?? this.diskon,
      diskonLabel: diskonLabel ?? this.diskonLabel,
      status: status ?? this.status,
      createdAt: createdAt,
      items: items ?? this.items,
      jenisPesanan: jenisPesanan ?? this.jenisPesanan,
      sumberPesanan: sumberPesanan ?? this.sumberPesanan,
      statusPembayaran: statusPembayaran ?? this.statusPembayaran,
      statusPengantaran: statusPengantaran ?? this.statusPengantaran,
    );
  }
}