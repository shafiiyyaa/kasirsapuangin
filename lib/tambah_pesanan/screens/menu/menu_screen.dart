import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../menu_board/models/menu_item.dart';
import '../../../menu_board/providers/menu_provider.dart';
import '../../../theme/app_theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/menu_item_card.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _kategoriTerpilih; // null = Semua
  bool _tampilanList = false; // false = grid, true = list

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
      return cocokKategori && cocokQuery;
    }).toList();
  }

  Map<String, List<MenuItem>> _kelompokkanPerKategori(List<MenuItem> items) {
    final map = <String, List<MenuItem>>{};
    for (final item in items) {
      map.putIfAbsent(item.kategori, () => []).add(item);
    }
    return map;
  }

  Future<void> _toggleTersedia(MenuItem item) async {
    final provider = context.read<MenuProvider>();
    try {
      await provider.ubahStatusTersedia(item.id, !item.tersedia);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengubah status: $e')),
      );
    }
  }

  Widget _buildFilterChips(MenuProvider provider) {
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Menu'),
        leading: AppScaffold.isWide(context) ? null : IconButton(
          icon: const Icon(Icons.menu),
          tooltip: 'Buka menu',
          onPressed: () => AppScaffold.openMenu(context),
        ),
        actions: [
          IconButton(
            tooltip: _tampilanList ? 'Tampilan grid' : 'Tampilan list',
            icon: Icon(
              _tampilanList
                  ? Icons.grid_view_outlined
                  : Icons.view_list_outlined,
            ),
            onPressed: () => setState(() => _tampilanList = !_tampilanList),
          ),
        ],
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
          Consumer<MenuProvider>(
            builder: (context, provider, _) => _buildFilterChips(provider),
          ),
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
                      'Menu tidak ditemukan.',
                      style: AppTextStyles.bodyMedium,
                    ),
                  );
                }

                final grouped = _kelompokkanPerKategori(filtered);

                return RefreshIndicator(
                  onRefresh: provider.loadMenu,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    children: grouped.entries.map((entry) {
                      return _KategoriSection(
                        judul: entry.key,
                        items: entry.value,
                        onToggleTersedia: _toggleTersedia,
                        tampilanList: _tampilanList,
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
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
  final ValueChanged<MenuItem> onToggleTersedia;
  final bool tampilanList;

  const _KategoriSection({
    required this.judul,
    required this.items,
    required this.onToggleTersedia,
    required this.tampilanList,
  });

  Widget _switch(MenuItem item) {
    return Switch(
      value: item.tersedia,
      onChanged: (_) => onToggleTersedia(item),
      activeThumbColor: AppColors.forestGreen,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Text(judul, style: AppTextStyles.displayMedium),
        ),
        if (tampilanList)
          Column(
            children: [
              for (final item in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: MenuItemListTile(
                    item: item,
                    trailing: _switch(item),
                  ),
                ),
            ],
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final kolom = kolomMenuUntukLebar(constraints.maxWidth);
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: items.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: kolom,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  mainAxisExtent: tinggiKartuMenu(kolom),
                ),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return MenuItemCard(
                    item: item,
                    trailing: _switch(item),
                  );
                },
              );
            },
          ),
      ],
    );
  }
}