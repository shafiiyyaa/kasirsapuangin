import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../menu_board/models/menu_item.dart';
import '../../../menu_board/providers/menu_provider.dart';
import '../../../theme/app_theme.dart';
import '../../widgets/app_scaffold.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String? _selectedCategory;
  bool _gridView = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<MenuProvider>().loadMenu();
    });
    _searchController.addListener(() {
      final next = _searchController.text.trim().toLowerCase();
      if (next != _query && mounted) setState(() => _query = next);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MenuItem> _filterMenu(List<MenuItem> items) {
    return items.where((item) {
      final matchesQuery = _query.isEmpty ||
          item.nama.toLowerCase().contains(_query) ||
          item.kategori.toLowerCase().contains(_query);
      final matchesCategory =
          _selectedCategory == null || item.kategori == _selectedCategory;
      return matchesQuery && matchesCategory;
    }).toList();
  }

  Future<void> _toggleAvailability(MenuItem item) async {
    try {
      await context
          .read<MenuProvider>()
          .ubahStatusTersedia(item.id, !item.tersedia);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(item.tersedia
              ? '${item.nama} ditandai habis.'
              : '${item.nama} tersedia kembali.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengubah status menu: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppScaffold.isWide(context)
          ? null
          : AppBar(
              automaticallyImplyLeading: false,
              title: const Text('Menu'),
              leading: IconButton(
                icon: const Icon(Icons.menu),
                tooltip: 'Buka menu',
                onPressed: () => AppScaffold.openMenu(context),
              ),
            ),
      body: Consumer<MenuProvider>(
        builder: (context, provider, _) {
          final categories = provider.kategoriList;
          final filtered = _filterMenu(provider.items);

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
                      onPressed: provider.loadMenu,
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: provider.loadMenu,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari nama atau kategori menu...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Hapus pencarian',
                            onPressed: _searchController.clear,
                            icon: const Icon(Icons.close_rounded),
                          ),
                    filled: true,
                    fillColor: scheme.surface,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Kategori',
                  style: AppTextStyles.displaySmall.copyWith(
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 9),
                SizedBox(
                  height: 94,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _CategoryTile(
                        label: 'Semua',
                        icon: Icons.grid_view_rounded,
                        selected: _selectedCategory == null,
                        onTap: () => setState(() => _selectedCategory = null),
                      ),
                      for (final category in categories)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: _CategoryTile(
                            label: category,
                            icon: _iconForCategory(category),
                            selected: _selectedCategory == category,
                            onTap: () => setState(
                              () => _selectedCategory = category,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Daftar Menu',
                            style: AppTextStyles.displaySmall.copyWith(
                              color: scheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Atur ketersediaan menu',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Tampilan grid',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => setState(() => _gridView = true),
                      style: IconButton.styleFrom(
                        backgroundColor: _gridView
                            ? scheme.primary.withOpacity(0.12)
                            : Colors.transparent,
                        foregroundColor: _gridView
                            ? scheme.primary
                            : scheme.onSurfaceVariant,
                      ),
                      icon: const Icon(Icons.grid_view_rounded),
                    ),
                    IconButton(
                      tooltip: 'Tampilan list',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => setState(() => _gridView = false),
                      style: IconButton.styleFrom(
                        backgroundColor: !_gridView
                            ? scheme.primary.withOpacity(0.12)
                            : Colors.transparent,
                        foregroundColor: !_gridView
                            ? scheme.primary
                            : scheme.onSurfaceVariant,
                      ),
                      icon: const Icon(Icons.view_list_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 42),
                    child: Column(
                      children: [
                        Icon(Icons.search_off_rounded,
                            size: 38, color: scheme.onSurfaceVariant),
                        const SizedBox(height: 8),
                        const Text('Menu tidak ditemukan.',
                            style: AppTextStyles.bodyMedium),
                      ],
                    ),
                  )
                else if (_gridView)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isLandscape =
                          MediaQuery.orientationOf(context) == Orientation.landscape;
                      // Empat kolom saat landscape, dua kolom saat portrait.
                      final columns = isLandscape ? 4 : 2;
                      return GridView.builder(
                        itemCount: filtered.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          mainAxisExtent: isLandscape ? 184 : 198,
                        ),
                        itemBuilder: (context, index) => _MenuGridCard(
                          item: filtered[index],
                          onToggle: () => _toggleAvailability(filtered[index]),
                        ),
                      );
                    },
                  )
                else
                  Column(
                    children: [
                      for (final item in filtered)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _MenuListRow(
                            item: item,
                            onToggle: () => _toggleAvailability(item),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

IconData _iconForCategory(String category) {
  final value = category.toLowerCase();
  if (value.contains('coffee')) return Icons.coffee_rounded;
  if (value.contains('non coffee') || value.contains('non-coffee')) {
    return Icons.local_drink_rounded;
  }
  if (value.contains('milk')) return Icons.local_cafe_rounded;
  if (value.contains('manual brew') || value.contains('brew')) {
    return Icons.coffee_maker_rounded;
  }
  if (value.contains('snack') || value.contains('camilan')) {
    return Icons.lunch_dining_rounded;
  }
  if (value.contains('food') || value.contains('makanan')) {
    return Icons.restaurant_rounded;
  }
  if (value.contains('dessert') || value.contains('roti')) {
    return Icons.cake_rounded;
  }
  if (value.contains('mocktail') || value.contains('drink')) {
    return Icons.local_bar_rounded;
  }
  return Icons.restaurant_menu_rounded;
}

class _CategoryTile extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_CategoryTile> createState() => _CategoryTileState();
}

class _CategoryTileState extends State<_CategoryTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background = widget.selected
        ? scheme.primary
        : (_hovered ? scheme.primary.withOpacity(0.08) : scheme.surface);
    final foreground = widget.selected ? scheme.onPrimary : scheme.primary;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        width: 116,
        height: 94,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.selected ? scheme.primary : scheme.outlineVariant,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(widget.icon, size: 28, color: foreground),
                  const SizedBox(height: 7),
                  Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuGridCard extends StatelessWidget {
  final MenuItem item;
  final VoidCallback onToggle;

  const _MenuGridCard({required this.item, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final available = item.tersedia;
    final fallbackIcon = item.tipe.toLowerCase() == 'minuman'
        ? Icons.local_cafe_rounded
        : Icons.restaurant_rounded;

    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: double.infinity,
                color: scheme.surfaceContainerHighest,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (item.gambarUrl != null && item.gambarUrl!.trim().isNotEmpty)
                      Image.network(
                        item.gambarUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Icon(fallbackIcon,
                              size: 34, color: scheme.primary),
                        ),
                      )
                    else
                      Center(
                        child: Icon(fallbackIcon,
                            size: 34, color: scheme.primary),
                      ),
                    Positioned(
                      top: 5,
                      right: 5,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 4),
                        decoration: BoxDecoration(
                          color: available
                              ? scheme.tertiaryContainer
                              : scheme.errorContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          available ? 'Tersedia' : 'Habis',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: available
                                ? scheme.onTertiaryContainer
                                : scheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            item.nama,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.titleSmall.copyWith(color: scheme.onSurface),
          ),
          Text(
            item.kategori,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall.copyWith(
              color: scheme.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  _rupiah(item.harga),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.price.copyWith(fontSize: 12),
                ),
              ),
              SizedBox(
                width: 30,
                height: 30,
                child: IconButton.filled(
                  tooltip: available ? 'Tandai habis' : 'Aktifkan kembali',
                  onPressed: onToggle,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  style: IconButton.styleFrom(
                    backgroundColor: available ? scheme.primary : scheme.error,
                    foregroundColor: scheme.onPrimary,
                  ),
                  icon: Icon(
                    available ? Icons.check_rounded : Icons.refresh_rounded,
                    size: 17,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MenuListRow extends StatelessWidget {
  final MenuItem item;
  final VoidCallback onToggle;

  const _MenuListRow({required this.item, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final available = item.tersedia;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.nama,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.titleSmall),
                const SizedBox(height: 2),
                Text(item.kategori,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                        color: scheme.onSurfaceVariant)),
                const SizedBox(height: 3),
                Text(_rupiah(item.harga), style: AppTextStyles.price),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 34,
            height: 34,
            child: IconButton.filled(
              tooltip: available ? 'Tandai habis' : 'Aktifkan kembali',
              onPressed: onToggle,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              style: IconButton.styleFrom(
                backgroundColor: available ? scheme.primary : scheme.error,
                foregroundColor: scheme.onPrimary,
              ),
              icon: Icon(
                available ? Icons.check_rounded : Icons.refresh_rounded,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _rupiah(num nominal) {
  final digits = nominal.toInt().toString();
  final grouped = digits.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '.',
  );
  return 'Rp $grouped';
}
