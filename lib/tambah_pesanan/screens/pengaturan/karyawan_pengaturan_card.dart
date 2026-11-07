import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../menu_board/models/profil.dart';
import '../../../menu_board/providers/auth_provider.dart';

/// Password acak 8 karakter (tanpa huruf/angka yang mirip: 0 O 1 l I).
String _passwordAcak([int panjang = 8]) {
  const huruf = 'abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  final r = Random.secure();
  return List.generate(panjang, (_) => huruf[r.nextInt(huruf.length)]).join();
}

/// Manajemen akun karyawan (tambah, lihat, ubah, hapus).
/// Ditanam di halaman Pengaturan, yang hanya bisa dibuka admin.
class KaryawanPengaturanCard extends StatefulWidget {
  const KaryawanPengaturanCard({super.key});

  @override
  State<KaryawanPengaturanCard> createState() =>
      _KaryawanPengaturanCardState();
}

class _KaryawanPengaturanCardState extends State<KaryawanPengaturanCard> {
  List<Profil> _daftar = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .order('nama');
      if (!mounted) return;
      setState(() {
        _daftar = (data as List)
            .map((e) => Profil.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Gagal memuat daftar karyawan: $e';
        _loading = false;
      });
    }
  }

  /// Memanggil Edge Function. Mengembalikan null jika sukses,
  /// atau pesan error jika gagal.
  Future<String?> _panggil(Map<String, dynamic> body) async {
    try {
      await Supabase.instance.client.functions
          .invoke('kelola-karyawan', body: body);
      return null;
    } on FunctionException catch (e) {
      final d = e.details;
      if (d is Map && d['error'] != null) return d['error'].toString();
      return 'Gagal (kode ${e.status}). ${d ?? ''}'.trim();
    } catch (e) {
      return 'Gagal menghubungi server: $e';
    }
  }

  void _info(String pesan) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(pesan)));
  }

  Future<void> _tambah() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _FormKaryawanDialog(
        awal: null,
        idSaya: null,
        onSimpan: _panggil,
      ),
    );
    if (ok == true && mounted) {
      _info('Akun karyawan berhasil dibuat.');
      _muat();
    }
  }

  Future<void> _ubah(Profil p, String? idSaya) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _FormKaryawanDialog(
        awal: p,
        idSaya: idSaya,
        onSimpan: _panggil,
      ),
    );
    if (ok == true && mounted) {
      _info('Data karyawan diperbarui.');
      _muat();
    }
  }

  Future<void> _hapus(Profil p) async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus akun?'),
        content: Text(
          'Akun ${p.nama} (@${p.username}) akan dihapus permanen dan tidak '
          'bisa login lagi. Riwayat pesanan tetap aman.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (yakin != true || !mounted) return;

    final err = await _panggil({'aksi': 'hapus', 'id': p.id});
    if (!mounted) return;
    if (err != null) {
      _info(err);
      return;
    }
    _info('Akun ${p.nama} dihapus.');
    _muat();
  }

  List<Widget> _isiDaftar(ColorScheme scheme, String? idSaya) {
    final hasil = <Widget>[];

    for (var i = 0; i < _daftar.length; i++) {
      final p = _daftar[i];
      final nama = p.nama.trim();

      if (i > 0) hasil.add(const Divider(height: 1));

      hasil.add(
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: scheme.primaryContainer,
            child: Text(
              nama.isEmpty ? '?' : nama[0].toUpperCase(),
              style: TextStyle(
                color: scheme.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          title: Text(
            p.id == idSaya ? '${p.nama} (kamu)' : p.nama,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            '@${p.username} • ${p.isAdmin ? 'Admin' : 'Kasir'}'
            '${p.aktif ? '' : ' • Nonaktif'}',
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Ubah',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _ubah(p, idSaya),
              ),
              IconButton(
                tooltip: 'Hapus',
                icon: Icon(
                  Icons.delete_outline,
                  color: p.id == idSaya ? null : Colors.red,
                ),
                onPressed: p.id == idSaya ? null : () => _hapus(p),
              ),
            ],
          ),
        ),
      );
    }

    return hasil;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final idSaya = context.watch<AuthProvider>().profil?.id;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Hanya admin yang bisa membuat, mengubah, atau menghapus '
                  'akun karyawan.',
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _tambah,
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                label: const Text('Tambah'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_error!, style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: _muat,
                  child: const Text('Coba lagi'),
                ),
              ],
            )
          else if (_daftar.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('Belum ada akun karyawan.'),
            )
          else
            ..._isiDaftar(scheme, idSaya),
        ],
      ),
    );
  }
}

