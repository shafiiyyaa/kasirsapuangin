import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../l10n/bahasa.dart';
import '../../../menu_board/models/pengeluaran.dart';
import '../../../menu_board/services/pengeluaran_service.dart';
import '../../../theme/app_theme.dart';
import '../../widgets/app_scaffold.dart';

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

String _tanggalPanjang(DateTime t) =>
    '${tr(_hariPendek[t.weekday - 1])}, ${t.day} ${tr(_namaBulan[t.month - 1])} ${t.year}';

/// Halaman Pengeluaran: tambah, lihat, ubah, dan hapus pengeluaran
/// per bulan. Hanya bisa dibuka admin (dijaga oleh router di main.dart).
class PengeluaranScreen extends StatefulWidget {
  const PengeluaranScreen({super.key});

  @override
  State<PengeluaranScreen> createState() => _PengeluaranScreenState();
}

class _PengeluaranScreenState extends State<PengeluaranScreen> {
  late DateTime _bulan; // tanggal 1 bulan yang sedang dilihat
  List<Pengeluaran> _data = [];
  bool _loading = true;
  String? _error;
  int _versi = 0; // abaikan hasil permintaan yang sudah usang

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _bulan = DateTime(now.year, now.month);
    _muat();
  }

  Future<void> _muat() async {
    final versi = ++_versi;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final awal = DateTime(_bulan.year, _bulan.month, 1);
      final akhir = DateTime(_bulan.year, _bulan.month + 1, 1);
      final data = await PengeluaranService.fetchPeriode(awal, akhir);
      if (!mounted || versi != _versi) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || versi != _versi) return;
      setState(() {
        _error = tr('Gagal memuat pengeluaran: {e}', {'e': e});
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

  int get _total => _data.fold(0, (s, p) => s + p.jumlah);

  void _pesan(String teks, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(teks),
        backgroundColor: error ? AppColors.statusBatal : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _bukaForm([Pengeluaran? lama]) async {
    final sekarang = DateTime.now();
    final bulanIni =
        sekarang.year == _bulan.year && sekarang.month == _bulan.month;
    final tanggalAwal = bulanIni
        ? DateTime(sekarang.year, sekarang.month, sekarang.day)
        : DateTime(_bulan.year, _bulan.month, 1);

    final berubah = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FormPengeluaran(lama: lama, tanggalAwal: tanggalAwal),
    );
    if (!mounted) return;
    if (berubah == true) {
      _pesan(tr('Pengeluaran berhasil disimpan'));
      await _muat();
    }
  }

  Future<void> _hapus(Pengeluaran p) async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(tr('Hapus pengeluaran ini?')),
        content: Text(
          tr('Pengeluaran sebesar Rp{n} bakal dihapus permanen. Lanjut?',
              {'n': _rp(p.jumlah)}),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr('Batal')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              tr('Hapus'),
              style: const TextStyle(color: AppColors.statusBatal),
            ),
          ),
        ],
      ),
    );
    if (yakin != true) return;

    try {
      await PengeluaranService.hapus(p.id);
      if (!mounted) return;
      _pesan(tr('Pengeluaran sudah dihapus'));
      await _muat();
    } catch (e) {
      if (!mounted) return;
      _pesan(tr('Gagal hapus: {e}', {'e': e}), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild otomatis saat bahasa diganti.
    context.watch<Bahasa>();

    final dark = Theme.of(context).brightness == Brightness.dark;
    final wide = AppScaffold.isWide(context);

    return Scaffold(
      appBar: wide
          ? null
          : AppBar(
              title: Text(tr('Pengeluaran')),
              leading: IconButton(
                icon: const Icon(Icons.menu),
                tooltip: tr('Buka menu'),
                onPressed: () => AppScaffold.openMenu(context),
              ),
              actions: [
                IconButton(
                  onPressed: _muat,
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: tr('Muat ulang'),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _bukaForm(),
        backgroundColor: AppColors.forestGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(tr('Tambah')),
      ),
      body: RefreshIndicator(
        onRefresh: _muat,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          children: [
            if (wide) ...[
              Text(tr('Pengeluaran'), style: AppTextStyles.displayMedium),
              const SizedBox(height: 8),
            ],

            // ----- Pemilih bulan -----
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _loading ? null : () => _gantiBulan(-1),
                ),
                Text(
                  '${tr(_namaBulan[_bulan.month - 1])} ${_bulan.year}',
                  style: AppTextStyles.bodyLarge
                      .copyWith(fontWeight: FontWeight.w700),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _loading ? null : () => _gantiBulan(1),
                ),
              ],
            ),
            if (_loading) const LinearProgressIndicator(minHeight: 3),
            const SizedBox(height: 8),

            // ----- Total bulan ini -----
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      tr('Total Pengeluaran'),
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: dark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                  ),
                  Text(
                    'Rp${_rp(_total)}',
                    style: AppTextStyles.priceLarge
                        .copyWith(color: AppColors.warning),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ----- Daftar -----
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
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
            else if (!_loading && _data.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    tr('Belum ada pengeluaran bulan ini.'),
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
              )
            else
              for (final p in _data)
                _BarisPengeluaran(
                  data: p,
                  dark: dark,
                  onTap: () => _bukaForm(p),
                  onHapus: () => _hapus(p),
                ),
          ],
        ),
      ),
    );
  }
}

