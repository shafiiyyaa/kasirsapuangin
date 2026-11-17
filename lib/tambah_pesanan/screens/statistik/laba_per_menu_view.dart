import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/bahasa.dart';
import '../../../menu_board/models/menu_item.dart';
import '../../../menu_board/models/order.dart';
import '../../../menu_board/services/supabase_service.dart';
import '../../../theme/app_theme.dart';

const _namaBulan = [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];
const _hariPendek = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

String _rp(int n) => n
    .toString()
    .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.');

enum _ModeLaba { harian, bulanan, tahunan }
enum _GrupLaba { perMenu, perKategori }

/// Satu baris hasil laba (untuk satu menu atau satu kategori).
class _BarisLaba {
  _BarisLaba(this.nama, {this.kategori});

  final String nama;
  final String? kategori;

  int terjual = 0;

  /// Pendapatan setelah diskon dibagi rata sesuai porsi harga tiap item.
  double pendapatan = 0;
  int modal = 0;

  int get pendapatanBulat => pendapatan.round();
  int get laba => pendapatanBulat - modal;
}

class _HasilLaba {
  const _HasilLaba({
    required this.perMenu,
    required this.perKategori,
    required this.totalModal,
    required this.pendapatan,
    required this.menuTanpaModal,
  });

  final List<_BarisLaba> perMenu;
  final List<_BarisLaba> perKategori;
  final int totalModal;
  final int pendapatan;
  final Set<String> menuTanpaModal;
}

/// View "Laba per Menu" yang berdiri sendiri.
///
/// Dipakai sebagai tab ketiga di layar Statistik supaya daftar laba per
/// menu tidak memanjang dan menyebabkan scroll panjang di tab Ringkasan.
///
/// Mendukung:
/// - Pilih periode: harian / bulanan / tahunan (tanggal bisa digeser).
/// - Grup baris: per menu atau per kategori.
/// - Filter kategori (hanya saat grup per menu) dan pencarian nama menu.
class LabaPerMenuView extends StatefulWidget {
  const LabaPerMenuView({super.key});

  @override
  State<LabaPerMenuView> createState() => _LabaPerMenuViewState();
}

class _LabaPerMenuViewState extends State<LabaPerMenuView> {
  _ModeLaba _mode = _ModeLaba.bulanan;
  _GrupLaba _grup = _GrupLaba.perMenu;
  late DateTime _tanggal;

  String _cari = '';
  String? _kategoriTerpilih; // null = Semua kategori

  List<Order> _orders = [];
  Map<String, MenuItem> _menuById = {};
  bool _loading = true;
  String? _error;
  int _versi = 0; // abaikan hasil permintaan usang

