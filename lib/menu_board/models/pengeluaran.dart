/// Model satu catatan pengeluaran (tabel `pengeluaran`).
class Pengeluaran {
  final String id;
  final String keterangan;
  final int jumlah;
  final DateTime tanggal;

  Pengeluaran({
    required this.id,
    required this.keterangan,
    required this.jumlah,
    required this.tanggal,
  });

  factory Pengeluaran.fromMap(Map<String, dynamic> map) {
    return Pengeluaran(
      id: map['id'] as String,
      keterangan: map['keterangan'] as String,
      jumlah: map['jumlah'] as int,
      tanggal: DateTime.parse(map['tanggal'] as String),
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'keterangan': keterangan,
      'jumlah': jumlah,
      'tanggal':
          '${tanggal.year}-${tanggal.month.toString().padLeft(2, '0')}-${tanggal.day.toString().padLeft(2, '0')}',
    };
  }
}