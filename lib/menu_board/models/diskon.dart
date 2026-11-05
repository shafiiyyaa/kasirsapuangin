/// Pengaturan diskon global (berlaku untuk semua menu).
class DiskonSetting {
  final bool aktif;
  final String tipe; // 'persen' atau 'nominal'
  final int nilai;
  final String? label;

  const DiskonSetting({
    this.aktif = false,
    this.tipe = 'persen',
    this.nilai = 0,
    this.label,
  });

  static const nonaktif = DiskonSetting();

  bool get persen => tipe == 'persen';

  factory DiskonSetting.fromMap(Map<String, dynamic> map) {
    return DiskonSetting(
      aktif: map['aktif'] as bool? ?? false,
      tipe: (map['tipe'] as String?) ?? 'persen',
      nilai: (map['nilai'] as num?)?.toInt() ?? 0,
      label: map['label'] as String?,
    );
  }

  /// Besar potongan untuk [subtotal] (harga asli). Tidak pernah melebihi subtotal.
  int hitung(int subtotal) {
    if (!aktif || nilai <= 0 || subtotal <= 0) return 0;
    final potongan = persen ? (subtotal * nilai / 100).round() : nilai;
    return potongan > subtotal ? subtotal : potongan;
  }

  /// Nama yang dicetak di struk dan disimpan di pesanan.
  String get namaStruk {
    final l = label?.trim();
    final dasar = (l == null || l.isEmpty) ? 'Diskon' : l;
    return persen ? '$dasar ($nilai%)' : dasar;
  }
}