  final TextEditingController _cariCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final sekarang = DateTime.now();
    _tanggal = DateTime(sekarang.year, sekarang.month, sekarang.day);
    _cariCtrl.addListener(() {
      final next = _cariCtrl.text.trim().toLowerCase();
      if (next != _cari) setState(() => _cari = next);
    });
    _muat();
  }

  @override
  void dispose() {
    _cariCtrl.dispose();
    super.dispose();
  }

  DateTime get _awal {
    switch (_mode) {
      case _ModeLaba.harian:
        return DateTime(_tanggal.year, _tanggal.month, _tanggal.day);
      case _ModeLaba.bulanan:
        return DateTime(_tanggal.year, _tanggal.month, 1);
      case _ModeLaba.tahunan:
        return DateTime(_tanggal.year, 1, 1);
    }
  }

  DateTime get _akhir {
    switch (_mode) {
      case _ModeLaba.harian:
        return DateTime(_tanggal.year, _tanggal.month, _tanggal.day + 1);
      case _ModeLaba.bulanan:
        return DateTime(_tanggal.year, _tanggal.month + 1, 1);
      case _ModeLaba.tahunan:
        return DateTime(_tanggal.year + 1, 1, 1);
    }
  }

  String get _labelPeriode {
    switch (_mode) {
      case _ModeLaba.harian:
        return '${tr(_hariPendek[_tanggal.weekday - 1])}, ${_tanggal.day} '
            '${tr(_namaBulan[_tanggal.month - 1])} ${_tanggal.year}';
      case _ModeLaba.bulanan:
        return '${tr(_namaBulan[_tanggal.month - 1])} ${_tanggal.year}';
      case _ModeLaba.tahunan:
        return '${tr('Tahun')} ${_tanggal.year}';
    }
  }

  Future<void> _muat() async {
    final versi = ++_versi;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final orders = await SupabaseService.fetchOrdersPeriode(_awal, _akhir);

      // Menu dipakai untuk kategori, dan sebagai cadangan modal untuk
      // pesanan lama yang belum menyimpan harga_modal di item-nya.
      var menu = <String, MenuItem>{};
      try {
        final daftar = await SupabaseService.fetchMenuItems();
        menu = {for (final m in daftar) m.id: m};
      } catch (_) {}

      if (!mounted || versi != _versi) return;
      setState(() {
        _orders = orders;
        _menuById = menu;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || versi != _versi) return;
      setState(() {
        _error = tr('Gagal memuat statistik: {e}', {'e': e});
        _loading = false;
      });
    }
  }

  void _geser(int arah) {
    setState(() {
      switch (_mode) {
        case _ModeLaba.harian:
          _tanggal =
              DateTime(_tanggal.year, _tanggal.month, _tanggal.day + arah);
          break;
        case _ModeLaba.bulanan:
          _tanggal = DateTime(_tanggal.year, _tanggal.month + arah, 1);
          break;
        case _ModeLaba.tahunan:
          _tanggal = DateTime(_tanggal.year + arah, 1, 1);
          break;
      }
    });
    _muat();
  }

  Future<void> _pilihTanggal() async {
    if (_mode != _ModeLaba.harian) return;
    final dipilih = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (dipilih == null || !mounted) return;
    setState(() {
      _tanggal = DateTime(dipilih.year, dipilih.month, dipilih.day);
    });
    _muat();
  }

  List<Order> get _orderSah =>
      _orders.where((o) => o.status != OrderStatus.batal).toList();

  /// Hitung modal dan laba per menu serta per kategori.
  /// Logikanya sama dengan tab Ringkasan: diskon pesanan dibagi ke tiap
  /// item sesuai porsi harganya supaya total laba konsisten.
  _HasilLaba _hitungLaba() {
    final perMenu = <String, _BarisLaba>{};
    final perKategori = <String, _BarisLaba>{};
    final tanpaModal = <String>{};
    var totalModal = 0;
    var pendapatan = 0;

    for (final o in _orderSah) {
      final totalItem = o.items.fold<int>(0, (s, i) => s + i.subtotal);

      for (final it in o.items) {
        final menu = _menuById[it.menuItemId];
        final modalSatuan = it.hargaModal ?? menu?.hargaModal ?? 0;
        final modal = modalSatuan * it.jumlah;
        final potongan = (o.diskon > 0 && totalItem > 0)
            ? o.diskon * it.subtotal / totalItem
            : 0.0;
        final bersih = it.subtotal - potongan;

        final nama = menu?.nama ?? it.namaMenu;
        final kategoriMenu = menu?.kategori ?? '';
        final kategori =
            kategoriMenu.isEmpty ? tr('Lainnya') : kategoriMenu;

        if (modalSatuan <= 0) tanpaModal.add(nama);
        totalModal += modal;
        pendapatan += bersih.round();

        final baris = [
          perMenu.putIfAbsent(
              it.menuItemId, () => _BarisLaba(nama, kategori: kategori)),
          perKategori.putIfAbsent(kategori, () => _BarisLaba(kategori)),
        ];
        for (final b in baris) {
          b.terjual += it.jumlah;
          b.pendapatan += bersih;
          b.modal += modal;
        }
      }
    }

    int urut(_BarisLaba a, _BarisLaba b) => b.laba.compareTo(a.laba);

    return _HasilLaba(
      perMenu: perMenu.values.toList()..sort(urut),
      perKategori: perKategori.values.toList()..sort(urut),
      totalModal: totalModal,
      pendapatan: pendapatan,
      menuTanpaModal: tanpaModal,
    );
  }

  List<String> get _daftarKategori {
    final set = <String>{};
    for (final m in _menuById.values) {
      if (m.kategori.trim().isNotEmpty) set.add(m.kategori);
    }
    final list = set.toList()..sort();
    return list;
  }

  @override
  Widget build(BuildContext context) {
    context.watch<Bahasa>(); // rebuild saat bahasa diganti

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ----- Pemilih mode periode -----
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<_ModeLaba>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: _ModeLaba.harian, label: Text(tr('Harian'))),
              ButtonSegment(
                  value: _ModeLaba.bulanan, label: Text(tr('Bulanan'))),
              ButtonSegment(
                  value: _ModeLaba.tahunan, label: Text(tr('Tahunan'))),
            ],
            selected: {_mode},
            onSelectionChanged: (pilihan) {
              setState(() => _mode = pilihan.first);
              _muat();
            },
          ),
        ),
        const SizedBox(height: 8),

        // ----- Navigasi tanggal -----
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: _loading ? null : () => _geser(-1),
            ),
            InkWell(
              onTap: _pilihTanggal,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Text(
                  _labelPeriode,
                  style: AppTextStyles.bodyLarge
                      .copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: _loading ? null : () => _geser(1),
            ),
          ],
        ),
        if (_loading) const LinearProgressIndicator(minHeight: 3),
        const SizedBox(height: 12),

        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                Text(_error!, style: AppTextStyles.bodyMedium),
                const SizedBox(height: 8),
                OutlinedButton(onPressed: _muat, child: Text(tr('Coba Lagi'))),
              ],
            ),
          )
        else ...[
          // ----- Kartu ringkas (pendapatan / modal / laba) -----
          ..._ringkasanKartu(),
          const SizedBox(height: 16),

          // ----- Toolbar filter: grup + kategori + cari -----
          _buildToolbar(),
          const SizedBox(height: 8),

          // ----- Daftar baris laba -----
          _buildDaftar(),
        ],
      ],
    );
  }

  List<Widget> _ringkasanKartu() {
    final laba = _hitungLaba();

    // Laba = Pendapatan - Total Modal (HPP). Tanpa biaya lain.
    final labaTotal = laba.pendapatan - laba.totalModal;

    return [
      _KartuRingkas(
        label: tr('Pendapatan'),
        nilai: laba.pendapatan,
        warna: AppColors.forestGreen,
      ),
      _KartuRingkas(
        label: tr('Total Modal (HPP)'),
        nilai: laba.totalModal,
        warna: AppColors.statusBatal,
      ),
      _KartuRingkas(
        label: tr('Laba'),
        nilai: labaTotal,
        warna: labaTotal >= 0
            ? AppColors.forestGreenDark
            : AppColors.statusBatal,
      ),
    ];
  }

  Widget _buildToolbar() {
    final kategoriList = _daftarKategori;
    final laba = _hitungLaba();
    final tampilkanDropdownKategori =
        _grup == _GrupLaba.perMenu && kategoriList.length > 1;

    // Kotak pencarian nama menu. Dipakai baik saat filter kategori
    // tampil maupun tidak, jadi dibuat satu kali di sini.
    final searchField = TextField(
      controller: _cariCtrl,
      decoration: InputDecoration(
        isDense: true,
        hintText: tr('Cari nama menu...'),
        prefixIcon: const Icon(Icons.search_rounded, size: 19),
        suffixIcon: _cari.isEmpty
            ? null
            : IconButton(
                tooltip: tr('Hapus pencarian'),
                onPressed: () => _cariCtrl.clear(),
                icon: const Icon(Icons.close_rounded, size: 18),
              ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Grup: per menu / per kategori
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<_GrupLaba>(
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor:
                  AppColors.forestGreen.withValues(alpha: 0.14),
              selectedForegroundColor: AppColors.forestGreenDark,
            ),
            segments: [
              ButtonSegment(
                  value: _GrupLaba.perMenu,
                  icon: const Icon(Icons.restaurant_menu_rounded, size: 16),
                  label: Text(tr('Per Menu'))),
              ButtonSegment(
                  value: _GrupLaba.perKategori,
                  icon: const Icon(Icons.category_rounded, size: 16),
                  label: Text(tr('Per Kategori'))),
            ],
            selected: {_grup},
            onSelectionChanged: (pilihan) =>
                setState(() => _grup = pilihan.first),
          ),
        ),
        const SizedBox(height: 10),
        if (tampilkanDropdownKategori)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _kategoriTerpilih,
                  isExpanded: true,
                  decoration: InputDecoration(
                    isDense: true,
                    prefixIcon:
                        const Icon(Icons.filter_list_rounded, size: 19),
                    labelText: tr('Kategori'),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text(tr('Semua kategori')),
                    ),
                    for (final k in kategoriList)
                      DropdownMenuItem(value: k, child: Text(k)),
                  ],
                  onChanged: (v) => setState(() => _kategoriTerpilih = v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: searchField),
            ],
          )
        else
          searchField,
        if (laba.menuTanpaModal.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline,
                    size: 16, color: AppColors.warning),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tr(
                      '{n} menu belum diisi modalnya. Laba bisa terlihat lebih besar dari sebenarnya.',
                      {'n': laba.menuTanpaModal.length},
                    ),
                    style: AppTextStyles.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDaftar() {
    if (_orderSah.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            tr('Belum ada penjualan pada periode ini.'),
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final laba = _hitungLaba();
    final sumber =
        _grup == _GrupLaba.perMenu ? laba.perMenu : laba.perKategori;

    var tampil = sumber.where((b) {
      final cocokCari =
          _cari.isEmpty || b.nama.toLowerCase().contains(_cari);
      final cocokKategori = _grup == _GrupLaba.perKategori ||
          _kategoriTerpilih == null ||
          b.kategori == _kategoriTerpilih;
      return cocokCari && cocokKategori;
    }).toList();

    if (tampil.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            tr('Tidak ada yang cocok dengan filter.'),
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 6),
          child: Text(
            tr('{n} baris', {'n': tampil.length}),
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textSecondary),
          ),
        ),
        for (final b in tampil) _BarisLabaRow(baris: b),
      ],
    );
  }
}

