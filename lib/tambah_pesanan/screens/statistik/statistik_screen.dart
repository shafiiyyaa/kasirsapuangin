import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../widgets/app_scaffold.dart';

import '../../../l10n/bahasa.dart';
import '../../../menu_board/models/order.dart';
import '../../../menu_board/models/pengeluaran.dart';
import '../../../menu_board/services/pengeluaran_service.dart';
import '../../../menu_board/services/supabase_service.dart';
import '../../../theme/app_theme.dart';
import 'laba_per_menu_view.dart';
import 'rekap_produksi.dart';

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

/// Format angka dengan titik ribuan: 15000 -> 15.000
String _rp(int n) => n
    .toString()
    .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.');

enum _ModeRingkasan { harian, bulanan, tahunan }

/// Satu baris rekap (per hari atau per bulan).
class _BarisRekap {
  int pesanan = 0;
  int pendapatan = 0;
  int pengeluaran = 0;
}

class StatistikScreen extends StatefulWidget {
  const StatistikScreen({super.key});

  @override
  State<StatistikScreen> createState() => _StatistikScreenState();
}

class _StatistikScreenState extends State<StatistikScreen> {
  _ModeRingkasan _mode = _ModeRingkasan.bulanan;
  late DateTime _tanggal; // patokan periode yang sedang dilihat

  List<Order> _orders = [];
  List<Pengeluaran> _pengeluaran = [];
  bool _loading = true;
  String? _error;
  int _versi = 0; // abaikan hasil permintaan yang sudah usang

