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

  // ---------- MENU ----------

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
    await client.from('menu_items').update(item.toMap()).eq('id', item.id);
  }

  static Future<void> setMenuTersedia(String id, bool tersedia) async {
    await client.from('menu_items').update({'tersedia': tersedia}).eq('id', id);
  }

  static Future<void> deleteMenuItem(String id) async {
    await client.from('menu_items').delete().eq('id', id);
  }

  // ---------- PESANAN ----------

  static Future<Order> createOrder({
    String? namaPelanggan,
    String? meja,
    String metodePembayaran = 'cash',
    String? kasir,
    required List<CartItem> items,
  }) async {
    final totalHarga = items.fold<int>(0, (sum, e) => sum + e.subtotal);

    final orderData = await client
        .from('orders')
        .insert({
          'nama_pelanggan': namaPelanggan,
          'meja': meja,
          'metode_pembayaran': metodePembayaran,
          'kasir': kasir,
          'total_harga': totalHarga,
          'status': OrderStatus.baru.dbValue,
        })
        .select()
        .single();

    final orderId = orderData['id'] as String;

    final itemRows = items
        .map((e) => {
              'order_id': orderId,
              'menu_item_id': e.menuItemId,
              'nama_menu': e.namaMenu,
              'harga_satuan': e.hargaSatuan,
              'jumlah': e.jumlah,
              'catatan': e.catatan,
            })
        .toList();
    await client.from('order_items').insert(itemRows);

    // Balikin Order yang items-nya udah keisi, biar struk yang
    // dicetak langsung setelah nyimpen langsung punya daftar item.
    final itemsTersimpan = items
        .map((e) => OrderItem(
              id: '',
              orderId: orderId,
              menuItemId: e.menuItemId,
              namaMenu: e.namaMenu,
              hargaSatuan: e.hargaSatuan,
              jumlah: e.jumlah,
              catatan: e.catatan,
            ))
        .toList();
    return Order.fromMap(orderData, items: itemsTersimpan);
  }

  /// Riwayat pesanan terbaru beserta item-itemnya.
  static Future<List<Order>> fetchOrders({int limit = 200}) async {
    final data = await client
        .from('orders')
        .select()
        .order('created_at', ascending: false)
        .limit(limit);
    final rows = (data as List).cast<Map<String, dynamic>>();
    if (rows.isEmpty) return const [];

    final items = await _ambilItemPerOrder(rows);
    return rows
        .map((r) =>
            Order.fromMap(r, items: items[r['id'] as String] ?? const []))
        .toList();
  }

  /// Pesanan pada periode [awal .. akhir) — dipakai halaman Statistik.
  static Future<List<Order>> fetchOrdersPeriode(
      DateTime awal, DateTime akhir) async {
    final data = await client
        .from('orders')
        .select()
        .gte('created_at',
            DateTime(awal.year, awal.month, awal.day).toUtc().toIso8601String())
        .lt(
            'created_at',
            DateTime(akhir.year, akhir.month, akhir.day)
                .toUtc()
                .toIso8601String())
        .order('created_at', ascending: false);
    final rows = (data as List).cast<Map<String, dynamic>>();
    if (rows.isEmpty) return const [];

    final items = await _ambilItemPerOrder(rows);
    return rows
        .map((r) =>
            Order.fromMap(r, items: items[r['id'] as String] ?? const []))
        .toList();
  }

  /// Ambil semua order_items untuk sekumpulan baris orders,
  /// dikelompokkan berdasarkan order_id.
  static Future<Map<String, List<OrderItem>>> _ambilItemPerOrder(
      List<Map<String, dynamic>> orderRows) async {
    final itemData = await client
        .from('order_items')
        .select()
        .inFilter('order_id', orderRows.map((r) => r['id'] as String).toList());

    final perOrder = <String, List<OrderItem>>{};
    for (final row in (itemData as List).cast<Map<String, dynamic>>()) {
      final item = OrderItem.fromMap(row);
      perOrder.putIfAbsent(item.orderId, () => []).add(item);
    }
    return perOrder;
  }

  static Future<void> updateOrderStatus(
      String orderId, OrderStatus status) async {
    await client
        .from('orders')
        .update({'status': status.dbValue}).eq('id', orderId);
  }

  /// Hapus pesanan: bersihkan dulu order_items-nya, baru orders-nya.
  static Future<void> hapusOrder(String orderId) async {
    await client.from('order_items').delete().eq('order_id', orderId);
    await client.from('orders').delete().eq('id', orderId);
  }

  /// Ringkasan dashboard: jumlah pesanan + pendapatan hari ini
  /// (pesanan berstatus batal tidak dihitung di pendapatan).
  static Future<RingkasanHariIni> fetchRingkasanHariIni() async {
    final now = DateTime.now();
    final awalHari =
        DateTime(now.year, now.month, now.day).toUtc().toIso8601String();

    final data = await client
        .from('orders')
        .select('total_harga, status')
        .gte('created_at', awalHari);

    var jumlah = 0;
    var pendapatan = 0;
    for (final row in (data as List).cast<Map<String, dynamic>>()) {
      if ((row['status'] as String?) == 'batal') continue;
      jumlah++;
      pendapatan += (row['total_harga'] as int?) ?? 0;
    }
    return RingkasanHariIni(jumlahPesanan: jumlah, totalPendapatan: pendapatan);
  }

  // ---------- PENGELUARAN ----------

  static Future<List<Pengeluaran>> fetchPengeluaran() async {
    final data = await client
        .from('pengeluaran')
        .select()
        .order('created_at', ascending: false);
    return (data as List)
        .map((e) => Pengeluaran.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  static Future<Pengeluaran> addPengeluaran(Pengeluaran item) async {
    final data = await client
        .from('pengeluaran')
        .insert(item.toInsertMap())
        .select()
        .single();
    return Pengeluaran.fromMap(data);
  }

  static Future<void> hapusPengeluaran(String id) async {
    await client.from('pengeluaran').delete().eq('id', id);
  }
}

/// Hasil ringkasan dashboard (jumlah pesanan + pendapatan hari ini).
class RingkasanHariIni {
  final int jumlahPesanan;
  final int totalPendapatan;

  const RingkasanHariIni({
    required this.jumlahPesanan,
    required this.totalPendapatan,
  });
}