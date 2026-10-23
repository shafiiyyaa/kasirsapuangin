import 'package:flutter/material.dart';
import '../../widgets/app_scaffold.dart';
import 'package:provider/provider.dart';

import '../../../menu_board/models/order.dart';
import '../../../menu_board/providers/pengeluaran_provider.dart';
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
      // Pastikan data pengeluaran sudah termuat untuk hitung uang keluar.
      await context.read<PengeluaranProvider>().loadPengeluaran();
      if (!mounted) return;
      setState(() {
        _orders = orders;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Gagal memuat statistik: $e';
        _loading = false;
      });
    }
  }

  void _gantiBulan(int delta) {
    setState(() => _bulan = DateTime(_bulan.year, _bulan.month + delta));
    _muat();
  }

  String _rupiah(int n) => n
      .toString()
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.');

  int get _uangMasuk => _orders
      .where((o) => o.status != OrderStatus.batal)
      .fold(0, (sum, o) => sum + o.totalHarga);

  int _masukPerMetode(String metode) => _orders
      .where(
          (o) => o.status != OrderStatus.batal && o.metodePembayaran == metode)
      .fold(0, (sum, o) => sum + o.totalHarga);

  @override
  Widget build(BuildContext context) {
    final pengeluaranProvider = context.watch<PengeluaranProvider>();
    final uangKeluar =
        pengeluaranProvider.totalPadaBulan(_bulan.year, _bulan.month);
    final selisih = _uangMasuk - uangKeluar;

    return Scaffold(
      appBar: AppScaffold.isWide(context) ? null : AppBar(
        title: const Text('Statistik'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          tooltip: 'Buka menu',
          onPressed: () => AppScaffold.openMenu(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, style: AppTextStyles.bodyMedium),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: _muat,
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _muat,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    children: [
                      // ----- Pemilih bulan -----
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left),
                            onPressed: () => _gantiBulan(-1),
                          ),
                          Text(
                            '${_namaBulan[_bulan.month - 1]} ${_bulan.year}',
                            style: AppTextStyles.bodyLarge
                                .copyWith(fontWeight: FontWeight.w700),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right),
                            onPressed: () => _gantiBulan(1),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // ----- Ringkasan cash in / cash out -----
                      _KartuRekap(
                        label: 'Uang Masuk',
                        nilai: _uangMasuk,
                        warna: AppColors.forestGreen,
                      ),
                      _KartuRekap(
                        label: 'Uang Keluar',
                        nilai: uangKeluar,
                        warna: AppColors.statusBatal,
                      ),
                      _KartuRekap(
                        label: 'Selisih (Laba)',
                        nilai: selisih,
                        warna: AppColors.forestGreenDark,
                      ),
                      const SizedBox(height: 16),
                      const Text('Rincian Pembayaran',
                          style: AppTextStyles.displayMedium),
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
                      _BarisMetode(
                        icon: Icons.account_balance,
                        label: 'Transfer',
                        nilai: _masukPerMetode('transfer'),
                      ),
                      const SizedBox(height: 16),
                      const Text('Rekap Harian', style: AppTextStyles.displayMedium),
                      const SizedBox(height: 4),
                      ..._rekapHarian(),
                    ],
                  ),
                ),
    );
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
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Text('Belum ada pesanan bulan ini.',
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
            '${_hariPendek[hari.weekday - 1]}, ${hari.day} ${_namaBulan[hari.month - 1]}',
            style: AppTextStyles.bodyLarge,
          ),
          subtitle: Text('${perHari[hari]!.length} pesanan',
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
          Text(label, style: AppTextStyles.bodyLarge),
          Text(
            'Rp${nilai.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}',
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
        'Rp${nilai.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}',
        style: AppTextStyles.price,
      ),
    );
  }
}
