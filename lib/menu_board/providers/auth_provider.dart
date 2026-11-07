import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profil.dart';

class AuthProvider extends ChangeNotifier {
  Profil? _profil;
  bool _sedangMasuk = false;
  String? _error;

  Profil? get profil => _profil;
  bool get sudahMasuk => _profil != null;
  bool get isAdmin => _profil?.isAdmin ?? false;
  bool get sedangMasuk => _sedangMasuk;
  String? get error => _error;

  SupabaseClient get _client => Supabase.instance.client;

  /// Username diubah jadi email palsu karena Supabase Auth butuh email.
  static String emailDari(String username) =>
      '${username.trim().toLowerCase()}@sapuangin.app';

  Future<Profil?> _muatProfil(String id) async {
    final data =
        await _client.from('profiles').select().eq('id', id).maybeSingle();
    return data == null ? null : Profil.fromMap(data);
  }

  /// Dipanggil sekali saat aplikasi mulai: pulihkan sesi yang tersimpan.
  Future<void> pulihkanSesi() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      final profil = await _muatProfil(user.id);
      if (profil == null || !profil.aktif) {
        await _client.auth.signOut();
        _profil = null;
      } else {
        _profil = profil;
      }
    } catch (_) {
      // Jaringan bermasalah: anggap belum masuk, tampilkan halaman login.
      _profil = null;
    }
  }

  Future<bool> masuk(String username, String password) async {
    if (_sedangMasuk) return false;

    if (username.trim().isEmpty || password.isEmpty) {
      _error = 'Isi username dan password.';
      notifyListeners();
      return false;
    }

    _sedangMasuk = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _client.auth.signInWithPassword(
        email: emailDari(username),
        password: password,
      );

      final user = res.user;
      if (user == null) {
        _error = 'Login gagal. Coba lagi.';
        return false;
      }

      final profil = await _muatProfil(user.id);
      if (profil == null) {
        await _client.auth.signOut();
        _error = 'Akun ini belum terdaftar sebagai karyawan.';
        return false;
      }
      if (!profil.aktif) {
        await _client.auth.signOut();
        _error = 'Akun ini sudah dinonaktifkan. Hubungi admin.';
        return false;
      }

      _profil = profil;
      return true;
    } on AuthException catch (e) {
      final pesan = e.message.toLowerCase();
      _error = pesan.contains('invalid')
          ? 'Username atau password salah.'
          : e.message;
      return false;
    } catch (e) {
      _error = 'Tidak bisa masuk: $e';
      return false;
    } finally {
      _sedangMasuk = false;
      notifyListeners();
    }
  }

  Future<void> keluar() async {
    try {
      await _client.auth.signOut();
    } catch (_) {
      // Tetap keluar secara lokal walau jaringan bermasalah.
    }
    _profil = null;
    _error = null;
    notifyListeners();
  }
}