/// Dialog tambah / ubah karyawan.
/// [awal] == null berarti mode tambah. Menutup dengan `true` jika sukses.
class _FormKaryawanDialog extends StatefulWidget {
  final Profil? awal;
  final String? idSaya;
  final Future<String?> Function(Map<String, dynamic> data) onSimpan;

  const _FormKaryawanDialog({
    required this.awal,
    required this.idSaya,
    required this.onSimpan,
  });

  @override
  State<_FormKaryawanDialog> createState() => _FormKaryawanDialogState();
}

class _FormKaryawanDialogState extends State<_FormKaryawanDialog> {
  late final TextEditingController _usernameC;
  late final TextEditingController _namaC;
  late final TextEditingController _passC;
  late bool _aktif;
  String _role = 'kasir';
  bool _sibuk = false;
  bool _lihatPassword = false;
  String? _error;

  bool get _edit => widget.awal != null;

  @override
  void initState() {
    super.initState();
    final a = widget.awal;
    _usernameC = TextEditingController(text: a?.username ?? '');
    _namaC = TextEditingController(text: a?.nama ?? '');
    _passC = TextEditingController();
    _aktif = a?.aktif ?? true;
    _role = a?.role ?? 'kasir';
  }

  @override
  void dispose() {
    _usernameC.dispose();
    _namaC.dispose();
    _passC.dispose();
    super.dispose();
  }

  void _setError(String pesan) => setState(() => _error = pesan);

  Future<void> _simpan() async {
    final username = _usernameC.text.trim().toLowerCase();
    final nama = _namaC.text.trim();
    final pass = _passC.text;

    if (!_edit && username.isEmpty) {
      _setError('Username wajib diisi.');
      return;
    }
    if (nama.isEmpty) {
      _setError('Nama wajib diisi.');
      return;
    }
    if (!_edit && pass.length < 6) {
      _setError('Password minimal 6 karakter.');
      return;
    }
    if (_edit && pass.isNotEmpty && pass.length < 6) {
      _setError('Password baru minimal 6 karakter.');
      return;
    }

    setState(() {
      _sibuk = true;
      _error = null;
    });

    final Map<String, dynamic> data = _edit
        ? {
            'aksi': 'ubah',
            'id': widget.awal!.id,
            'nama': nama,
            'aktif': _aktif,
            if (pass.isNotEmpty) 'password': pass,
          }
        : {
            'aksi': 'buat',
            'username': username,
            'nama': nama,
            'password': pass,
            'role': _role,
          };

    final err = await widget.onSimpan(data);
    if (!mounted) return;

    if (err == null) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _sibuk = false;
        _error = err;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final akunSendiri = _edit && widget.awal!.id == widget.idSaya;

    return AlertDialog(
      title: Text(_edit ? 'Ubah karyawan' : 'Tambah karyawan'),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _usernameC,
                enabled: !_edit,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'Username (untuk login)',
                  helperText:
                      'Huruf kecil, angka, titik, strip. Min. 3 karakter.',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _namaC,
                decoration: const InputDecoration(
                  labelText: 'Nama karyawan',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passC,
                obscureText: !_lihatPassword,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: _edit ? 'Password baru (opsional)' : 'Password',
                  helperText: _edit
                      ? 'Kosongkan jika tidak ingin mengganti password.'
                      : 'Ketik sendiri (minimal 6 karakter).',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    tooltip: _lihatPassword
                        ? 'Sembunyikan password'
                        : 'Lihat password',
                    onPressed: () =>
                        setState(() => _lihatPassword = !_lihatPassword),
                    icon: Icon(
                      _lihatPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                ),
              ),
              Wrap(
                spacing: 4,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _passC.text = _passwordAcak();
                        _lihatPassword = true;
                      });
                    },
                    icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                    label: const Text('Buat acak'),
                  ),
                  TextButton.icon(
                    onPressed: _passC.text.isEmpty
                        ? null
                        : () => Clipboard.setData(
                              ClipboardData(text: _passC.text),
                            ),
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text('Salin'),
                  ),
                ],
              ),
              if (!_edit) ...[
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  initialValue: _role,
                  decoration: const InputDecoration(
                    labelText: 'Peran',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'kasir', child: Text('Kasir')),
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _role = v);
                  },
                ),
              ],
              if (_edit)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Akun aktif'),
                  subtitle: Text(
                    akunSendiri
                        ? 'Akun sendiri tidak bisa dinonaktifkan.'
                        : 'Akun nonaktif tidak bisa login.',
                  ),
                  value: _aktif,
                  onChanged: akunSendiri
                      ? null
                      : (v) => setState(() => _aktif = v),
                ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  style: TextStyle(color: scheme.error, fontSize: 13),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _sibuk ? null : () => Navigator.pop(context, false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _sibuk ? null : _simpan,
          child: _sibuk
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Simpan'),
        ),
      ],
    );
  }
}