
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/menu_item.dart';
import '../models/order.dart';
import '../models/pengeluaran.dart';

const String supabaseUrl = 'https://nbsemkswjlvnzwwlyhhg.supabase.co';
const String supabasePublishableKey =
    'sb_publishable_K1QMR9WNPheN5IaWY4gMLQ_3uOw8p3l';

class SupabaseService {
  SupabaseService._();

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabasePublishableKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;

  // ============================================================
  // MENU
  // ============================================================

  static Future<List<MenuItem>> fetchMenuItems() async {
    final data = await client
        .from('menu_items')
        .select()
        .order('kategori')
        .order('nama');

    return (data as List)
        .map((e) => MenuItem.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  static Future<MenuItem> addMenuItem(MenuItem item) async {
    final data = await client
        .from('menu_items')
        .insert(item.toInsertMap())
        .select()
        .single();

    return MenuItem.fromMap(data);
  }

  static Future<void> updateMenuItem(MenuItem item) async {
    await client
        .from('menu_items')
        .update(item.toMap())
        .eq('id', item.id);
  }

  static Future<void> setMenuTersedia(
    String id,
    bool tersedia,
  ) async {
    await client
        .from('menu_items')
        .update({'tersedia': tersedia})
        .eq('id', id);
  }

  static Future<void> deleteMenuItem(String id) async {
    await client.from('menu_items').delete().eq('id', id);
  }

  // ============================================================
  // PESANAN
  // ============================================================

  /// Membuat pesanan baru.
  ///
  /// jenisPesanan:
  /// - dine_in
  /// - takeaway
  ///
  /// sumberPesanan:
  /// - kasir
  /// - qr
  ///
  /// statusPembayaran:
  /// - belum_dibayar
  /// - dibayar
  ///
  /// statusPengantaran:
  /// - belum_diantar
  /// - sudah_diantar
  ///
  /// Default untuk pesanan kasir adalah dine-in dan belum dibayar.
  /// Status dibayar hanya digunakan jika pembayaran benar-benar
  /// sudah diterima atau dikonfirmasi.
  static Future<Order> createOrder({
    String? namaPelanggan,
    String? meja,
    String metodePembayaran = 'cash',
    String? kasir,
    required List<CartItem> items,
    String jenisPesanan = 'dine_in',
    String sumberPesanan = 'kasir',
    String statusPembayaran = 'belum_dibayar',
    String statusPengantaran = 'belum_diantar',
  }) async {
    if (items.isEmpty) {
      throw Exception('Keranjang pesanan masih kosong.');
    }

    final totalHarga = items.fold<int>(
      0,
      (sum, item) => sum + item.subtotal,
    );

    // Simpan data utama pesanan.
    final orderData = await client
        .from('orders')
        .insert({
          'nama_pelanggan': namaPelanggan,
          'meja': meja,
          'metode_pembayaran': metodePembayaran,
          'kasir': kasir,
          'total_harga': totalHarga,
          'status': OrderStatus.baru.dbValue,
          'jenis_pesanan': jenisPesanan,
          'sumber_pesanan': sumberPesanan,
          'status_pembayaran': statusPembayaran,
          'status_pengantaran': statusPengantaran,
        })
        .select()
        .single();

    final orderId = orderData['id'] as String;

    // Simpan detail item pesanan.
    final itemRows = items
        .map(
          (item) => {
            'order_id': orderId,
            'menu_item_id': item.menuItemId,
            'nama_menu': item.namaMenu,
            'harga_satuan': item.hargaSatuan,
            'jumlah': item.jumlah,
            'catatan': item.catatan,
          },
        )
        .toList();

    await client.from('order_items').insert(itemRows);

    // Kembalikan pesanan lengkap agar bisa langsung ditampilkan
    // atau dicetak tanpa harus mengambil ulang item dari database.
    final itemsTersimpan = items
        .map(
          (item) => OrderItem(
            id: '',
            orderId: orderId,
            menuItemId: item.menuItemId,
            namaMenu: item.namaMenu,
            hargaSatuan: item.hargaSatuan,
            jumlah: item.jumlah,
            catatan: item.catatan,
          ),
        )
        .toList();

    return Order.fromMap(
      orderData,
      items: itemsTersimpan,
    );
  }

  /// Mengambil pesanan terbaru beserta detail item.
  static Future<List<Order>> fetchOrders({
    int limit = 200,
  }) async {
    final data = await client
        .from('orders')
        .select()
        .order('created_at', ascending: false)
        .limit(limit);

    final rows = (data as List).cast<Map<String, dynamic>>();

    if (rows.isEmpty) {
      return const [];
    }

    final itemsPerOrder = await _ambilItemPerOrder(rows);

    return rows.map((row) {
      final id = row['id'] as String;

      return Order.fromMap(
        row,
        items: itemsPerOrder[id] ?? const [],
      );
    }).toList();
  }

  /// Mengambil pesanan pada rentang tanggal.
  /// Digunakan oleh halaman statistik dan riwayat.
  static Future<List<Order>> fetchOrdersPeriode(
    DateTime awal,
    DateTime akhir,
  ) async {
    final data = await client
        .from('orders')
        .select()
        .gte(
          'created_at',
          DateTime(
            awal.year,
            awal.month,
            awal.day,
          ).toUtc().toIso8601String(),
        )
        .lt(
          'created_at',
          DateTime(
            akhir.year,
            akhir.month,
            akhir.day,
          ).toUtc().toIso8601String(),
        )
        .order('created_at', ascending: false);

    final rows = (data as List).cast<Map<String, dynamic>>();

    if (rows.isEmpty) {
      return const [];
    }

    final itemsPerOrder = await _ambilItemPerOrder(rows);

    return rows.map((row) {
      final id = row['id'] as String;

      return Order.fromMap(
        row,
        items: itemsPerOrder[id] ?? const [],
      );
    }).toList();
  }

  /// Mengambil item untuk beberapa pesanan sekaligus.
  static Future<Map<String, List<OrderItem>>> _ambilItemPerOrder(
    List<Map<String, dynamic>> orderRows,
  ) async {
    final orderIds = orderRows
        .map((row) => row['id'] as String)
        .toList();

    final itemData = await client
        .from('order_items')
        .select()
        .inFilter('order_id', orderIds);

    final hasil = <String, List<OrderItem>>{};

    for (final row
        in (itemData as List).cast<Map<String, dynamic>>()) {
      final item = OrderItem.fromMap(row);

      hasil.putIfAbsent(item.orderId, () => []).add(item);
    }

    return hasil;
  }

  /// Memperbarui status proses pesanan.
  /// Status ini berbeda dengan status pengantaran.
  static Future<void> updateOrderStatus(
    String orderId,
    OrderStatus status,
  ) async {
    await client
        .from('orders')
        .update({'status': status.dbValue})
        .eq('id', orderId);
  }

  /// Memperbarui status pengantaran.
  static Future<void> updateStatusPengantaran(
    String orderId, {
    required bool sudahDiantar,
  }) async {
    await client
        .from('orders')
        .update({
          'status_pengantaran':
              sudahDiantar ? 'sudah_diantar' : 'belum_diantar',
        })
        .eq('id', orderId);
  }

  /// Memperbarui status pembayaran.
  static Future<void> updateStatusPembayaran(
    String orderId, {
    required bool sudahDibayar,
  }) async {
    await client
        .from('orders')
        .update({
          'status_pembayaran':
              sudahDibayar ? 'dibayar' : 'belum_dibayar',
        })
        .eq('id', orderId);
  }

  /// Menghapus pesanan beserta item-itemnya.
  static Future<void> hapusOrder(String orderId) async {
    await client
        .from('order_items')
        .delete()
        .eq('order_id', orderId);

    await client
        .from('orders')
        .delete()
        .eq('id', orderId);
  }

  /// Ringkasan pesanan dan pendapatan hari ini.
  /// Pesanan batal tidak dihitung sebagai pendapatan.
  static Future<RingkasanHariIni> fetchRingkasanHariIni() async {
    final now = DateTime.now();

    // Menggunakan awal hari lokal, kemudian dikonversi ke UTC.
    final awalHariLokal = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final awalHariUtc =
        awalHariLokal.toUtc().toIso8601String();

    final data = await client
        .from('orders')
        .select('total_harga, status')
        .gte('created_at', awalHariUtc);

    var jumlah = 0;
    var pendapatan = 0;

    for (final row
        in (data as List).cast<Map<String, dynamic>>()) {
      if ((row['status'] as String?) == 'batal') {
        continue;
      }

      jumlah++;
      pendapatan +=
          (row['total_harga'] as num?)?.toInt() ?? 0;
    }

    return RingkasanHariIni(
      jumlahPesanan: jumlah,
      totalPendapatan: pendapatan,
    );
  }

  // ============================================================
  // PENGELUARAN
  // ============================================================

  static Future<List<Pengeluaran>> fetchPengeluaran() async {
    final data = await client
        .from('pengeluaran')
        .select()
        .order('created_at', ascending: false);

    return (data as List)
        .map(
          (e) => Pengeluaran.fromMap(
            e as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  static Future<Pengeluaran> addPengeluaran(
    Pengeluaran item,
  ) async {
    final data = await client
        .from('pengeluaran')
        .insert(item.toInsertMap())
        .select()
        .single();

    return Pengeluaran.fromMap(data);
  }

  static Future<void> hapusPengeluaran(String id) async {
    await client
        .from('pengeluaran')
        .delete()
        .eq('id', id);
  }
}

/// Hasil ringkasan dashboard.
class RingkasanHariIni {
  final int jumlahPesanan;
  final int totalPendapatan;

  const RingkasanHariIni({
    required this.jumlahPesanan,
    required this.totalPendapatan,
  });
}
