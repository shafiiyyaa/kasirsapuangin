import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../menu_board/models/diskon.dart';
import '../../../menu_board/providers/order_provider.dart';
import '../../../menu_board/services/supabase_service.dart';
import '../../../theme/app_colors.dart';

/// Memberi titik pemisah ribuan: "1000" -> "1.000", "1500000" -> "1.500.000".
String _ribuan(String digit) {
  final buffer = StringBuffer();
  for (var i = 0; i < digit.length; i++) {
    buffer.write(digit[i]);
    final sisa = digit.length - i - 1;
    if (sisa > 0 && sisa % 3 == 0) buffer.write('.');
  }
  return buffer.toString();
}

/// Format angka otomatis saat mengetik (1000 jadi 1.000).
class _FormatterRibuan extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digit = newValue.text.replaceAll(RegExp('[^0-9]'), '');
    if (digit.isEmpty) return const TextEditingValue(text: '');
    final hasil = _ribuan(digit);
    return TextEditingValue(
      text: hasil,
      selection: TextSelection.collapsed(offset: hasil.length),
    );
  }
}

class DiskonPengaturanCard extends StatefulWidget {
  const DiskonPengaturanCard({super.key});

  @override
  State<DiskonPengaturanCard> createState() => _DiskonPengaturanCardState();
}

class _DiskonPengaturanCardState extends State<DiskonPengaturanCard> {
  final _nilaiC = TextEditingController();
  final _labelC = TextEditingController();

  bool _aktif = false;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  @override
  void dispose() {
    _nilaiC.dispose();
    _labelC.dispose();
    super.dispose();
  }

  static String _rp(int n) => 'Rp${_ribuan(n.toString())}';

  /// Nilai angka dari kolom (titik pemisah ribuan diabaikan).
  int get _nilaiAngka =>
      int.tryParse(_nilaiC.text.replaceAll('.', '')) ?? 0;

  Future<void> _muat() async {
    try {
      final s = await SupabaseService.fetchDiskon();
      if (!mounted) return;
      setState(() {
        _aktif = s.aktif;
        // Tipe diskon selalu nominal (Rp). Pilihan Persen (%) sudah
        // dihapus sesuai permintaan; diskon selalu berupa potongan tetap.
        _nilaiC.text = s.nilai > 0 ? _ribuan(s.nilai.toString()) : '';
        _labelC.text = s.label ?? '';
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Gagal memuat diskon. Pastikan sql_diskon.sql sudah '
            'dijalankan di Supabase.\n\nDetail: $e';
        _loading = false;
      });
    }
  }

  void _muatUlang() {
    setState(() {
      _loading = true;
      _error = null;
    });
    _muat();
  }

  DiskonSetting get _draft => DiskonSetting(
        aktif: _aktif,
        tipe: 'nominal',
        nilai: _nilaiAngka,
        label: _labelC.text.trim().isEmpty ? null : _labelC.text.trim(),
      );

  Future<void> _simpan() async {
    final d = _draft;
    final messenger = ScaffoldMessenger.of(context);

    if (d.aktif && d.nilai <= 0) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Isi besar diskon dulu.')),
      );
      return;
    }
    if (d.nilai > 100000000) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Diskon nominal terlalu besar.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await SupabaseService.simpanDiskon(d);
      if (!mounted) return;
      await context.read<OrderProvider>().loadDiskon();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            d.aktif ? 'Diskon disimpan dan aktif.' : 'Diskon dinonaktifkan.',
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Gagal menyimpan diskon: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_error!, style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: _muatUlang,
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      );
    }

    final contoh = DiskonSetting(
      aktif: true,
      tipe: 'nominal',
      nilai: _nilaiAngka,
    ).hitung(100000);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Aktifkan diskon',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            subtitle: const Text(
              'Berlaku untuk semua menu di pesanan baru.',
              style: TextStyle(fontSize: 12),
            ),
            value: _aktif,
            activeThumbColor: AppColors.forestGreen,
            onChanged: (v) => setState(() => _aktif = v),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nilaiC,
            keyboardType: TextInputType.number,
            inputFormatters: [_FormatterRibuan()],
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Besar diskon (Rp)',
              hintText: 'contoh: 5.000',
              prefixText: 'Rp ',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _labelC,
            decoration: const InputDecoration(
              labelText: 'Nama promo (opsional, tampil di struk)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Contoh: Rp100.000 - ${_rp(contoh)} = ${_rp(100000 - contoh)}',
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _simpan,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Simpan Diskon'),
            ),
          ),
        ],
      ),
    );
  }
}