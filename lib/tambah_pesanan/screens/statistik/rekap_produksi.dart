import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../menu_board/models/divisi.dart.dart';
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

/// Cadangan porsi di atas rata-rata penjualan (10%).
const double _cadangan = 0.10;

enum _Mode { harian, bulanan, tahunan }

Color _warnaDivisi(Divisi d) {
  switch (d) {
    case Divisi.makanan:
      return const Color(0xFFC96F2D);
    case Divisi.minuman:
      return const Color(0xFF2F7DA8);
    case Divisi.snack:
      return const Color(0xFF8E5BA8);
    case Divisi.lainnya:
      return const Color(0xFF7A8580);
  }
}

IconData _ikonDivisi(Divisi d) {
  switch (d) {
    case Divisi.makanan:
      return Icons.restaurant_rounded;
    case Divisi.minuman:
      return Icons.local_cafe_rounded;
    case Divisi.snack:
      return Icons.bakery_dining_rounded;
    case Divisi.lainnya:
      return Icons.more_horiz_rounded;
  }
}

String _rupiah(int n) => 'Rp${n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}';

int _angka(dynamic nilai) => (nilai as num?)?.toInt() ?? 0;

class _BarisRekap {
  final String nama;
  final String? kategori;
  final Divisi divisi;
  final int jumlah;
  final int omzet;

  const _BarisRekap({
    required this.nama,
    required this.kategori,
    required this.divisi,
    required this.jumlah,
    required this.omzet,
  });
}

/// Rekap produksi per divisi + menu terlaris (best seller)
/// per hari / bulan / tahun, lengkap dengan saran porsi.
class RekapProduksiView extends StatefulWidget {
  const RekapProduksiView({super.key});

  @override
  State<RekapProduksiView> createState() => _RekapProduksiViewState();
}

class _RekapProduksiViewState extends State<RekapProduksiView> {
  _Mode _mode = _Mode.bulanan;
  late DateTime _tanggal;
  Divisi? _filter;

  List<_BarisRekap> _baris = [];
  int _hariBuka = 0;
  bool _loading = true;
  String? _error;
  int _versi = 0; // untuk mengabaikan hasil permintaan yang sudah usang

  @override
  void initState() {
    super.initState();
    final sekarang = DateTime.now();
    _tanggal = DateTime(sekarang.year, sekarang.month, sekarang.day);
    _muat();
  }

  DateTime get _awal {
    switch (_mode) {
      case _Mode.harian:
        return DateTime(_tanggal.year, _tanggal.month, _tanggal.day);
      case _Mode.bulanan:
        return DateTime(_tanggal.year, _tanggal.month, 1);
      case _Mode.tahunan:
        return DateTime(_tanggal.year, 1, 1);
    }
  }

  DateTime get _akhir {
    switch (_mode) {
      case _Mode.harian:
        return DateTime(_tanggal.year, _tanggal.month, _tanggal.day + 1);
      case _Mode.bulanan:
        return DateTime(_tanggal.year, _tanggal.month + 1, 1);
      case _Mode.tahunan:
        return DateTime(_tanggal.year + 1, 1, 1);
    }
  }

  String get _labelPeriode {
    switch (_mode) {
      case _Mode.harian:
        return '${_hariPendek[_tanggal.weekday - 1]}, ${_tanggal.day} '
            '${_namaBulan[_tanggal.month - 1]} ${_tanggal.year}';
      case _Mode.bulanan:
        return '${_namaBulan[_tanggal.month - 1]} ${_tanggal.year}';
      case _Mode.tahunan:
        return 'Tahun ${_tanggal.year}';
    }
  }

  Future<void> _muat() async {
    final versi = ++_versi;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final hasil = await Supabase.instance.client.rpc(
        'rekap_menu',
        params: {
          'p_awal': _awal.toUtc().toIso8601String(),
          'p_akhir': _akhir.toUtc().toIso8601String(),
        },
      );

      if (!mounted || versi != _versi) return;

      final daftar = (hasil as List).cast<Map<String, dynamic>>();
      var hariBuka = 0;
      final baris = <_BarisRekap>[];

      for (final m in daftar) {
        final kategori = m['kategori'] as String?;
        final tipe = m['tipe'] as String?;
        final hari = _angka(m['hari_buka']);
        if (hari > hariBuka) hariBuka = hari;

        baris.add(
          _BarisRekap(
            nama: (m['nama_menu'] as String?) ?? '-',
            kategori: kategori,
            divisi: divisiDari(kategori: kategori, tipe: tipe),
            jumlah: _angka(m['jumlah']),
            omzet: _angka(m['omzet']),
          ),
        );
      }

      setState(() {
        _baris = baris;
        _hariBuka = hariBuka;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || versi != _versi) return;
      setState(() {
        _error = 'Gagal memuat rekap: $e';
        _loading = false;
      });
    }
  }

  void _geser(int arah) {
    setState(() {
      switch (_mode) {
        case _Mode.harian:
          _tanggal =
              DateTime(_tanggal.year, _tanggal.month, _tanggal.day + arah);
          break;
        case _Mode.bulanan:
          _tanggal = DateTime(_tanggal.year, _tanggal.month + arah, 1);
          break;
        case _Mode.tahunan:
          _tanggal = DateTime(_tanggal.year + arah, 1, 1);
          break;
      }
    });
    _muat();
  }

