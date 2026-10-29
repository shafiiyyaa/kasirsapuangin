import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../menu_board/models/menu_item.dart';
import '../../theme/app_theme.dart';
import '../config_pelanggan.dart';
import '../pelanggan_provider.dart';
import 'sheet_pesanan.dart';

class MenuPelangganScreen extends StatefulWidget {
  const MenuPelangganScreen({super.key});

  @override
  State<MenuPelangganScreen> createState() => _MenuPelangganScreenState();
}

class _MenuPelangganScreenState extends State<MenuPelangganScreen> {
  final TextEditingController _cariController = TextEditingController();
  String _kategori = 'Semua';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final prov = context.read<PelangganProvider>();
      if (prov.menu.isEmpty) prov.loadMenu();
    });
  }

  @override
  void dispose() {
    _cariController.dispose();
    super.dispose();
  }

  void _bukaPesanan() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.lightBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const SheetPesanan(),
    );
  }

  List<MenuItem> _saring(List<MenuItem> semua) {
    final kata = _cariController.text.trim().toLowerCase();

    final cocok = semua.where((m) {
      final cocokKategori = _kategori == 'Semua' || m.kategori == _kategori;
      final cocokCari = kata.isEmpty ||
          m.nama.toLowerCase().contains(kata) ||
          m.kategori.toLowerCase().contains(kata);
      return cocokKategori && cocokCari;
    }).toList();

    // Menu yang tersedia tampil duluan, yang habis di bagian bawah.
    return [
      ...cocok.where((m) => m.tersedia),
      ...cocok.where((m) => !m.tersedia),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<PelangganProvider>();
    final kategoriList = ['Semua', ...prov.daftarKategori];
    final daftar = _saring(prov.menu);

    return Scaffold(
      bottomNavigationBar: prov.jumlahItem > 0
          ? _BarKeranjang(
              jumlahItem: prov.jumlahItem,
              total: prov.total,
              onTap: _bukaPesanan,
            )
          : null,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          kNamaToko,
                          style: AppTextStyles.displaySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (prov.mejaDariQr) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.sageLight.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Meja ${prov.meja}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.forestGreenDark,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Muat ulang menu',
                    onPressed: prov.loadingMenu ? null : () => prov.loadMenu(),
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TextField(
                controller: _cariController,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Cari nama atau kategori menu...',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 74,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: kategoriList.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final nama = kategoriList[i];
                  return _ChipKategori(
                    label: nama,
                    icon: nama == 'Semua'
                        ? Icons.grid_view_rounded
                        : _ikonKategori(nama),
                    dipilih: _kategori == nama,
                    onTap: () => setState(() => _kategori = nama),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Expanded(child: _isi(prov, daftar)),
          ],
        ),
      ),
    );
  }

  Widget _isi(PelangganProvider prov, List<MenuItem> daftar) {
    if (prov.loadingMenu && prov.menu.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (prov.errorMenu != null && prov.menu.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 40),
              const SizedBox(height: 12),
              Text(prov.errorMenu!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => prov.loadMenu(),
                child: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (daftar.isEmpty) {
      return const Center(child: Text('Menu tidak ditemukan.'));
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 224,
      ),
      itemCount: daftar.length,
      itemBuilder: (context, i) {
        final menu = daftar[i];
        return _KartuMenu(
          menu: menu,
          jumlah: prov.jumlahDi(menu.id),
          onTambah: () => prov.tambah(menu),
          onKurang: () => prov.kurang(menu.id),
        );
      },
    );
  }
}

