import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../l10n/bahasa.dart';
import '../../theme/app_colors.dart';
import 'supabase_service.dart';

/// Notifikasi pesanan masuk (mis. dari QR per meja).
///
/// Cara kerja:
/// 1. Mendengarkan baris BARU di tabel `orders` lewat Supabase Realtime.
/// 2. Pesanan yang dibuat kasir sendiri (sumber 'kasir' + ada nama kasir)
///    diabaikan. Selebihnya (mis. sumber 'qr') dianggap pesanan masuk.
/// 3. Membunyikan nada dan menampilkan banner di atas layar. Nada diulang
///    tiap beberapa detik (maksimal beberapa kali) sampai kasir menekan
///    LIHAT atau TUTUP.
///
/// Catatan: hanya bekerja selama aplikasi terbuka.
class NotifikasiPesanan {
  NotifikasiPesanan._();

  static final NotifikasiPesanan instance = NotifikasiPesanan._();

  /// Dipasang di MaterialApp.router (scaffoldMessengerKey) supaya banner
  /// bisa tampil di layar mana pun.
  final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static const int _maksBunyi = 6;
  static const Duration _jedaUlang = Duration(seconds: 5);

  /// Nada yang dipakai. Isi dengan nama salah satu file di assets/sounds/:
  /// 'bel_ketuk.wav', 'dering_telepon.wav', 'alarm_beep.wav', 'sirine.wav',
  /// 'ting_tong_keras.wav', atau 'ding_dong_lembut.wav'.
  static const String _fileSuara = 'pesanan_masuk.wav';

  final AudioPlayer _player = AudioPlayer();
  final Set<String> _sudahDiberitahu = {};

  RealtimeChannel? _channel;
  Timer? _timerUlang;
  int _belumDilihat = 0;
  int _hitungBunyi = 0;
  String? _infoTerakhir;

  VoidCallback? _onPesananMasuk;
  VoidCallback? _onLihat;

  /// Mulai mendengarkan pesanan baru. Aman dipanggil berulang kali.
  ///
  /// [onPesananMasuk] dipanggil untuk memuat ulang daftar pesanan.
  /// [onLihat] dipanggil saat kasir menekan LIHAT (mis. buka halaman riwayat).
  void mulai({VoidCallback? onPesananMasuk, VoidCallback? onLihat}) {
    _onPesananMasuk = onPesananMasuk;
    _onLihat = onLihat;
    if (_channel != null) return;

    _channel = SupabaseService.client
        .channel('pesanan-masuk')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'orders',
          callback: _saatOrderBaru,
        )
        .subscribe();
  }

  /// Berhenti mendengarkan (mis. saat logout).
  Future<void> berhenti() async {
    _hentikanBunyi();
    _belumDilihat = 0;
    _infoTerakhir = null;
    messengerKey.currentState?.removeCurrentMaterialBanner();

    final channel = _channel;
    _channel = null;
    if (channel != null) {
      try {
        await SupabaseService.client.removeChannel(channel);
      } catch (_) {}
    }
  }

  // ------------------------------------------------------------
  // Pesanan baru
  // ------------------------------------------------------------

  void _saatOrderBaru(PostgresChangePayload payload) {
    final baru = payload.newRecord;
    final id = baru['id']?.toString();
    if (id == null || !_sudahDiberitahu.add(id)) return;

    final sumber = (baru['sumber_pesanan'] ?? '').toString();
    final kasir = (baru['kasir'] ?? '').toString().trim();

    // Pesanan yang dibuat lewat aplikasi kasir tidak perlu diberi tahu.
    if (sumber == 'kasir' && kasir.isNotEmpty) return;

    final meja = (baru['meja'] ?? '').toString().trim();
    final nama = (baru['nama_pelanggan'] ?? '').toString().trim();
    final takeaway = (baru['jenis_pesanan'] ?? '').toString() == 'takeaway';

    final bagian = <String>[
      if (takeaway) 'Takeaway' else if (meja.isNotEmpty) tr('Meja {m}', {'m': meja}),
      if (nama.isNotEmpty) nama,
    ];
    _infoTerakhir = bagian.isEmpty ? tr('Pesanan dari QR') : bagian.join(' • ');

    _belumDilihat++;
    _tampilkanBanner();
    _mulaiBunyi();

    // Item pesanan disimpan SESUDAH baris pesanan, jadi muat ulang sebentar
    // lagi (dua kali, supaya aman kalau jaringan lambat).
    Future.delayed(const Duration(milliseconds: 1500), () => _onPesananMasuk?.call());
    Future.delayed(const Duration(seconds: 5), () => _onPesananMasuk?.call());
  }

  // ------------------------------------------------------------
  // Banner
  // ------------------------------------------------------------

  void _tampilkanBanner() {
    final messenger = messengerKey.currentState;
    if (messenger == null) return;

    messenger.removeCurrentMaterialBanner();

    final judul = _belumDilihat > 1
        ? tr('{n} pesanan baru masuk!', {'n': _belumDilihat})
        : tr('Pesanan baru masuk!');

    messenger.showMaterialBanner(
      MaterialBanner(
        backgroundColor: AppColors.forestGreen,
        leading: const Icon(Icons.notifications_active, color: Colors.white),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              judul,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            if (_infoTerakhir != null)
              Text(
                _infoTerakhir!,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _lihat,
            child: Text(
              tr('LIHAT'),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: _tutup,
            child: Text(
              tr('TUTUP'),
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  void _lihat() {
    _tutup();
    _onLihat?.call();
  }

  void _tutup() {
    _hentikanBunyi();
    _belumDilihat = 0;
    messengerKey.currentState?.removeCurrentMaterialBanner();
  }

  // ------------------------------------------------------------
  // Suara
  // ------------------------------------------------------------

  Future<void> _bunyi() async {
    try {
      await _player.stop();
      await _player.setVolume(1.0);
      await _player.play(AssetSource('sounds/$_fileSuara'));
    } catch (_) {
      // Cadangan kalau file suara belum terpasang.
      SystemSound.play(SystemSoundType.alert);
    }
  }

  void _mulaiBunyi() {
    _timerUlang?.cancel();
    _hitungBunyi = 1;
    _bunyi();

    _timerUlang = Timer.periodic(_jedaUlang, (timer) {
      if (_belumDilihat == 0 || _hitungBunyi >= _maksBunyi) {
        timer.cancel();
        return;
      }
      _hitungBunyi++;
      _bunyi();
    });
  }

  void _hentikanBunyi() {
    _timerUlang?.cancel();
    _timerUlang = null;
    _player.stop().catchError((_) {});
  }
}