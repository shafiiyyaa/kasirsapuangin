import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../menu_board/models/menu_item.dart';
import '../../../menu_board/models/order_item.dart';
import '../../../menu_board/providers/menu_provider.dart';
import '../../../menu_board/providers/order_provider.dart';
import '../../../theme/app_theme.dart';
import '../../widgets/menu_item_card.dart';

class AddOrderScreen extends StatefulWidget {
  const AddOrderScreen({super.key});

  @override
  State<AddOrderScreen> createState() => _AddOrderScreenState();
}

class _AddOrderScreenState extends State<AddOrderScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _kategoriTerpilih;

  /// Urutan tampil chip sesuai menu fisik; kategori di luar daftar
  /// ini tetap muncul, ditaruh di paling belakang.
  static const _urutanKategori = [
    'Camilan',
    'Snacks',
    'Food',
    'Manual Brew',
    'Milk Based',
    'Coffee Based',
    'Non Coffee',
    'Mocktail',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MenuProvider>().loadMenu();
    });
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MenuItem> _terapkanFilter(List<MenuItem> items) {
    return items.where((e) {
      final cocokKategori =
          _kategoriTerpilih == null || e.kategori == _kategoriTerpilih;
      final cocokQuery =
          _query.isEmpty || e.nama.toLowerCase().contains(_query);
      return cocokKategori && cocokQuery && e.tersedia;
    }).toList();
  }

  Map<String, List<MenuItem>> _kelompokkanPerKategori(List<MenuItem> items) {
    final map = <String, List<MenuItem>>{};
    for (final item in items) {
      map.putIfAbsent(item.kategori, () => []).add(item);
    }
    return map;
  }

  void _tambahCepat(MenuItem item) {
    context.read<OrderProvider>().tambahKeKeranjang(
          CartItem(
            menuItemId: item.id,
            namaMenu: item.nama,
            hargaSatuan: item.harga,
          ),
        );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 900),
        content: Text('${item.nama} ditambahkan ke keranjang'),
      ),
    );
  }

  void _bukaKeranjang() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CartSheet(),
    );
  }

  Widget _buildFilterChips() {
    return Consumer<MenuProvider>(
      builder: (context, provider, _) {
        final kategoris = [...provider.kategoriList]..sort((a, b) {
            final ia = _urutanKategori.indexOf(a);
            final ib = _urutanKategori.indexOf(b);
            return (ia < 0 ? 999 : ia).compareTo(ib < 0 ? 999 : ib);
          });

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _FilterChip(
                label: 'Semua',
                selected: _kategoriTerpilih == null,
                onTap: () => setState(() => _kategoriTerpilih = null),
              ),
              for (final k in kategoris) ...[
                const SizedBox(width: 8),
                _FilterChip(
                  label: k,
                  selected: _kategoriTerpilih == k,
                  onTap: () => setState(() => _kategoriTerpilih = k),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Pesanan'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Cari menu...',
                prefixIcon: Icon(Icons.search, size: 20),
              ),
            ),
          ),
          _buildFilterChips(),
          const SizedBox(height: 8),
          Expanded(
            child: Consumer<MenuProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading && provider.items.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.error != null && provider.items.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            provider.error!,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyMedium,
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: () => provider.loadMenu(),
                            child: const Text('Coba Lagi'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final filtered = _terapkanFilter(provider.items);

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      'Menu tidak ditemukan / semua lagi habis.',
                      style: AppTextStyles.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                final grouped = _kelompokkanPerKategori(filtered);

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                  children: grouped.entries.map((entry) {
                    return _KategoriSection(
                      judul: entry.key,
                      items: entry.value,
                      onTap: _tambahCepat,
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
      bottomSheet: Consumer<OrderProvider>(
        builder: (context, orderProvider, _) {
          if (orderProvider.cart.isEmpty) return const SizedBox.shrink();
          return _CartBar(
            jumlahItem: orderProvider.jumlahItemCart,
            total: orderProvider.totalCart,
            onTap: _bukaKeranjang,
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.forestGreen : AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.forestGreen : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: selected ? AppColors.textOnGreen : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _KategoriSection extends StatelessWidget {
  final String judul;
  final List<MenuItem> items;
  final ValueChanged<MenuItem> onTap;

  const _KategoriSection({
    required this.judul,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Text(judul, style: AppTextStyles.displayMedium),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return MenuItemCard(
              item: item,
              onTap: () => onTap(item),
              trailing: const Icon(
                Icons.add_circle,
                color: AppColors.forestGreen,
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Bar ringkas persisten di bawah layar, muncul begitu keranjang gak kosong.
class _CartBar extends StatelessWidget {
  final int jumlahItem;
  final int total;
  final VoidCallback onTap;

  const _CartBar({
    required this.jumlahItem,
    required this.total,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.forestGreen,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$jumlahItem item • ${_formatRupiah(total)}',
                style: AppTextStyles.button,
              ),
              Row(
                children: [
                  Text('Lihat Keranjang', style: AppTextStyles.button),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet keranjang: atur jumlah/catatan per item, isi nama
/// pelanggan & nomor meja (opsional), lalu simpan pesanan ke Supabase.
class _CartSheet extends StatefulWidget {
  const _CartSheet();

  @override
  State<_CartSheet> createState() => _CartSheetState();
}

class _CartSheetState extends State<_CartSheet> {
  final _namaController = TextEditingController();
  final _mejaController = TextEditingController();

  @override
  void dispose() {
    _namaController.dispose();
    _mejaController.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    final provider = context.read<OrderProvider>();
    final nama = _namaController.text.trim();
    final meja = _mejaController.text.trim();
    provider.setNamaPelanggan(nama.isEmpty ? null : nama);
    provider.setMeja(meja.isEmpty ? null : meja);

    try {
      final order = await provider.simpanPesanan();
      if (!mounted) return;

      if (order != null) {
        Navigator.of(context).pop(); // tutup sheet keranjang
        if (mounted) {
          context.pop(); // balik dari layar Tambah Pesanan
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pesanan berhasil disimpan')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan pesanan: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Consumer<OrderProvider>(
            builder: (context, orderProvider, _) {
              return Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Keranjang', style: AppTextStyles.displayMedium),
                  ),
                  Expanded(
                    child: orderProvider.cart.isEmpty
                        ? Center(
                            child: Text(
                              'Keranjang kosong',
                              style: AppTextStyles.bodyMedium,
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: orderProvider.cart.length,
                            itemBuilder: (context, index) {
                              final item = orderProvider.cart[index];
                              return _CartItemTile(
                                item: item,
                                onTambah: () =>
                                    orderProvider.ubahJumlah(index, item.jumlah + 1),
                                onKurang: () =>
                                    orderProvider.ubahJumlah(index, item.jumlah - 1),
                                onHapus: () =>
                                    orderProvider.hapusDariKeranjang(index),
                                onCatatanBerubah: (catatan) =>
                                    item.catatan = catatan,
                              );
                            },
                          ),
                  ),
                  if (orderProvider.cart.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: _namaController,
                                  decoration: const InputDecoration(
                                    hintText: 'Nama pelanggan (opsional)',
                                    isDense: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: _mejaController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    hintText: 'Meja',
                                    isDense: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Total', style: AppTextStyles.bodyLarge),
                              Text(
                                _formatRupiah(orderProvider.totalCart),
                                style: AppTextStyles.priceLarge,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed:
                                orderProvider.isSubmitting ? null : _simpan,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(50),
                            ),
                            child: orderProvider.isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Simpan Pesanan'),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final CartItem item;
  final VoidCallback onTambah;
  final VoidCallback onKurang;
  final VoidCallback onHapus;
  final ValueChanged<String> onCatatanBerubah;

  const _CartItemTile({
    required this.item,
    required this.onTambah,
    required this.onKurang,
    required this.onHapus,
    required this.onCatatanBerubah,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(item.namaMenu, style: AppTextStyles.bodyLarge),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: AppColors.statusBatal,
                  ),
                  onPressed: onHapus,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatRupiah(item.subtotal), style: AppTextStyles.price),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: onKurang,
                      visualDensity: VisualDensity.compact,
                    ),
                    Text('${item.jumlah}', style: AppTextStyles.bodyLarge),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: onTambah,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ],
            ),
            TextField(
              decoration: const InputDecoration(
                hintText: 'Catatan (mis. pedas, tanpa es)',
                isDense: true,
              ),
              style: AppTextStyles.bodySmall,
              onChanged: onCatatanBerubah,
            ),
          ],
        ),
      ),
    );
  }
}

String _formatRupiah(int angka) {
  final str = angka.toString();
  final buffer = StringBuffer();
  for (int i = 0; i < str.length; i++) {
    final posFromRight = str.length - i;
    buffer.write(str[i]);
    if (posFromRight > 1 && posFromRight % 3 == 1) {
      buffer.write('.');
    }
  }
  return 'Rp$buffer';
}