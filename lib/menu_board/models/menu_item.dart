/// Model untuk satu item menu (mewakili baris di tabel `menu_items`
/// pada Supabase).
class MenuItem {
  final String id;
  final String nama;
  final String kategori; // mis. "Manual Brew", "Coffee Based", "Food", dst
  final String tipe; // "makanan" atau "minuman"
  final int harga; // dalam Rupiah, disimpan sebagai int (mis. 15000)
  final bool tersedia; // status stok: tersedia / habis
  final String? catatan; // opsional, mis. varian "Hot/Ice" dipisah jadi 2 baris
  /// URL foto menu jika kolom gambar_url/image_url tersedia di Supabase.
  final String? gambarUrl;
  final DateTime createdAt;

  const MenuItem({
    required this.id,
    required this.nama,
    required this.kategori,
    required this.tipe,
    required this.harga,
    this.tersedia = true,
    this.catatan,
    this.gambarUrl,
    required this.createdAt,
  });

  factory MenuItem.fromMap(Map<String, dynamic> map) {
    return MenuItem(
      id: map['id'] as String,
      nama: map['nama'] as String,
      kategori: map['kategori'] as String,
      tipe: map['tipe'] as String? ?? 'makanan',
      harga: map['harga'] as int,
      tersedia: map['tersedia'] as bool? ?? true,
      catatan: map['catatan'] as String?,
      gambarUrl: (map['gambar_url'] ?? map['image_url'] ?? map['foto_url']) as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama': nama,
      'kategori': kategori,
      'tipe': tipe,
      'harga': harga,
      'tersedia': tersedia,
      'catatan': catatan,
    };
  }

  /// Dipakai saat insert baru — tanpa id & created_at (digenerate Supabase).
  Map<String, dynamic> toInsertMap() {
    return {
      'nama': nama,
      'kategori': kategori,
      'tipe': tipe,
      'harga': harga,
      'tersedia': tersedia,
      'catatan': catatan,
    };
  }

  MenuItem copyWith({
    String? nama,
    String? kategori,
    String? tipe,
    int? harga,
    bool? tersedia,
    String? catatan,
    String? gambarUrl,
  }) {
    return MenuItem(
      id: id,
      nama: nama ?? this.nama,
      kategori: kategori ?? this.kategori,
      tipe: tipe ?? this.tipe,
      harga: harga ?? this.harga,
      tersedia: tersedia ?? this.tersedia,
      catatan: catatan ?? this.catatan,
      gambarUrl: gambarUrl ?? this.gambarUrl,
      createdAt: createdAt,
    );
  }
}