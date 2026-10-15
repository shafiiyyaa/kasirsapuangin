import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/menu_item.dart';
import '../models/order.dart';
import '../models/order_item.dart';

const String supabaseUrl = 'https://nbsemkswjlvnzwwlyhhg.supabase.co';
const String supabasePublishableKey =
    'sb_publishable_K1QMR9WNPheN5IaWY4gMLQ_3uOw8p3l';

/// Satu pintu untuk semua akses ke Supabase.
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
    required List<CartItem> items,
  }) async {
    final totalHarga = items.fold<int>(0, (sum, e) => sum + e.subtotal);

    final orderData = await client
        .from('orders')
        .insert({
          'nama_pelanggan': namaPelanggan,
          'meja': meja,
          'metode_pembayaran': metodePembayaran,
          'total_harga': totalHarga,
          'status': OrderStatus.baru.dbValue,
        })
        .select()
        .single();

    final order = Order.fromMap(orderData);

    final itemRows = items
        .map((e) => {
              'order_id': order.id,
              'menu_item_id': e.menuItemId,
              'nama_menu': e.namaMenu,
              'harga_satuan': e.hargaSatuan,
              'jumlah': e.jumlah,
              'catatan': e.catatan,
            })
        .toList();

    final insertedItems =
        await client.from('order_items').insert(itemRows).select();

    final orderItems = (insertedItems as List)
        .map((e) => OrderItem.fromMap(e as Map<String, dynamic>))
        .toList();

    return order.copyWith(items: orderItems);
  }

  static Future<List<Order>> fetchOrders({int limit = 50}) async {
    final data = await client
        .from('orders')
        .select('*, order_items(*)')
        .order('created_at', ascending: false)
        .limit(limit);

    return (data as List).map((e) {
      final map = e as Map<String, dynamic>;
      final itemsRaw = map['order_items'] as List? ?? [];
      final items = itemsRaw
          .map((i) => OrderItem.fromMap(i as Map<String, dynamic>))
          .toList();
      return Order.fromMap(map, items: items);
    }).toList();
  }

  static Future<void> updateOrderStatus(
      String orderId, OrderStatus status) async {
    await client
        .from('orders')
        .update({'status': status.dbValue}).eq('id', orderId);
  }

  // ---------- DASHBOARD ----------

  static Future<({int jumlahPesanan, int totalPendapatan})>
      fetchRingkasanHariIni() async {
    final now = DateTime.now();
    final awalHari = DateTime(now.year, now.month, now.day).toUtc();

    final data = await client
        .from('orders')
        .select('total_harga, status')
        .gte('created_at', awalHari.toIso8601String())
        .neq('status', OrderStatus.batal.dbValue);

    final rows = data as List;
    final totalPendapatan = rows.fold<int>(
      0,
      (sum, e) => sum + (e['total_harga'] as int),
    );

    return (jumlahPesanan: rows.length, totalPendapatan: totalPendapatan);
  }
}