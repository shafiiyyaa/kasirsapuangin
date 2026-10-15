import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../menu_board/providers/pengeluaran_provider.dart';
import '../../../theme/app_theme.dart';

const _namaBulan = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
];

String _formatRupiah(int n) =>
    n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.');

class PengeluaranScreen extends StatefulWidget {
  const PengeluaranScreen({super.key});

  @override
  State<PengeluaranScreen> createState() => _PengeluaranScreenState();
}

class _PengeluaranScreenState extends State<PengeluaranScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PengeluaranProvider>().loadPengeluaran();
    });
  }

  String _labelTanggal(DateTime d) =>
      '${d.day} ${_namaBulan[d.month - 1]} ${d.year}';

  void _bukaFormTambah() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _FormPengeluaran(),
    );
  }

  Future<void> _hapus(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus pengeluaran?'),
        content: const Text(
            'Catatan pengeluaran ini akan dihapus permanen. Lanjutkan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final provider = context.read<PengeluaranProvider>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      await provider.hapus(id);
      messenger.showSnackBar(
        const SnackBar(content: Text('Pengeluaran dihapus')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Gagal menghapus: $e')),
      );
    }
  }

  /// Pesan error yang ramah, khususnya kalau tabelnya belum dibuat.
  Widget _pesanError(String error) {
    final tabelBelumAda =
        error.contains('does not exist') || error.contains('404');
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(error, textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium),
            if (tabelBelumAda) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Tabel "pengeluaran" belum ada di Supabase.\n'
                  'Jalankan SQL berikut di SQL Editor:\n\n'
                  'create table pengeluaran (\n'
                  '  id uuid primary key default gen_random_uuid(),\n'
                  '  keterangan text not null,\n'
                  '  jumlah int4 not null,\n'
                  '  tanggal date not null default current_date,\n'
                  '  created_at timestamptz not null default now()\n'
                  ');',
                  style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ],
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () =>
                  context.read<PengeluaranProvider>().loadPengeluaran(),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PengeluaranProvider>();
    final now = DateTime.now();
    final totalBulanIni = provider.totalPadaBulan(now.year, now.month);

    return Scaffold(
      appBar: AppBar(title: const Text('Pengeluaran')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _bukaFormTambah,
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.forestGreenDark,
        icon: const Icon(Icons.add),
        label: const Text('Catat'),
      ),
      body: provider.isLoading && provider.items.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null && provider.items.isEmpty
              ? _pesanError(provider.error!)
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.statusBatal.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.statusBatal.withOpacity(0.4)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Pengeluaran bulan ini',
                              style: AppTextStyles.bodyLarge),
                          Text(
                            'Rp${_formatRupiah(totalBulanIni)}',
                            style: AppTextStyles.priceLarge
                                .copyWith(color: AppColors.statusBatal),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (provider.items.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: Text(
                            'Belum ada pengeluaran.\nTekan "Catat" untuk menambah.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyMedium,
                          ),
                        ),
                      )
                    else
                      ...provider.items.map(
                        (p) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(
                            Icons.shopping_basket_outlined,
                            color: AppColors.statusBatal,
                          ),
                          title: Text(p.keterangan,
                              style: AppTextStyles.bodyLarge),
                          subtitle: Text(_labelTanggal(p.tanggal),
                              style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('-Rp${_formatRupiah(p.jumlah)}',
                                  style: AppTextStyles.price.copyWith(
                                      color: AppColors.statusBatal)),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    size: 20),
                                onPressed: () => _hapus(p.id),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }
}

/// Form tambah pengeluaran: keterangan, jumlah (auto-format rupiah), tanggal.
class _FormPengeluaran extends StatefulWidget {
  const _FormPengeluaran();

  @override
  State<_FormPengeluaran> createState() => _FormPengeluaranState();
}

class _FormPengeluaranState extends State<_FormPengeluaran> {
  final _keteranganController = TextEditingController();
  final _jumlahController = TextEditingController();
  DateTime _tanggal = DateTime.now();
  bool _menyimpan = false;

  @override
  void initState() {
    super.initState();
    _jumlahController.addListener(_formatJumlah);
  }

  @override
  void dispose() {
    _keteranganController.dispose();
    _jumlahController.dispose();
    super.dispose();
  }

  /// Format live: ketik "10000" -> tampil "10.000".
  void _formatJumlah() {
    final digits =
        _jumlahController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return;
    final formatted = _formatRupiah(int.parse(digits));
    if (formatted == _jumlahController.text) return;
    _jumlahController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  Future<void> _simpan() async {
    final keterangan = _keteranganController.text.trim();
    final digits =
        _jumlahController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final jumlah = int.tryParse(digits) ?? 0;

    if (keterangan.isEmpty || jumlah <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Isi keterangan dan jumlahnya dulu ya')),
      );
      return;
    }

    setState(() => _menyimpan = true);
    final provider = context.read<PengeluaranProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await provider.tambah(
        keterangan: keterangan,
        jumlah: jumlah,
        tanggal: _tanggal,
      );
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
            content: Text(
                'Tercatat: $keterangan (Rp${_formatRupiah(jumlah)})')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Gagal menyimpan: $e')),
      );
      if (mounted) setState(() => _menyimpan = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Catat Pengeluaran', style: AppTextStyles.displayMedium),
            const SizedBox(height: 16),
            TextField(
              controller: _keteranganController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Kebutuhan apa? (mis. Susu, Kopi, Gas)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _jumlahController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Jumlah',
                prefixText: 'Rp ',
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _tanggal,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (picked != null && mounted) {
                  setState(() => _tanggal = picked);
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      '${_tanggal.day} ${_namaBulan[_tanggal.month - 1]} ${_tanggal.year}',
                        style: AppTextStyles.bodyMedium),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _menyimpan ? null : _simpan,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child: _menyimpan
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}