class _KartuRingkas extends StatelessWidget {
  final String label;
  final int nilai;
  final Color warna;

  const _KartuRingkas({
    required this.label,
    required this.nilai,
    required this.warna,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: warna.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: warna.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: AppTextStyles.bodyLarge)),
          const SizedBox(width: 8),
          Text(
            '${nilai < 0 ? '-' : ''}Rp${_rp(nilai.abs())}',
            style: AppTextStyles.priceLarge.copyWith(color: warna),
          ),
        ],
      ),
    );
  }
}

class _BarisLabaRow extends StatelessWidget {
  final _BarisLaba baris;

  const _BarisLabaRow({required this.baris});

  @override
  Widget build(BuildContext context) {
    final rugi = baris.laba < 0;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(
        baris.nama,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.bodyLarge,
      ),
      subtitle: Text(
        tr('{n} terjual • Pendapatan Rp{a} • Modal Rp{m}', {
          'n': baris.terjual,
          'a': _rp(baris.pendapatanBulat),
          'm': _rp(baris.modal),
        }),
        style:
            AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
      ),
      trailing: Text(
        '${rugi ? '-' : ''}Rp${_rp(baris.laba.abs())}',
        style: AppTextStyles.price.copyWith(
          color: rugi ? AppColors.statusBatal : AppColors.forestGreen,
        ),
      ),
    );
  }
}