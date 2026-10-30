import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_theme.dart';
import '../config_pelanggan.dart';
import '../pelanggan_service.dart';
import '../widgets/doodle_latar.dart';

/// Halaman status pesanan. Diperbarui otomatis tiap 5 detik.
class StatusPesananScreen extends StatefulWidget {
  final String orderId;

  const StatusPesananScreen({super.key, required this.orderId});

  @override
  State<StatusPesananScreen> createState() => _StatusPesananScreenState();
}

class _StatusPesananScreenState extends State<StatusPesananScreen> {
  Timer? _timer;
  StatusPesanan? _status;
  bool _loading = true;
  bool _tidakAda = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _muat();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _muat());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _muat() async {
    try {
      final hasil = await PelangganService.ambilStatus(widget.orderId);
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = null;
        _status = hasil;
        _tidakAda = hasil == null;
      });

      if (hasil == null || hasil.batal || hasil.sudahDiantar) {
        _timer?.cancel();
      }
    } on PelangganException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.pesan;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(child: DoodleLatar()),
          SafeArea(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _tidakAda
                    ? _pesanTengah(
                        Icons.search_off_rounded,
                        'Pesanan tidak ditemukan.',
                      )
                    : _status == null
                        ? _pesanTengah(
                            Icons.wifi_off_rounded,
                            _error ?? 'Tidak bisa memuat status pesanan.',
                            bisaCobaLagi: true,
                          )
                        : _isi(_status!),
          ),
        ],
      ),
    );
  }

  Widget _pesanTengah(IconData icon, String pesan, {bool bisaCobaLagi = false}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44),
            const SizedBox(height: 12),
            Text(pesan, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            if (bisaCobaLagi)
              FilledButton(
                onPressed: _muat,
                child: const Text('Coba lagi'),
              ),
            TextButton(
              onPressed: () => context.go('/'),
              child: const Text('Kembali ke menu'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _isi(StatusPesanan s) {
    final String judul;
    final String subjudul;
    final IconData ikon;
    final Color warnaIkon;

    if (s.batal) {
      judul = 'Pesanan dibatalkan';
      subjudul = 'Silakan hubungi kasir untuk informasi lebih lanjut.';
      ikon = Icons.cancel_rounded;
      warnaIkon = AppColors.statusBatal;
    } else if (s.sudahDiantar) {
      judul = 'Selamat menikmati!';
      subjudul = 'Pesananmu sudah diantar.';
      ikon = Icons.check_circle_rounded;
      warnaIkon = AppColors.statusSelesai;
    } else {
      judul = 'Pesanan terkirim!';
      subjudul = 'Pesananmu sudah masuk ke kasir.';
      ikon = Icons.check_circle_rounded;
      warnaIkon = AppColors.forestGreen;
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 12),
        Center(
          child: TweenAnimationBuilder<double>(
            key: ValueKey(judul),
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 750),
            curve: Curves.elasticOut,
            builder: (context, nilai, child) {
              return Transform.scale(scale: nilai, child: child);
            },
            child: Icon(ikon, size: 64, color: warnaIkon),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          judul,
          textAlign: TextAlign.center,
          style: AppTextStyles.displayMedium,
        ),
        const SizedBox(height: 6),
        Text(
          subjudul,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _baris('Tempat', s.meja == null ? 'Take away' : 'Meja ${s.meja}'),
                const SizedBox(height: 10),
                _baris('Total', rupiah(s.total)),
                const SizedBox(height: 10),
                _baris(
                  'Pembayaran',
                  s.sudahBayar ? 'Sudah dibayar' : 'Belum dibayar',
                  warna: s.sudahBayar
                      ? AppColors.statusSelesai
                      : AppColors.warning,
                ),
              ],
            ),
          ),
        ),
        if (!s.sudahBayar && !s.batal) ...[
          const SizedBox(height: 8),
          const Text(
            'Selesaikan pembayaran lewat kasir. Status akan berubah setelah kasir mengonfirmasi.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.lightTextSecondary,
              height: 1.4,
            ),
          ),
        ],
        if (!s.batal) ...[
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _langkah(s, 0, 'Pesanan diterima',
                      'Kasir sudah menerima pesananmu'),
                  _langkah(s, 1, 'Sedang disiapkan', 'Pesananmu sedang dibuat'),
                  _langkah(
                    s,
                    2,
                    'Siap diantar',
                    s.meja == null
                        ? 'Silakan ambil di kasir'
                        : 'Segera diantar ke mejamu',
                  ),
                  _langkah(s, 3, 'Sudah diantar', 'Selamat menikmati!',
                      terakhir: true),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),
        const Text(
          'Halaman ini diperbarui otomatis.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: AppColors.lightTextSecondary),
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () => context.go('/'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
          child: const Text('Pesan lagi'),
        ),
      ],
    );
  }

  Widget _baris(String label, String nilai, {Color? warna}) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.lightTextSecondary,
          ),
        ),
        const Spacer(),
        Text(
          nilai,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: warna,
          ),
        ),
      ],
    );
  }

  Widget _langkah(
    StatusPesanan s,
    int indeks,
    String judul,
    String keterangan, {
    bool terakhir = false,
  }) {
    final aktif = s.langkahAktif;
    final selesai = indeks < aktif || aktif == 3;
    final berjalan = indeks == aktif && aktif != 3;

    final IconData ikon;
    final Color warna;
    if (selesai) {
      ikon = Icons.check_circle_rounded;
      warna = AppColors.forestGreen;
    } else if (berjalan) {
      ikon = Icons.radio_button_checked_rounded;
      warna = AppColors.gold;
    } else {
      ikon = Icons.radio_button_unchecked_rounded;
      warna = AppColors.abu;
    }

    return Padding(
      padding: EdgeInsets.only(bottom: terakhir ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(ikon, color: warna, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  judul,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: (selesai || berjalan)
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: (selesai || berjalan)
                        ? AppColors.lightTextPrimary
                        : AppColors.abu,
                  ),
                ),
                if (selesai || berjalan)
                  Text(
                    keterangan,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.lightTextSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}