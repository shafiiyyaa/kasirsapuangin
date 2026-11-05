/// Divisi dapur / pembuat: dipakai untuk rekap produksi di Statistik
/// (dan nanti untuk struk dapur per divisi).
enum Divisi { makanan, minuman, snack, lainnya }

extension DivisiX on Divisi {
  String get label {
    switch (this) {
      case Divisi.makanan:
        return 'Makanan';
      case Divisi.minuman:
        return 'Minuman';
      case Divisi.snack:
        return 'Snack';
      case Divisi.lainnya:
        return 'Lainnya';
    }
  }
}

/// Menentukan divisi sebuah menu dari kategori dan tipenya.
/// Cukup longgar: tidak peduli huruf besar/kecil, dan tahan terhadap nama
/// kategori buatan sendiri (mis. "Non Coffee", "Milk Based", "Snacks").
Divisi divisiDari({String? kategori, String? tipe}) {
  final teks = '${kategori ?? ''} ${tipe ?? ''}'.toLowerCase();

  if (teks.trim().isEmpty) return Divisi.lainnya;

  // Snack dicek paling awal karena tipenya biasanya tetap "makanan".
  if (teks.contains('snack') || teks.contains('camilan')) {
    return Divisi.snack;
  }

  const kataMinuman = [
    'minum',
    'drink',
    'coffee',
    'kopi',
    'milk',
    'susu',
    'brew',
    'tea',
    'teh',
    'juice',
    'jus',
    'latte',
  ];
  for (final kata in kataMinuman) {
    if (teks.contains(kata)) return Divisi.minuman;
  }

  if (teks.contains('makan') || teks.contains('food')) {
    return Divisi.makanan;
  }

  return Divisi.lainnya;
}