/// Profil karyawan (data tabel `profiles`).
class Profil {
  final String id;
  final String username;
  final String nama;
  final String role; // 'admin' atau 'kasir'
  final bool aktif;

  const Profil({
    required this.id,
    required this.username,
    required this.nama,
    required this.role,
    required this.aktif,
  });

  bool get isAdmin => role == 'admin';

  factory Profil.fromMap(Map<String, dynamic> map) {
    return Profil(
      id: map['id'] as String,
      username: (map['username'] as String?) ?? '',
      nama: (map['nama'] as String?) ?? '',
      role: (map['role'] as String?) ?? 'kasir',
      aktif: map['aktif'] as bool? ?? true,
    );
  }
}