  Future<void> _pilihTanggal() async {
    if (_mode != _Mode.harian) return;
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

  int _saranPerHari(_BarisRekap b) {
    if (_hariBuka <= 0) return 0;
    return ((b.jumlah / _hariBuka) * (1 + _cadangan)).ceil();
  }

  int _totalDivisi(Divisi d) =>
      _baris.where((b) => b.divisi == d).fold(0, (s, b) => s + b.jumlah);

  int _jenisDivisi(Divisi d) => _baris.where((b) => b.divisi == d).length;

  @override
  Widget build(BuildContext context) {
    final tampil = _filter == null
        ? _baris
        : _baris.where((b) => b.divisi == _filter).toList();
    final terbanyak = tampil.isEmpty ? 1 : tampil.first.jumlah;
    final adaLainnya = _baris.any((b) => b.divisi == Divisi.lainnya);
    final tampilkanSaran = _mode != _Mode.harian;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<_Mode>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: _Mode.harian, label: Text('Harian')),
              ButtonSegment(value: _Mode.bulanan, label: Text('Bulanan')),
              ButtonSegment(value: _Mode.tahunan, label: Text('Tahunan')),
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
              onPressed: () => _geser(-1),
            ),
            InkWell(
              onTap: _pilihTanggal,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Text(
                  _labelPeriode,
                  style: AppTextStyles.bodyLarge
                      .copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => _geser(1),
            ),
          ],
        ),
        if (_loading) const LinearProgressIndicator(minHeight: 3),
        const SizedBox(height: 8),

        // ----- Rekap produksi per divisi -----
        const Text('Rekap Produksi per Divisi',
            style: AppTextStyles.displayMedium),
        const SizedBox(height: 4),
        Text(
          'Jumlah porsi yang harus dikerjakan tiap divisi. Ketuk untuk memfilter.',
          style: AppTextStyles.bodySmall
              .copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (final d in const [
              Divisi.makanan,
              Divisi.minuman,
              Divisi.snack,
            ]) ...[
              Expanded(
                child: _KartuDivisi(
                  divisi: d,
                  total: _totalDivisi(d),
                  jenis: _jenisDivisi(d),
                  terpilih: _filter == d,
                  onTap: () =>
                      setState(() => _filter = _filter == d ? null : d),
                ),
              ),
              if (d != Divisi.snack) const SizedBox(width: 8),
            ],
          ],
        ),
        if (adaLainnya)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Ada menu yang kategorinya belum masuk Makanan/Minuman/Snack '
              '(atau menunya sudah dihapus). Muncul di daftar "Semua".',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
          ),
        if (_filter != null)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _filter = null),
              icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
              label: const Text('Tampilkan semua divisi'),
            ),
          ),
        const SizedBox(height: 16),

        // ----- Menu terlaris -----
        Text(
          _filter == null
              ? 'Menu Terlaris'
              : 'Menu Terlaris • ${_filter!.label}',
          style: AppTextStyles.displayMedium,
        ),
        const SizedBox(height: 8),
        if (_error != null)
          Column(
            children: [
              Text(_error!, style: AppTextStyles.bodyMedium),
              const SizedBox(height: 8),
              OutlinedButton(onPressed: _muat, child: const Text('Coba Lagi')),
            ],
          )
        else if (!_loading && tampil.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('Belum ada penjualan pada periode ini.',
                style: AppTextStyles.bodyMedium),
          )
        else
          for (var i = 0; i < tampil.length; i++)
            _BarisMenu(
              peringkat: i + 1,
              baris: tampil[i],
              warna: _warnaDivisi(tampil[i].divisi),
              rasio: tampil[i].jumlah / terbanyak,
              catatan: tampilkanSaran && _hariBuka > 0
                  ? '≈ ${(tampil[i].jumlah / _hariBuka).toStringAsFixed(1)} /hari'
                      '  •  saran ${_saranPerHari(tampil[i])} porsi/hari'
                  : _rupiah(tampil[i].omzet),
            ),
        if (tampilkanSaran && tampil.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.forestGreen.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline,
                    size: 18, color: AppColors.forestGreen),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Saran porsi = rata-rata terjual per hari buka '
                    '($_hariBuka hari) ditambah cadangan '
                    '${(_cadangan * 100).round()}%. Pakai sebagai patokan '
                    'menyiapkan stok bulan berikutnya.',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _KartuDivisi extends StatelessWidget {
  final Divisi divisi;
  final int total;
  final int jenis;
  final bool terpilih;
  final VoidCallback onTap;

  const _KartuDivisi({
    required this.divisi,
    required this.total,
    required this.jenis,
    required this.terpilih,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final warna = _warnaDivisi(divisi);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: warna.withValues(alpha: terpilih ? 0.18 : 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: warna.withValues(alpha: terpilih ? 0.9 : 0.35),
            width: terpilih ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(_ikonDivisi(divisi), color: warna, size: 22),
            const SizedBox(height: 4),
            Text(
              divisi.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: warna,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$total',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            Text(
              'porsi • $jenis menu',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10.5, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarisMenu extends StatelessWidget {
  final int peringkat;
  final _BarisRekap baris;
  final Color warna;
  final double rasio;
  final String catatan;

  const _BarisMenu({
    required this.peringkat,
    required this.baris,
    required this.warna,
    required this.rasio,
    required this.catatan,
  });

  Color get _warnaPeringkat {
    switch (peringkat) {
      case 1:
        return const Color(0xFFE0A526);
      case 2:
        return const Color(0xFF9AA3A8);
      case 3:
        return const Color(0xFFB87333);
      default:
        return Colors.black26;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: _warnaPeringkat.withValues(alpha: 0.18),
            child: Text(
              '$peringkat',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: peringkat <= 3 ? _warnaPeringkat : Colors.black54,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        baris.nama,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyLarge
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${baris.jumlah} porsi',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: rasio.clamp(0.0, 1.0).toDouble(),
                    minHeight: 7,
                    color: warna,
                    backgroundColor: warna.withValues(alpha: 0.12),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${baris.divisi.label}'
                  '${baris.kategori == null ? '' : ' • ${baris.kategori}'}'
                  '  |  $catatan',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}