import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../widgets/app_scaffold.dart';

import '../../../l10n/bahasa.dart';
import '../../../menu_board/models/order.dart';
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

class StatistikScreen extends StatefulWidget {
  const StatistikScreen({super.key});

  @override
  State<StatistikScreen> createState() => _StatistikScreenState();
}

class _StatistikScreenState extends State<StatistikScreen> {
  late DateTime _bulan; // tanggal 1 bulan yang sedang dilihat
  List<Order> _orders = [];
  bool _loading = true;
  String? _error;

  // 0 = Ringkasan, 1 = Produksi & Best Seller, 2 = Laba per Menu
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _bulan = DateTime(now.year, now.month);
    _muat();
  }

  Future<void> _muat() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final awal = DateTime(_bulan.year, _bulan.month, 1);
      final akhir = DateTime(_bulan.year, _bulan.month + 1, 1);
      final orders = await SupabaseService.fetchOrdersPeriode(awal, akhir);

      if (!mounted) return;
      setState(() {
        _orders = orders;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = tr('Gagal memuat statistik: {e}', {'e': e});
        _loading = false;
      });
    }
  }

  void _gantiBulan(int delta) {
    setState(() {
      _bulan = DateTime(_bulan.year, _bulan.month + delta);
    });
    _muat();
  }

  String _rupiah(int n) => _rp(n);

  int get _uangMasuk => _orders
      .where((o) => o.status != OrderStatus.batal)
      .fold(0, (sum, o) => sum + o.totalHarga);

  int _masukPerMetode(String metode) => _orders
      .where(
          (o) => o.status != OrderStatus.batal && o.metodePembayaran == metode)
      .fold(0, (sum, o) => sum + o.totalHarga);

  List<Order> get _orderSah =>
      _orders.where((o) => o.status != OrderStatus.batal).toList();

  int get _hargaAsli => _orderSah.fold(0, (s, o) => s + o.subtotalAsli);

  int get _totalDiskon => _orderSah.fold(0, (s, o) => s + o.diskon);

  int get _pesananBerdiskon => _orderSah.where((o) => o.diskon > 0).length;

  String _subJudulHari(List<Order> list) {
    final diskon = list
        .where((o) => o.status != OrderStatus.batal)
        .fold(0, (s, o) => s + o.diskon);
    return diskon > 0
        ? tr('{n} pesanan - diskon Rp{d}',
            {'n': list.length, 'd': _rupiah(diskon)})
        : tr('{n} pesanan', {'n': list.length});
  }

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
    if (_loading) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    if (_error != null) {
      return [
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
        ),
      ];
    }

    final pendapatan = _uangMasuk;

    return [
      // ----- Pemilih bulan -----
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _gantiBulan(-1),
          ),
          Text(
            '${tr(_namaBulan[_bulan.month - 1])} ${_bulan.year}',
            style:
                AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => _gantiBulan(1),
          ),
        ],
      ),
      const SizedBox(height: 8),
      // ----- Pendapatan -----
      _KartuRekap(
        label: tr('Harga Asli (sebelum diskon)'),
        nilai: _hargaAsli,
        warna: AppColors.statusDiproses,
      ),
      _KartuRekap(
        label: tr('Total Diskon ({n} pesanan)', {'n': _pesananBerdiskon}),
        nilai: _totalDiskon,
        warna: AppColors.warning,
      ),
      _KartuRekap(
        label: tr('Pendapatan (setelah diskon)'),
        nilai: pendapatan,
        warna: AppColors.forestGreen,
      ),
      const SizedBox(height: 16),

      // ----- Rincian laba per menu (sekarang ada di tab sendiri) -----
      // Daftar panjang per menu dipindah ke tab "Laba per Menu" supaya
      // tab Ringkasan tidak terlalu panjang saat di-scroll. Tombol ini
      // menggantikan list plus tombol "tampilkan semua" yang lama.
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
      const SizedBox(height: 16),
      Text(tr('Rekap Harian'), style: AppTextStyles.displayMedium),
      const SizedBox(height: 4),
      ..._rekapHarian(),
    ];
  }

  List<Widget> _rekapHarian() {
    final perHari = <DateTime, List<Order>>{};
    for (final o in _orders) {
      final t = o.createdAt; // sudah lokal (WIB)
      perHari.putIfAbsent(DateTime(t.year, t.month, t.day), () => []).add(o);
    }
    final hariUrut = perHari.keys.toList()..sort((a, b) => b.compareTo(a));

    if (hariUrut.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(tr('Belum ada pesanan bulan ini.'),
              style: AppTextStyles.bodyMedium),
        ),
      ];
    }

    return [
      for (final hari in hariUrut)
        ListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text(
            '${tr(_hariPendek[hari.weekday - 1])}, ${hari.day} ${tr(_namaBulan[hari.month - 1])}',
            style: AppTextStyles.bodyLarge,
          ),
          subtitle: Text(_subJudulHari(perHari[hari]!),
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary)),
          trailing: Text(
            _rupiah(perHari[hari]!
                .where((o) => o.status != OrderStatus.batal)
                .fold(0, (s, o) => s + o.totalHarga)),
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