class _BarisPengeluaran extends StatelessWidget {
  final Pengeluaran data;
  final bool dark;
  final VoidCallback onTap;
  final VoidCallback onHapus;

  const _BarisPengeluaran({
    required this.data,
    required this.dark,
    required this.onTap,
    required this.onHapus,
  });

  @override
  Widget build(BuildContext context) {
    final surface = dark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = dark ? AppColors.darkBorder : AppColors.lightBorder;
    final primary =
        dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondary =
        dark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.south_west_rounded,
                    size: 20,
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rp${_rp(data.jumlah)}',
                        style: AppTextStyles.price.copyWith(color: primary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _tanggalPanjang(data.tanggal),
                        style: AppTextStyles.bodySmall
                            .copyWith(color: secondary),
                      ),
                      if (data.keterangan.trim().isNotEmpty)
                        Text(
                          data.keterangan.trim(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall
                              .copyWith(color: secondary),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: tr('Hapus'),
                  onPressed: onHapus,
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.statusBatal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Memberi titik ribuan otomatis saat mengetik jumlah: 15000 -> 15.000
class _RibuanFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digit = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digit.isEmpty) return const TextEditingValue(text: '');
    final teks = _rp(int.parse(digit));
    return TextEditingValue(
      text: teks,
      selection: TextSelection.collapsed(offset: teks.length),
    );
  }
}

/// Form tambah / ubah pengeluaran (bottom sheet).
/// Isi: tanggal, jumlah, dan catatan (opsional).
class _FormPengeluaran extends StatefulWidget {
  final Pengeluaran? lama;
  final DateTime tanggalAwal;

  const _FormPengeluaran({required this.lama, required this.tanggalAwal});

  @override
  State<_FormPengeluaran> createState() => _FormPengeluaranState();
}

class _FormPengeluaranState extends State<_FormPengeluaran> {
  late DateTime _tanggal;
  final TextEditingController _jumlahCtrl = TextEditingController();
  final TextEditingController _catatanCtrl = TextEditingController();
  bool _menyimpan = false;
  String? _errorJumlah;

  bool get _edit => widget.lama != null;

  @override
  void initState() {
    super.initState();
    final lama = widget.lama;
    if (lama != null) {
      _tanggal = DateTime(lama.tanggal.year, lama.tanggal.month, lama.tanggal.day);
      _jumlahCtrl.text = _rp(lama.jumlah);
      _catatanCtrl.text = lama.keterangan;
    } else {
      _tanggal = widget.tanggalAwal;
    }
  }

  @override
  void dispose() {
    _jumlahCtrl.dispose();
    _catatanCtrl.dispose();
    super.dispose();
  }

  Future<void> _pilihTanggal() async {
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
  }

  Future<void> _simpan() async {
    final jumlah = int.tryParse(_jumlahCtrl.text.replaceAll('.', '')) ?? 0;
    if (jumlah <= 0) {
      setState(() => _errorJumlah = tr('Isi jumlah pengeluaran dulu.'));
      return;
    }

    setState(() {
      _errorJumlah = null;
      _menyimpan = true;
    });

    final item = Pengeluaran(
      id: widget.lama?.id ?? '',
      keterangan: _catatanCtrl.text.trim(),
      jumlah: jumlah,
      tanggal: _tanggal,
    );

    try {
      if (_edit) {
        await PengeluaranService.ubah(widget.lama!.id, item);
      } else {
        await PengeluaranService.tambah(item);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _menyimpan = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('Gagal menyimpan pengeluaran: {e}', {'e': e})),
          backgroundColor: AppColors.statusBatal,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final surface = dark ? AppColors.darkSurface : AppColors.lightSurface;
    final primary =
        dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final bawah = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bawah),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _edit ? tr('Edit Pengeluaran') : tr('Tambah Pengeluaran'),
                style: AppTextStyles.displayMedium.copyWith(color: primary),
              ),
              const SizedBox(height: 16),

              // Tanggal
              InkWell(
                onTap: _menyimpan ? null : _pilihTanggal,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: tr('Tanggal'),
                    suffixIcon: const Icon(Icons.calendar_month_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _tanggalPanjang(_tanggal),
                    style: AppTextStyles.bodyLarge.copyWith(color: primary),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Jumlah
              TextField(
                controller: _jumlahCtrl,
                enabled: !_menyimpan,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(12),
                  _RibuanFormatter(),
                ],
                decoration: InputDecoration(
                  labelText: tr('Jumlah / Total'),
                  prefixText: 'Rp ',
                  errorText: _errorJumlah,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Catatan (opsional)
              TextField(
                controller: _catatanCtrl,
                enabled: !_menyimpan,
                maxLength: 80,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: tr('Catatan (opsional)'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _menyimpan ? null : () => Navigator.pop(context),
                      child: Text(tr('Batal')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _menyimpan ? null : _simpan,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.forestGreen,
                      ),
                      child: _menyimpan
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(tr('Simpan')),
                    ),
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