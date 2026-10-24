import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ⚠️ PENTING: samain 5 import di bawah sama struktur folder kamu.
//    Cara cek: liat file dashboard_screen.dart kamu pake berapa ../ buat theme.
import '../../../menu_board/models/order.dart';
import '../../../menu_board/providers/order_provider.dart';
import '../../services/receipt_service.dart'; // ← sesuaikan lokasi receipt_service.dart kamu
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../widgets/app_scaffold.dart';

String rupiah(num nominal) {
  final digits = nominal.toInt().toString();
  final grouped = digits.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '.',
  );
  return 'Rp $grouped';
}

class AddOrderScreen extends StatefulWidget {
  const AddOrderScreen({super.key});

  @override
  State<AddOrderScreen> createState() => _AddOrderScreenState();
}

class _AddOrderScreenState extends State<AddOrderScreen> {
  static const String _semua = 'Semua';
  String _kategoriDipilih = _semua;

  List<Map<String, dynamic>> _menu = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _muatMenu();
  }

  Future<void> _muatMenu() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await Supabase.instance.client
          .from('menu_items')
          .select()
          .order('kategori', ascending: true)
          .order('nama', ascending: true);
      if (!mounted) return;
      setState(() {
        _menu = (res as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // ---- helper baca data menu (nama kolom sama kaya Kelola Menu) ----
  String _id(Map<String, dynamic> m) => (m['id'] ?? '').toString();
  String _nama(Map<String, dynamic> m) => (m['nama'] ?? '-').toString();
  String _kategori(Map<String, dynamic> m) =>
      (m['kategori'] ?? 'Lainnya').toString();
  int _harga(Map<String, dynamic> m) => (m['harga'] as num?)?.toInt() ?? 0;
  bool _tersedia(Map<String, dynamic> m) => (m['tersedia'] ?? true) == true;

  List<String> get _kategoriUnik {
    final set = <String>{};
    for (final m in _menu) {
      set.add(_kategori(m));
    }
    final list = set.toList()..sort();
    return [_semua, ...list];
  }

  List<Map<String, dynamic>> get _hasil {
    return _menu.where((m) {
      if (!_tersedia(m)) return false;
      if (_kategoriDipilih != _semua && _kategori(m) != _kategoriDipilih) {
        return false;
      }
      return true;
    }).toList();
  }

  int _jumlahDiKeranjang(List<CartItem> cart, String menuItemId) {
    for (final c in cart) {
      if (c.menuItemId == menuItemId) return c.jumlah;
    }
    return 0;
  }

  Future<void> _bukaKeranjang() async {
    final pesanan = await showModalBottomSheet<Order>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CartSheet(),
    );
    if (pesanan == null || !mounted) return;
    context.read<OrderProvider>().loadRingkasanHariIni(); // refresh statistik
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Pesanan tersimpan • ${rupiah(pesanan.totalHarga)}',
          style: const TextStyle(
            color: Color(0xFF285B3A),
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: const Color(0xFFF0F8F1),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFB8DCC0), width: 1),
        ),
        action: SnackBarAction(
          label: 'Cetak Struk',
          textColor: const Color(0xFF285B3A),
          onPressed: () => ReceiptService.cetakStruk(pesanan),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final kategoriList = _kategoriUnik;
    final hasil = _hasil;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppScaffold.isWide(context)
          ? null
          : AppBar(
              title: const Text('Tambah Pesanan'),
              leading: IconButton(
                icon: const Icon(Icons.menu),
                tooltip: 'Buka menu',
                onPressed: () => AppScaffold.openMenu(context),
              ),
            ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.forestGreen))
          : _error != null
              ? _TampilanKosong(
                  icon: Icons.cloud_off_rounded,
                  judul: 'Gagal memuat menu',
                  pesan: _error!,
                  aksiLabel: 'Coba Lagi',
                  onAksi: _muatMenu,
                )
              : Column(
                  children: [
                    _barisKategori(kategoriList),
                    Expanded(
                      child: hasil.isEmpty
                          ? const _TampilanKosong(
                              icon: Icons.storefront_rounded,
                              judul: 'Belum ada menu',
                              pesan:
                                  'Tambahkan menu dulu di Pengaturan > Kelola Menu.',
                            )
                          : Consumer<OrderProvider>(
                              builder: (context, orderProv, _) {
                                return GridView.builder(
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 4, 16, 16),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                    childAspectRatio: 0.95,
                                  ),
                                  itemCount: hasil.length,
                                  itemBuilder: (context, i) {
                                    final menu = hasil[i];
                                    final id = _id(menu);
                                    return _KartuMenu(
                                      menu: menu,
                                      jumlahDiKeranjang: _jumlahDiKeranjang(
                                          orderProv.cart, id),
                                      rupiah: rupiah(_harga(menu)),
                                      onTap: () {
                                        orderProv.tambahKeKeranjang(
                                          menuItemId: id,
                                          namaMenu: _nama(menu),
                                          hargaSatuan: _harga(menu),
                                        );
                                      },
                                    );
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
      bottomNavigationBar: Consumer<OrderProvider>(
        builder: (context, prov, _) {
          final jumlah = prov.jumlahItemKeranjang;
          return Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: 12 + MediaQuery.of(context).padding.bottom,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Total keranjang',
                          style: AppTextStyles.bodySmall),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(rupiah(prov.totalKeranjang),
                            style: AppTextStyles.priceLarge),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: jumlah == 0 ? null : _bukaKeranjang,
                  icon: const Icon(Icons.shopping_cart_rounded, size: 18),
                  label: Text('Keranjang ($jumlah)'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _barisKategori(List<String> kategoriList) {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: kategoriList.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final k = kategoriList[i];
          final terpilih = k == _kategoriDipilih;
          return ChoiceChip(
            label: Text(k),
            selected: terpilih,
            onSelected: (_) => setState(() => _kategoriDipilih = k),
            selectedColor: AppColors.forestGreen,
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: terpilih ? AppColors.putih : AppColors.textSecondary,
            ),
            showCheckmark: false,
            side: BorderSide(
                color: terpilih ? AppColors.forestGreen : AppColors.border),
            backgroundColor: AppColors.surface,
          );
        },
      ),
    );
  }
}

// =============================================================
// KERANJANG (bottom sheet yang bisa ditarik)
// =============================================================
class _CartSheet extends StatefulWidget {
  const _CartSheet();

  @override
  State<_CartSheet> createState() => _CartSheetState();
}

class _CartSheetState extends State<_CartSheet> {
  static const Map<String, String> _labelMetode = {
    'cash': 'Cash',
    'qris': 'QRIS',
    'transfer': 'Transfer',
  };

  late final TextEditingController _kasirC;
  late final TextEditingController _namaC;
  late final TextEditingController _mejaC;
  String _jenisPesanan = 'dine_in';

  @override
  void initState() {
    super.initState();
    final prov = context.read<OrderProvider>();
    _kasirC = TextEditingController(text: prov.kasir);
    _namaC = TextEditingController(text: prov.namaPelanggan);
    _mejaC = TextEditingController(text: prov.meja);
    _jenisPesanan = prov.jenisPesanan;
  }

  @override
  void dispose() {
    _kasirC.dispose();
    _namaC.dispose();
    _mejaC.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    if (_kasirC.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Isi dulu nama kasirnya ya'),
          backgroundColor: AppColors.statusBatal,
        ),
      );
      return;
    }
    final prov = context.read<OrderProvider>();
    prov.setKasir(_kasirC.text);
    prov.setNamaPelanggan(_namaC.text);
    prov.setJenisPesanan(_jenisPesanan);
    prov.setMeja(_jenisPesanan == 'dine_in' ? _mejaC.text : '');

    final pesanan = await prov.simpanPesanan();
    if (!mounted) return;
    if (pesanan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(prov.pesanError ?? 'Gagal menyimpan pesanan'),
          backgroundColor: AppColors.statusBatal,
        ),
      );
      return;
    }
    Navigator.of(context).pop(pesanan); // balikin hasil ke layar utama
  }

  Future<void> _editCatatan(CartItem item) async {
    final c = TextEditingController(text: item.catatan ?? '');
    final hasil = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Catatan — ${item.namaMenu}',
            style: AppTextStyles.titleMedium),
        content: TextField(
          controller: c,
          autofocus: true,
          maxLines: 2,
          decoration: const InputDecoration(
            hintText: 'misal: less sugar, take away',
            isDense: true,
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: AppColors.forestGreen),
            onPressed: () => Navigator.pop(context, c.text),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (hasil != null) {
      context.read<OrderProvider>().ubahCatatan(item.menuItemId, hasil);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Consumer<OrderProvider>(
            builder: (context, prov, _) {
              return ListView(
                controller: scrollController,
                padding: EdgeInsets.fromLTRB(
                    16, 10, 16, MediaQuery.of(context).viewInsets.bottom + 24),
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Expanded(
                          child: Text('Keranjang',
                              style: AppTextStyles.displaySmall)),
                      if (!prov.keranjangKosong)
                        TextButton(
                          onPressed: prov.kosongkanKeranjang,
                          child: const Text('Kosongkan',
                              style: TextStyle(color: AppColors.statusBatal)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // ===== NAMA KASIR (BARU) =====
                  _Field(
                    controller: _kasirC,
                    label: 'Nama Kasir',
                    hint: 'misal: Rani',
                    icon: Icons.badge_rounded,
                  ),
                  const SizedBox(height: 10),
                  _Field(
                    controller: _namaC,
                    label: 'Nama Pelanggan (opsional)',
                    hint: 'misal: Bu Ita',
                    icon: Icons.person_rounded,
                  ),
                  const SizedBox(height: 10),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Jenis Pesanan',
                      style: AppTextStyles.titleSmall,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        avatar: const Icon(
                          Icons.table_restaurant_rounded,
                          size: 18,
                        ),
                        label: const Text('Dine-in'),
                        selected: _jenisPesanan == 'dine_in',
                        onSelected: (_) {
                          setState(() => _jenisPesanan = 'dine_in');
                        },
                        showCheckmark: false,
                        selectedColor:
                            AppColors.forestGreen.withValues(alpha: 0.14),
                        backgroundColor: AppColors.surface,
                        side: BorderSide(
                          color: _jenisPesanan == 'dine_in'
                              ? AppColors.forestGreen
                              : AppColors.border,
                        ),
                      ),
                      ChoiceChip(
                        avatar: const Icon(
                          Icons.takeout_dining_rounded,
                          size: 18,
                        ),
                        label: const Text('Takeaway'),
                        selected: _jenisPesanan == 'takeaway',
                        onSelected: (_) {
                          setState(() => _jenisPesanan = 'takeaway');
                        },
                        showCheckmark: false,
                        selectedColor: Colors.lightBlue.withValues(alpha: 0.13),
                        backgroundColor: AppColors.surface,
                        side: BorderSide(
                          color: _jenisPesanan == 'takeaway'
                              ? Colors.lightBlue
                              : AppColors.border,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_jenisPesanan == 'dine_in')
                    _Field(
                      controller: _mejaC,
                      label: 'Nomor Meja (opsional)',
                      hint: 'misal: 3',
                      icon: Icons.table_restaurant_rounded,
                    ),
                  const SizedBox(height: 14),

                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Metode Pembayaran',
                        style: AppTextStyles.titleSmall),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _labelMetode.entries.map((e) {
                      final terpilih = prov.metodePembayaran == e.key;
                      return ChoiceChip(
                        label: Text(e.value),
                        selected: terpilih,
                        onSelected: (_) => prov.setMetodePembayaran(e.key),
                        selectedColor: AppColors.forestGreen,
                        labelStyle: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: terpilih
                              ? AppColors.putih
                              : AppColors.textSecondary,
                        ),
                        showCheckmark: false,
                        side: BorderSide(
                            color: terpilih
                                ? AppColors.forestGreen
                                : AppColors.border),
                        backgroundColor: AppColors.surface,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  if (prov.keranjangKosong)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text('Keranjang masih kosong',
                            style: AppTextStyles.bodySmall),
                      ),
                    )
                  else ...[
                    const Align(
                      alignment: Alignment.centerLeft,
                      child:
                          Text('Item Dipesan', style: AppTextStyles.titleSmall),
                    ),
                    const SizedBox(height: 4),
                    ...prov.cart.map(
                      (item) => _TileItem(
                        item: item,
                        onCatatan: () => _editCatatan(item),
                        onKurang: () => prov.ubahJumlah(item.menuItemId, -1),
                        onTambah: () => prov.ubahJumlah(item.menuItemId, 1),
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                            child: Text('Total',
                                style: AppTextStyles.titleMedium)),
                        Text(rupiah(prov.totalKeranjang),
                            style: AppTextStyles.priceLarge),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton(
                    onPressed: prov.isSubmitting || prov.keranjangKosong
                        ? null
                        : _simpan,
                    child: prov.isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.putih),
                          )
                        : const Text('Simpan Pesanan'),
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

// =============================================================
// WIDGET KECIL
// =============================================================
class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;

  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.titleSmall),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20, color: AppColors.textSecondary),
            filled: true,
            fillColor: AppColors.surface,
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.forestGreen, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _TileItem extends StatelessWidget {
  final CartItem item;
  final VoidCallback onCatatan;
  final VoidCallback onKurang;
  final VoidCallback onTambah;

  const _TileItem({
    required this.item,
    required this.onCatatan,
    required this.onKurang,
    required this.onTambah,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.namaMenu,
                    style: AppTextStyles.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text('${rupiah(item.hargaSatuan)} x ${item.jumlah}',
                    style: AppTextStyles.bodySmall),
                if (item.catatan != null)
                  Text('Catatan: ${item.catatan}',
                      style: AppTextStyles.bodySmall
                          .copyWith(fontStyle: FontStyle.italic)),
                GestureDetector(
                  onTap: onCatatan,
                  child: Text(
                    item.catatan == null ? '+ Tambah catatan' : 'Ubah catatan',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.forestGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(rupiah(item.subtotal), style: AppTextStyles.price),
              const SizedBox(height: 4),
              Row(
                children: [
                  _TombolStepper(icon: Icons.remove_rounded, onTap: onKurang),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child:
                        Text('${item.jumlah}', style: AppTextStyles.titleSmall),
                  ),
                  _TombolStepper(icon: Icons.add_rounded, onTap: onTambah),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TombolStepper extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TombolStepper({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.goldMuda,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: AppColors.forestGreenDark),
      ),
    );
  }
}

class _KartuMenu extends StatelessWidget {
  final Map<String, dynamic> menu;
  final int jumlahDiKeranjang;
  final String rupiah;
  final VoidCallback onTap;

  const _KartuMenu({
    required this.menu,
    required this.jumlahDiKeranjang,
    required this.rupiah,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final nama = (menu['nama'] ?? '-').toString();
    final kategori = (menu['kategori'] ?? 'Lainnya').toString();

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: jumlahDiKeranjang > 0
                  ? AppColors.forestGreen
                  : AppColors.border,
              width: jumlahDiKeranjang > 0 ? 1.5 : 1,
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(nama,
                        style: AppTextStyles.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ),
                  if (jumlahDiKeranjang > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.forestGreen,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$jumlahDiKeranjang',
                        style: const TextStyle(
                          color: AppColors.putih,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(kategori,
                  style: AppTextStyles.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(rupiah, style: AppTextStyles.price),
                    ),
                  ),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.add_rounded,
                        color: AppColors.putih, size: 18),
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

class _TampilanKosong extends StatelessWidget {
  final IconData icon;
  final String judul;
  final String pesan;
  final String? aksiLabel;
  final VoidCallback? onAksi;

  const _TampilanKosong({
    required this.icon,
    required this.judul,
    required this.pesan,
    this.aksiLabel,
    this.onAksi,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.goldMuda,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, color: AppColors.forestGreen, size: 30),
            ),
            const SizedBox(height: 14),
            Text(judul,
                textAlign: TextAlign.center, style: AppTextStyles.titleMedium),
            const SizedBox(height: 6),
            Text(pesan,
                textAlign: TextAlign.center, style: AppTextStyles.bodySmall),
            if (aksiLabel != null && onAksi != null) ...[
              const SizedBox(height: 12),
              TextButton(onPressed: onAksi, child: Text(aksiLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
