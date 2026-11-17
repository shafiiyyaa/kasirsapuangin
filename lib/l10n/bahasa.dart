import 'package:flutter/foundation.dart';

import 'kamus_en_a.dart';
import 'kamus_en_b.dart';
import 'kamus_en_c.dart';
import 'kamus_en_d.dart';

/// Pengaturan bahasa aplikasi: 'id' (Indonesia) atau 'en' (English).
///
/// Cara kerja: teks Indonesia dipakai sebagai kunci. Jika bahasa Inggris
/// dipilih dan terjemahannya ada di kamus, teks Inggris dipakai. Jika belum
/// ada, teks Indonesia tetap tampil (tidak pernah error).
class Bahasa extends ChangeNotifier {
  Bahasa._();

  static final Bahasa instance = Bahasa._();

  String _kode = 'id';

  String get kode => _kode;

  bool get inggris => _kode == 'en';

  static final Map<String, String> _en = {
    ...kamusEnA,
    ...kamusEnB,
    ...kamusEnC,
    ...kamusEnD,
  };

  void atur(String kode) {
    if (kode != 'id' && kode != 'en') return;
    if (kode == _kode) return;
    _kode = kode;
    notifyListeners();
  }

  String terjemah(String indonesia, [Map<String, Object?>? isi]) {
    var teks = _kode == 'en' ? (_en[indonesia] ?? indonesia) : indonesia;
    if (isi != null) {
      isi.forEach((nama, nilai) {
        teks = teks.replaceAll('{$nama}', '$nilai');
      });
    }
    return teks;
  }
}

/// Pintasan terjemahan. Contoh: `tr('Kelola Menu')`,
/// atau dengan isian: `tr('{n} pesanan', {'n': 5})`.
String tr(String indonesia, [Map<String, Object?>? isi]) =>
    Bahasa.instance.terjemah(indonesia, isi);