IconData _ikonKategori(String kategori) {
  final value = kategori.toLowerCase();
  if (value.contains('non coffee') || value.contains('non-coffee')) {
    return Icons.local_drink_rounded;
  }
  if (value.contains('coffee')) return Icons.coffee_rounded;
  if (value.contains('milk')) return Icons.local_cafe_rounded;
  if (value.contains('brew')) return Icons.coffee_maker_rounded;
  if (value.contains('snack')) return Icons.lunch_dining_rounded;
  if (value.contains('camilan')) return Icons.bakery_dining_rounded;
  if (value.contains('food') || value.contains('makanan')) {
    return Icons.restaurant_rounded;
  }
  if (value.contains('dessert') || value.contains('roti')) {
    return Icons.cake_rounded;
  }
  return Icons.restaurant_menu_rounded;
}

class _ChipKategori extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool dipilih;
  final VoidCallback onTap;

  const _ChipKategori({
    required this.label,
    required this.icon,
    required this.dipilih,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final warnaTeks =
        dipilih ? AppColors.textOnGreen : AppColors.lightTextPrimary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        constraints: const BoxConstraints(minWidth: 72),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: dipilih ? AppColors.forestGreen : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: dipilih ? AppColors.forestGreen : AppColors.lightBorder,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: warnaTeks),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: warnaTeks,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KartuMenu extends StatelessWidget {
  final MenuItem menu;
  final int jumlah;
  final VoidCallback onTambah;
  final VoidCallback onKurang;

  const _KartuMenu({
    required this.menu,
    required this.jumlah,
    required this.onTambah,
    required this.onKurang,
  });

  Widget _placeholder() {
    return Container(
      color: AppColors.lightSurfaceAlt,
      child: Center(
        child: Icon(
          _ikonKategori(menu.kategori),
          size: 34,
          color: AppColors.forestGreen,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final habis = !menu.tersedia;
    final punyaFoto = menu.gambarUrl != null && menu.gambarUrl!.isNotEmpty;

    return Opacity(
      opacity: habis ? 0.55 : 1,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  height: 92,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      punyaFoto
                          ? Image.network(
                              menu.gambarUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _placeholder(),
                            )
                          : _placeholder(),
                      if (habis)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Habis',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                menu.nama,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                menu.kategori,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.lightTextSecondary,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        rupiah(menu.harga),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.forestGreen,
                        ),
                      ),
                    ),
                  ),
                  if (!habis)
                    StepperJumlah(
                      jumlah: jumlah,
                      onTambah: onTambah,
                      onKurang: onKurang,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tombol "+" (kalau jumlah 0) atau  "- 2 +" (kalau sudah dipilih).
class StepperJumlah extends StatelessWidget {
  final int jumlah;
  final VoidCallback onTambah;
  final VoidCallback onKurang;

  const StepperJumlah({
    super.key,
    required this.jumlah,
    required this.onTambah,
    required this.onKurang,
  });

  Widget _tombol(IconData icon, VoidCallback onTap, {required bool isi}) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isi ? AppColors.forestGreen : Colors.transparent,
          border: Border.all(color: AppColors.forestGreen, width: 1.5),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isi ? Colors.white : AppColors.forestGreen,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (jumlah == 0) {
      return _tombol(Icons.add_rounded, onTambah, isi: true);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _tombol(Icons.remove_rounded, onKurang, isi: false),
        SizedBox(
          width: 28,
          child: Text(
            '$jumlah',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ),
        _tombol(Icons.add_rounded, onTambah, isi: true),
      ],
    );
  }
}

class _BarKeranjang extends StatelessWidget {
  final int jumlahItem;
  final int total;
  final VoidCallback onTap;

  const _BarKeranjang({
    required this.jumlahItem,
    required this.total,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Material(
          color: AppColors.forestGreen,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const Icon(Icons.shopping_bag_outlined,
                      color: AppColors.textOnGreen),
                  const SizedBox(width: 10),
                  Text(
                    '$jumlahItem item  •  ${rupiah(total)}',
                    style: const TextStyle(
                      color: AppColors.textOnGreen,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'Lihat pesanan',
                    style: TextStyle(
                      color: AppColors.textOnGreen,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right_rounded,
                      color: AppColors.textOnGreen),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}