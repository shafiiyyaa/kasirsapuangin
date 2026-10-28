import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../widgets/app_scaffold.dart';
import '../../../menu_board/models/pengeluaran.dart';
import '../../../menu_board/providers/pengeluaran_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

const List<String> _namaBulan = [
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

String _formatRupiah(int angka) {
  return angka.toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (_) => '.',
      );
}

String _formatTanggal(DateTime tanggal) {
  return '${tanggal.day} ${_namaBulan[tanggal.month - 1]} ${tanggal.year}';
}

bool _tanggalSama(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

class PengeluaranScreen extends StatefulWidget {
  const PengeluaranScreen({super.key});

  @override
  State<PengeluaranScreen> createState() => _PengeluaranScreenState();
}

class _PengeluaranScreenState extends State<PengeluaranScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _filter = 'Bulan ini';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<PengeluaranProvider>().loadPengeluaran();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _sesuaiFilter(Pengeluaran item) {
    final now = DateTime.now();
    final tanggal = item.tanggal;

    switch (_filter) {
      case 'Hari ini':
        return _tanggalSama(tanggal, now);

      case '7 hari':
        final awal = DateTime(now.year, now.month, now.day)
            .subtract(const Duration(days: 6));
        final akhir = DateTime(now.year, now.month, now.day);

        return !tanggal.isBefore(awal) && !tanggal.isAfter(akhir);

      case 'Bulan ini':
        return tanggal.year == now.year && tanggal.month == now.month;

      case 'Semua':
        return true;

      default:
        return true;
    }
  }

  List<Pengeluaran> _daftarTerfilter(
    List<Pengeluaran> semua,
  ) {
    final kataKunci = _searchController.text.trim().toLowerCase();

    final hasil = semua.where((item) {
      return _sesuaiFilter(item) &&
          item.keterangan.toLowerCase().contains(kataKunci);
    }).toList();

    hasil.sort(
      (a, b) => b.tanggal.compareTo(a.tanggal),
    );

    return hasil;
  }

  int _jumlahTotal(Iterable<Pengeluaran> items) {
    return items.fold<int>(
      0,
      (total, item) => total + item.jumlah,
    );
  }

  Future<void> _hapusPengeluaran(String id) async {
    final setuju = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus pengeluaran?'),
        content: const Text(
          'Catatan ini akan dihapus permanen. Lanjutkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (setuju != true || !mounted) return;

    try {
      await context.read<PengeluaranProvider>().hapus(id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pengeluaran berhasil dihapus.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus pengeluaran: $e')),
      );
    }
  }

  void _bukaFormTambah() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _FormPengeluaran(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PengeluaranProvider>();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final sekarang = DateTime.now();

    final semua = provider.items;
    final daftar = _daftarTerfilter(semua);

    final totalBulanIni = provider.totalPadaBulan(
      sekarang.year,
      sekarang.month,
    );

    final totalHariIni = _jumlahTotal(
      semua.where((item) => _tanggalSama(item.tanggal, sekarang)),
    );

    final dataMingguan = List<int>.generate(7, (index) {
      final tanggal = DateTime(
        sekarang.year,
        sekarang.month,
        sekarang.day,
      ).subtract(Duration(days: 6 - index));

      return _jumlahTotal(
        semua.where((item) => _tanggalSama(item.tanggal, tanggal)),
      );
    });

    final totalMingguan = dataMingguan.fold<int>(
      0,
      (sum, nilai) => sum + nilai,
    );

    final jumlahMaksimum = dataMingguan.fold<int>(
      0,
      (maks, nilai) => nilai > maks ? nilai : maks,
    );

    final jumlahBulanIni = semua.where((item) {
      return item.tanggal.year == sekarang.year &&
          item.tanggal.month == sekarang.month;
    }).length;

    return Scaffold(
      appBar: AppScaffold.isWide(context)
          ? null
          : AppBar(
              title: const Text('Pengeluaran'),
              leading: IconButton(
                tooltip: 'Buka menu',
                onPressed: () => AppScaffold.openMenu(context),
                icon: const Icon(Icons.menu_rounded),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _bukaFormTambah,
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Catat Pengeluaran'),
      ),
      body: provider.isLoading && semua.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null && semua.isEmpty
              ? _tampilanError(provider.error!)
              : RefreshIndicator(
                  onRefresh: provider.loadPengeluaran,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      20,
                      20,
                      100,
                    ),
                    children: [
                      Text(
                        'Pengeluaran Operasional',
                        style: AppTextStyles.displayMedium.copyWith(
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Pantau pengeluaran Sapuangin dengan lebih mudah.',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),

                      const SizedBox(height: 22),

                      // Ringkasan pengeluaran bulan ini.
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: theme.brightness == Brightness.dark
                                ? const [
                                    Color(0xFF245342),
                                    Color(0xFF15352C),
                                  ]
                                : const [
                                    Color(0xFF286B56),
                                    Color(0xFF153D30),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.account_balance_wallet_outlined,
                                  color: Colors.white70,
                                ),
                                SizedBox(width: 9),
                                Expanded(
                                  child: Text(
                                    'Total pengeluaran bulan ini',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.trending_up_rounded,
                                  color: Colors.white70,
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            Text(
                              'Rp${_formatRupiah(totalBulanIni)}',
                              style: AppTextStyles.displayLarge.copyWith(
                                color: Colors.white,
                                fontSize: 29,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$jumlahBulanIni catatan pada '
                              '${_namaBulan[sekarang.month - 1]}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Kartu statistik.
                      Row(
                        children: [
                          Expanded(
                            child: _KartuStatistik(
                              judul: 'Pengeluaran hari ini',
                              nilai: 'Rp${_formatRupiah(totalHariIni)}',
                              ikon: Icons.today_rounded,
                              warna: const Color(0xFF72B49B),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _KartuStatistik(
                              judul: 'Jumlah catatan',
                              nilai: '${semua.length} transaksi',
                              ikon: Icons.receipt_long_rounded,
                              warna: AppColors.gold,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 26),

                      // Grafik pengeluaran tujuh hari.
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Tren Pengeluaran',
                              style: AppTextStyles.titleLarge.copyWith(
                                color: colors.onSurface,
                              ),
                            ),
                          ),
                          Text(
                            '7 hari terakhir',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: colors.outlineVariant,
                          ),
                        ),
                        child: Column(
                          children: [
                            if (jumlahMaksimum == 0)
                              SizedBox(
                                height: 130,
                                child: Center(
                                  child: Text(
                                    'Belum ada pengeluaran selama '
                                    '7 hari terakhir.',
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: colors.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              )
                            else
                              SizedBox(
                                height: 142,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: List.generate(7, (index) {
                                    final nominal = dataMingguan[index];
                                    final tinggi = nominal == 0
                                        ? 4.0
                                        : 12.0 +
                                            88.0 * nominal / jumlahMaksimum;

                                    final hariIni = index == 6;

                                    final tanggal = DateTime(
                                      sekarang.year,
                                      sekarang.month,
                                      sekarang.day,
                                    ).subtract(Duration(days: 6 - index));

                                    const namaHari = [
                                      'Sen',
                                      'Sel',
                                      'Rab',
                                      'Kam',
                                      'Jum',
                                      'Sab',
                                      'Min',
                                    ];

                                    return Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            if (nominal > 0)
                                              Text(
                                                nominal >= 1000000
                                                    ? '${(nominal / 1000000).toStringAsFixed(1)} jt'
                                                    : nominal >= 1000
                                                        ? '${(nominal / 1000).round()} rb'
                                                        : '$nominal',
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  color:
                                                      colors.onSurfaceVariant,
                                                ),
                                              ),
                                            const SizedBox(height: 5),
                                            AnimatedContainer(
                                              duration: const Duration(
                                                milliseconds: 250,
                                              ),
                                              height: tinggi,
                                              width: double.infinity,
                                              decoration: BoxDecoration(
                                                color: hariIni
                                                    ? colors.primary
                                                    : colors.primary
                                                        .withOpacity(0.35),
                                                borderRadius:
                                                    BorderRadius.circular(7),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              namaHari[tanggal.weekday - 1],
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: hariIni
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                                color: hariIni
                                                    ? colors.primary
                                                    : colors.onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              ),
                            const Divider(height: 26),
                            Row(
                              children: [
                                Icon(
                                  Icons.insights_rounded,
                                  color: colors.primary,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Total 7 hari terakhir',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: colors.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                Text(
                                  'Rp${_formatRupiah(totalMingguan)}',
                                  style: AppTextStyles.price.copyWith(
                                    color: colors.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 26),

                      Text(
                        'Riwayat Pengeluaran',
                        style: AppTextStyles.titleLarge.copyWith(
                          color: colors.onSurface,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Pencarian.
                      TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Cari kebutuhan operasional...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _searchController.text.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Hapus pencarian',
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                  icon: const Icon(Icons.close_rounded),
                                ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Filter periode.
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final pilihan in [
                              'Hari ini',
                              '7 hari',
                              'Bulan ini',
                              'Semua',
                            ])
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(pilihan),
                                  selected: _filter == pilihan,
                                  onSelected: (_) {
                                    setState(() => _filter = pilihan);
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      if (daftar.isEmpty)
                        _tampilanKosong(
                          colors,
                          semua.isEmpty,
                        )
                      else
                        ...daftar.map(
                          (item) => _BarisPengeluaran(
                            item: item,
                            onHapus: () => _hapusPengeluaran(item.id),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _tampilanKosong(
    ColorScheme colors,
    bool belumAdaData,
  ) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(
            Icons.eco_outlined,
            size: 42,
            color: colors.primary,
          ),
          const SizedBox(height: 12),
          Text(
            belumAdaData ? 'Belum ada pengeluaran' : 'Catatan tidak ditemukan',
            style: AppTextStyles.titleMedium.copyWith(
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            belumAdaData
                ? 'Tekan tombol Catat Pengeluaran untuk memulai.'
                : 'Coba kata kunci atau filter lainnya.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          if (belumAdaData) ...[
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: _bukaFormTambah,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Catat pengeluaran'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _tampilanError(String error) {
    final colors = Theme.of(context).colorScheme;

    final tabelBelumAda =
        error.contains('does not exist') || error.contains('404');

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 44,
              color: colors.error,
            ),
            const SizedBox(height: 12),
            Text(
              'Pengeluaran belum bisa dimuat',
              textAlign: TextAlign.center,
              style: AppTextStyles.titleMedium.copyWith(
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            if (tabelBelumAda) ...[
              const SizedBox(height: 12),
              const Text(
                'Pastikan tabel pengeluaran sudah dibuat '
                'di Supabase dengan kolom id, keterangan, '
                'jumlah, dan tanggal.',
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () =>
                  context.read<PengeluaranProvider>().loadPengeluaran(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

class _KartuStatistik extends StatelessWidget {
  final String judul;
  final String nilai;
  final IconData ikon;
  final Color warna;

  const _KartuStatistik({
    required this.judul,
    required this.nilai,
    required this.ikon,
    required this.warna,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: warna.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(ikon, color: warna, size: 21),
          ),
          const SizedBox(height: 13),
          Text(
            judul,
            style: AppTextStyles.bodySmall.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            nilai,
            style: AppTextStyles.titleMedium.copyWith(
              color: colors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _BarisPengeluaran extends StatelessWidget {
  final Pengeluaran item;
  final VoidCallback onHapus;

  const _BarisPengeluaran({
    required this.item,
    required this.onHapus,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: colors.error.withOpacity(0.10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              Icons.shopping_basket_outlined,
              color: colors.error,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.keterangan,
                  style: AppTextStyles.titleSmall.copyWith(
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTanggal(item.tanggal),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '-Rp${_formatRupiah(item.jumlah)}',
                  style: AppTextStyles.price.copyWith(
                    color: colors.error,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Hapus pengeluaran',
            onPressed: onHapus,
            icon: const Icon(Icons.delete_outline_rounded),
            color: colors.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

/// Form untuk menambahkan catatan pengeluaran.
class _FormPengeluaran extends StatefulWidget {
  const _FormPengeluaran();

  @override
  State<_FormPengeluaran> createState() => _FormPengeluaranState();
}

class _FormPengeluaranState extends State<_FormPengeluaran> {
  final TextEditingController _keteranganController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController();
  final TextEditingController _hargaController = TextEditingController();

  DateTime _tanggal = DateTime.now();
  bool _menyimpan = false;

  @override
  void initState() {
    super.initState();
    _qtyController.addListener(_refreshTotal);
    _hargaController.addListener(_formatHarga);
  }

  @override
  void dispose() {
    _keteranganController.dispose();
    _qtyController.dispose();
    _hargaController.dispose();
    super.dispose();
  }

  void _refreshTotal() {
    if (mounted) setState(() {});
  }

  void _formatHarga() {
    final digits = _hargaController.text.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    if (digits.isNotEmpty) {
      final angka = int.tryParse(digits) ?? 0;
      final format = _formatRupiah(angka);

      if (format != _hargaController.text) {
        _hargaController.value = TextEditingValue(
          text: format,
          selection: TextSelection.collapsed(
            offset: format.length,
          ),
        );
        return;
      }
    }

    _refreshTotal();
  }

  int get _qty {
    final nilai = int.tryParse(_qtyController.text.trim());
    return nilai == null || nilai <= 0 ? 1 : nilai;
  }

  int get _hargaSatuan {
    final digits = _hargaController.text.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
    return int.tryParse(digits) ?? 0;
  }

  int get _totalHarga => _qty * _hargaSatuan;

  Future<void> _pilihTanggal() async {
    final tanggalDipilih = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (tanggalDipilih != null && mounted) {
      setState(() => _tanggal = tanggalDipilih);
    }
  }

  Future<void> _simpan() async {
    final keterangan = _keteranganController.text.trim();

    if (keterangan.isEmpty || _totalHarga <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Isi keterangan dan harga satuannya terlebih dahulu.',
          ),
        ),
      );
      return;
    }

    setState(() => _menyimpan = true);

    final provider = context.read<PengeluaranProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final total = _totalHarga;

    try {
      await provider.tambah(
        keterangan: keterangan,
        jumlah: total,
        tanggal: _tanggal,
      );

      if (!mounted) return;

      navigator.pop();

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Pengeluaran tersimpan: Rp${_formatRupiah(total)}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _menyimpan = false);

      messenger.showSnackBar(
        SnackBar(content: Text('Gagal menyimpan: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 26),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.outlineVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Catat Pengeluaran',
                style: AppTextStyles.displayMedium.copyWith(
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Catat kebutuhan operasional kafe.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _keteranganController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Nama kebutuhan',
                  hintText: 'Contoh: Susu, kopi, atau gas',
                  prefixIcon: Icon(Icons.shopping_bag_outlined),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _qtyController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Jumlah',
                        hintText: '1',
                        prefixIcon: Icon(Icons.numbers_rounded),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _hargaController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Harga satuan',
                        hintText: '15000',
                        prefixText: 'Rp ',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: colors.primary.withOpacity(0.30),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Total harga',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: colors.onSurface,
                        ),
                      ),
                    ),
                    Text(
                      'Rp${_formatRupiah(_totalHarga)}',
                      style: AppTextStyles.priceLarge.copyWith(
                        color: colors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pilihTanggal,
                icon: const Icon(Icons.calendar_month_outlined),
                label: Text(_formatTanggal(_tanggal)),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: _menyimpan ? null : _simpan,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                child: _menyimpan
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Simpan Pengeluaran'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