  // 0 = Ringkasan, 1 = Produksi & Best Seller, 2 = Laba per Menu
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _tanggal = DateTime(now.year, now.month, now.day);
    _muat();
  }

  DateTime get _awal {
    switch (_mode) {
      case _ModeRingkasan.harian:
        return DateTime(_tanggal.year, _tanggal.month, _tanggal.day);
      case _ModeRingkasan.bulanan:
        return DateTime(_tanggal.year, _tanggal.month, 1);
      case _ModeRingkasan.tahunan:
        return DateTime(_tanggal.year, 1, 1);
    }
  }

  DateTime get _akhir {
    switch (_mode) {
      case _ModeRingkasan.harian:
        return DateTime(_tanggal.year, _tanggal.month, _tanggal.day + 1);
      case _ModeRingkasan.bulanan:
        return DateTime(_tanggal.year, _tanggal.month + 1, 1);
      case _ModeRingkasan.tahunan:
        return DateTime(_tanggal.year + 1, 1, 1);
    }
  }

  String get _labelPeriode {
    switch (_mode) {
      case _ModeRingkasan.harian:
        return '${tr(_hariPendek[_tanggal.weekday - 1])}, ${_tanggal.day} '
            '${tr(_namaBulan[_tanggal.month - 1])} ${_tanggal.year}';
      case _ModeRingkasan.bulanan:
        return '${tr(_namaBulan[_tanggal.month - 1])} ${_tanggal.year}';
      case _ModeRingkasan.tahunan:
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
      final hasil = await Future.wait<Object>([
        SupabaseService.fetchOrdersPeriode(_awal, _akhir),
        PengeluaranService.fetchPeriode(_awal, _akhir),
      ]);

      if (!mounted || versi != _versi) return;
      setState(() {
        _orders = hasil[0] as List<Order>;
        _pengeluaran = hasil[1] as List<Pengeluaran>;
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
        case _ModeRingkasan.harian:
          _tanggal =
              DateTime(_tanggal.year, _tanggal.month, _tanggal.day + arah);
          break;
        case _ModeRingkasan.bulanan:
          _tanggal = DateTime(_tanggal.year, _tanggal.month + arah, 1);
          break;
        case _ModeRingkasan.tahunan:
          _tanggal = DateTime(_tanggal.year + arah, 1, 1);
          break;
      }
    });
    _muat();
  }

  Future<void> _pilihTanggal() async {
    if (_mode != _ModeRingkasan.harian) return;
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

  // ---------- hitungan ----------

  List<Order> get _orderSah =>
      _orders.where((o) => o.status != OrderStatus.batal).toList();

  /// Pendapatan keseluruhan = total yang dibayar (setelah diskon).
  int get _pendapatan => _orderSah.fold(0, (sum, o) => sum + o.totalHarga);

  int get _totalPengeluaran =>
      _pengeluaran.fold(0, (sum, p) => sum + p.jumlah);

  /// Laba = pendapatan - pengeluaran (dihitung otomatis).
  int get _laba => _pendapatan - _totalPengeluaran;

  int _masukPerMetode(String metode) => _orderSah
      .where((o) => o.metodePembayaran == metode)
      .fold(0, (sum, o) => sum + o.totalHarga);

  // ---------- tampilan ----------

  @override
  Widget build(BuildContext context) {
    // Rebuild otomatis saat bahasa diganti.
    context.watch<Bahasa>();

    return Scaffold(
      appBar: AppScaffold.isWide(context)
          ? null
          : AppBar(
              title: Text(tr('Statistik')),
              leading: IconButton(
                icon: const Icon(Icons.menu),
                tooltip: tr('Buka menu'),
                onPressed: () => AppScaffold.openMenu(context),
              ),
            ),
      body: RefreshIndicator(
        onRefresh: _muat,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<int>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: 0,
                    icon: const Icon(Icons.payments_outlined),
                    label: Text(tr('Ringkasan')),
                  ),
                  ButtonSegment(
                    value: 1,
                    icon: const Icon(Icons.local_fire_department_outlined),
                    label: Text(tr('Produksi & Terlaris')),
                  ),
                  ButtonSegment(
                    value: 2,
                    icon: const Icon(Icons.savings_outlined),
                    label: Text(tr('Laba per Menu')),
                  ),
                ],
                selected: {_tab},
                onSelectionChanged: (pilihan) =>
                    setState(() => _tab = pilihan.first),
              ),
            ),
            const SizedBox(height: 12),
            if (_tab == 1)
              const RekapProduksiView()
            else if (_tab == 2)
              const LabaPerMenuView()
            else
              ..._ringkasan(),
          ],
        ),
      ),
    );
  }

  List<Widget> _ringkasan() {
    return [
      _pemilihPeriode(),
      const SizedBox(height: 12),
      if (_error != null)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Column(
            children: [
              Text(_error!, style: AppTextStyles.bodyMedium),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _muat,
                child: Text(tr('Coba Lagi')),
              ),
            ],
          ),
        )
      else if (_loading)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: Center(child: CircularProgressIndicator()),
        )
      else
        ..._isiRingkasan(),
    ];
  }

  Widget _pemilihPeriode() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<_ModeRingkasan>(
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor:
                  AppColors.forestGreen.withValues(alpha: 0.14),
              selectedForegroundColor: AppColors.forestGreenDark,
            ),
            segments: [
              ButtonSegment(
                value: _ModeRingkasan.harian,
                label: Text(tr('Harian')),
              ),
              ButtonSegment(
                value: _ModeRingkasan.bulanan,
                label: Text(tr('Bulanan')),
              ),
              ButtonSegment(
                value: _ModeRingkasan.tahunan,
                label: Text(tr('Tahunan')),
              ),
            ],
            selected: {_mode},
            onSelectionChanged: (pilihan) {
              setState(() => _mode = pilihan.first);
              _muat();
            },
          ),
        ),
        const SizedBox(height: 8),
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
      ],
    );
  }

  List<Widget> _isiRingkasan() {
    final laba = _laba;

    return [
      // ----- Pendapatan, pengeluaran, laba -----
      _KartuRekap(
        label: tr('Pendapatan Keseluruhan'),
        nilai: _pendapatan,
        warna: AppColors.forestGreen,
      ),
      _KartuRekap(
        label: tr('Pengeluaran'),
        nilai: _totalPengeluaran,
        warna: AppColors.warning,
      ),
      _KartuRekap(
        label: tr('Laba (Pendapatan - Pengeluaran)'),
        nilai: laba,
        warna: laba >= 0 ? AppColors.success : AppColors.statusBatal,
      ),
      const SizedBox(height: 16),

      // ----- Rincian laba per menu (ada di tab sendiri) -----
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => setState(() => _tab = 2),
          icon: const Icon(Icons.manage_search_rounded, size: 18),
          label: Text(tr('Lihat rincian laba per menu')),
        ),
      ),
      const SizedBox(height: 16),

      // ----- Rincian pembayaran -----
      Text(tr('Rincian Pembayaran'), style: AppTextStyles.displayMedium),
      const SizedBox(height: 8),
      _BarisMetode(
        icon: Icons.payments_outlined,
        label: 'Cash',
        nilai: _masukPerMetode('cash'),
      ),
      _BarisMetode(
        icon: Icons.qr_code_2,
        label: 'QRIS',
        nilai: _masukPerMetode('qris'),
      ),

      // ----- Rekap per hari (bulanan) / per bulan (tahunan) -----
      if (_mode != _ModeRingkasan.harian) ..._rekap(),
    ];
  }

  List<Widget> _rekap() {
    final perBulan = _mode == _ModeRingkasan.tahunan;

    DateTime kunci(DateTime t) =>
        perBulan ? DateTime(t.year, t.month) : DateTime(t.year, t.month, t.day);

    final baris = <DateTime, _BarisRekap>{};
    for (final o in _orderSah) {
      final b = baris.putIfAbsent(kunci(o.createdAt), () => _BarisRekap());
      b.pesanan++;
      b.pendapatan += o.totalHarga;
    }
    for (final p in _pengeluaran) {
      final b = baris.putIfAbsent(kunci(p.tanggal), () => _BarisRekap());
      b.pengeluaran += p.jumlah;
    }
    final urut = baris.keys.toList()..sort((a, b) => b.compareTo(a));

    return [
      const SizedBox(height: 16),
      Text(
        tr(perBulan ? 'Rekap Bulanan' : 'Rekap Harian'),
        style: AppTextStyles.displayMedium,
      ),
      const SizedBox(height: 4),
      if (urut.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            tr('Belum ada data pada periode ini.'),
            style: AppTextStyles.bodyMedium,
          ),
        )
      else
        for (final k in urut)
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(
              perBulan
                  ? tr(_namaBulan[k.month - 1])
                  : '${tr(_hariPendek[k.weekday - 1])}, ${k.day} ${tr(_namaBulan[k.month - 1])}',
              style: AppTextStyles.bodyLarge,
            ),
            subtitle: Text(
              baris[k]!.pengeluaran > 0
                  ? tr('{n} pesanan • pengeluaran Rp{p}', {
                      'n': baris[k]!.pesanan,
                      'p': _rp(baris[k]!.pengeluaran),
                    })
                  : tr('{n} pesanan', {'n': baris[k]!.pesanan}),
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
            trailing: Text(
              'Rp${_rp(baris[k]!.pendapatan)}',
              style: AppTextStyles.price,
            ),
          ),
    ];
  }
}

class _KartuRekap extends StatelessWidget {
  final String label;
  final int nilai;
  final Color warna;

  const _KartuRekap({
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

class _BarisMetode extends StatelessWidget {
  final IconData icon;
  final String label;
  final int nilai;

  const _BarisMetode({
    required this.icon,
    required this.label,
    required this.nilai,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: Icon(icon, color: AppColors.forestGreen),
      title: Text(label, style: AppTextStyles.bodyLarge),
      trailing: Text(
        'Rp${_rp(nilai)}',
        style: AppTextStyles.price,
      ),
    );
  }
}