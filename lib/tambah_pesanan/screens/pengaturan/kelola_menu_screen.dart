import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// PENTING: samain 3 import di bawah ini dengan path yang dipake file lain
// (tinggal copy dari dashboard_screen.dart).
import '../../../theme/app_theme.dart' hide AppTextStyles;
import '../../../theme/app_text_styles.dart';
import '../../../menu_board/providers/menu_provider.dart';
import '../../widgets/app_scaffold.dart';

class KelolaMenuScreen extends StatefulWidget {
  const KelolaMenuScreen({super.key});

  @override
  State<KelolaMenuScreen> createState() => _KelolaMenuScreenState();
}

class _KelolaMenuScreenState extends State<KelolaMenuScreen> {
  final _cari = TextEditingController();
  List<Map<String, dynamic>> _menu = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  @override
  void dispose() {
    _cari.dispose();
    super.dispose();
  }

  // ---------- helper data ----------
  String _nama(Map<String, dynamic> m) => (m['nama'] ?? '').toString();
  String _kategori(Map<String, dynamic> m) => (m['kategori'] ?? '').toString();
  String _tipe(Map<String, dynamic> m) => (m['tipe'] ?? '').toString();
  int _harga(Map<String, dynamic> m) =>
      m['harga'] is num ? (m['harga'] as num).toInt() : 0;
  bool _tersedia(Map<String, dynamic> m) => m['tersedia'] == true;
  String _rupiah(int n) => 'Rp ${_FormatterRupiah.beriTitik(n.toString())}';

  List<String> get _kategoriUnik =>
      _menu.map(_kategori).where((s) => s.isNotEmpty).toSet().toList()..sort();

  List<String> get _tipeUnik =>
      _menu.map(_tipe).where((s) => s.isNotEmpty).toSet().toList()..sort();

  List<Map<String, dynamic>> get _hasil {
    final q = _cari.text.trim().toLowerCase();
    if (q.isEmpty) return _menu;
    return _menu
        .where((m) =>
            _nama(m).toLowerCase().contains(q) ||
            _kategori(m).toLowerCase().contains(q))
        .toList();
  }

  // ---------- muat & sinkron ----------
  Future<void> _muat() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await Supabase.instance.client
          .from('menu_items')
          .select()
          .order('kategori', ascending: true)
          .order('nama', ascending: true);
      if (!mounted) return;
      setState(() {
        _menu = List<Map<String, dynamic>>.from(data as List);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // biar menu board & halaman kasir ikut ke-refresh
  Future<void> _sinkronProvider() async {
    if (!mounted) return;
    try {
      await context.read<MenuProvider>().loadMenu();
    } catch (_) {
      // abaikan — yang penting data di Supabase udah keubah
    }
  }

  // ---------- aksi ----------
  Future<void> _bukaForm([Map<String, dynamic>? menu]) async {
    final berubah = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FormMenu(
        menu: menu,
        kategoriList: _kategoriUnik,
        tipeList: _tipeUnik,
      ),
    );
    if (!mounted) return;
    if (berubah == true) {
      await _muat();
      await _sinkronProvider();
    }
  }

  Future<void> _toggleTersedia(Map<String, dynamic> m, bool val) async {
    setState(() => m['tersedia'] = val);
    try {
      await Supabase.instance.client
          .from('menu_items')
          .update({'tersedia': val}).eq('id', m['id']);
      await _sinkronProvider();
    } catch (e) {
      if (!mounted) return;
      setState(() => m['tersedia'] = !val);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal ubah status: $e'),
          backgroundColor: AppColors.statusBatal,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _hapusMenu(Map<String, dynamic> m) async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus menu ini?'),
        content: Text(
          '"${_nama(m)}" bakal dihapus permanen dari daftar menu. Lanjut?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus',
                style: TextStyle(color: AppColors.statusBatal)),
          ),
        ],
      ),
    );
    if (yakin != true) return;
    try {
      await Supabase.instance.client
          .from('menu_items')
          .delete()
          .eq('id', m['id']);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Menu "${_nama(m)}" udah dihapus'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _muat();
      await _sinkronProvider();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal hapus: $e'),
          backgroundColor: AppColors.statusBatal,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ---------- tampilan ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.forestGreen,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        leading: AppScaffold.isWide(context)
            ? null
            : IconButton(
                icon: const Icon(Icons.menu),
                tooltip: 'Buka menu',
                onPressed: () => AppScaffold.openMenu(context),
              ),
        title: const Text('Kelola Menu'),
        actions: [
          IconButton(
            onPressed: _muat,
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat ulang',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _bukaForm(),
        backgroundColor: AppColors.forestGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _cari,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Cari nama menu...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: EdgeInsets.zero,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.forestGreen),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 13, color: Colors.black38),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Ketuk buat edit • geser switch buat tandai habis • tahan buat hapus',
                    style: TextStyle(fontSize: 11, color: Colors.black38),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _isi()),
        ],
      ),
    );
  }

  Widget _isi() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.forestGreen),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off,
                  size: 44, color: AppColors.statusBatal),
              const SizedBox(height: 12),
              const Text('Gagal memuat menu',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 4),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.black45),
              ),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _muat, child: const Text('Coba Lagi')),
            ],
          ),
        ),
      );
    }
    if (_menu.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.restaurant, size: 56, color: Colors.black26),
            SizedBox(height: 12),
            Text('Belum ada menu',
                style: TextStyle(fontSize: 15, color: Colors.black45)),
            SizedBox(height: 4),
            Text('Ketuk tombol Tambah buat bikin menu pertama',
                style: TextStyle(fontSize: 12, color: Colors.black38)),
          ],
        ),
      );
    }

    final daftar = _hasil;
    if (daftar.isEmpty) {
      return Center(
        child: Text('Ga ada menu yang cocok sama "${_cari.text}"',
            style: const TextStyle(fontSize: 13, color: Colors.black45)),
      );
    }

    final anak = <Widget>[];
    String? kategoriLalu;
    for (final m in daftar) {
      final k = _kategori(m);
      final tampil = k.isEmpty ? 'Lainnya' : k;
      if (tampil != kategoriLalu) {
        kategoriLalu = tampil;
        anak.add(Padding(
          padding: const EdgeInsets.fromLTRB(4, 18, 4, 6),
          child: Text(
            tampil.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: AppColors.forestGreenDark,
            ),
          ),
        ));
      }
      anak.add(_tile(m));
    }

    return RefreshIndicator(
      color: AppColors.forestGreen,
      onRefresh: _muat,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
        children: anak,
      ),
    );
  }

  /// Foto kecil di daftar menu; kalau belum ada foto, tampil huruf awal.
  Widget _fotoKecil(Map<String, dynamic> m, bool habis) {
    final huruf = CircleAvatar(
      radius: 23,
      backgroundColor: habis
          ? Colors.black12
          : AppColors.forestGreen.withValues(alpha: 0.12),
      child: Text(
        _nama(m).isNotEmpty ? _nama(m)[0].toUpperCase() : '?',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: habis ? Colors.black38 : AppColors.forestGreen,
        ),
      ),
    );

    final url = (m['gambar_url'] ?? '').toString().trim();
    if (url.isEmpty) return huruf;

    return Opacity(
      opacity: habis ? 0.5 : 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 46,
          height: 46,
          child: Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Center(child: huruf),
          ),
        ),
      ),
    );
  }

  Widget _tile(Map<String, dynamic> m) {
    final habis = !_tersedia(m);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        onTap: () => _bukaForm(m),
        onLongPress: () => _hapusMenu(m),
        contentPadding: const EdgeInsets.fromLTRB(10, 2, 4, 2),
        leading: _fotoKecil(m, habis),
        title: Text(
          _nama(m),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          habis
              ? 'Habis — ga ditampilin di kasir'
              : (_tipe(m).isEmpty ? _kategori(m) : _tipe(m)),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            color: habis ? AppColors.statusBatal : Colors.black45,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_rupiah(_harga(m)), style: AppTextStyles.price),
            const SizedBox(width: 4),
            Switch(
              value: _tersedia(m),
              onChanged: (v) => _toggleTersedia(m, v),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= FORM TAMBAH / EDIT =================

class _FormMenu extends StatefulWidget {
  const _FormMenu({
    required this.kategoriList,
    required this.tipeList,
    this.menu,
  });

  final Map<String, dynamic>? menu;
  final List<String> kategoriList;
  final List<String> tipeList;

  @override
  State<_FormMenu> createState() => _FormMenuState();
}

class _FormMenuState extends State<_FormMenu> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nama;
  late final TextEditingController _harga;
  late final TextEditingController _catatan;
  late final TextEditingController _kategoriBaru;
  late final TextEditingController _tipeBaru;

  String? _kategori;
  String? _tipe;
  bool _kategoriModeBaru = false;
  bool _tipeModeBaru = false;
  bool _tersedia = true;
  bool _menyimpan = false;

  // ---- foto menu ----
  final ImagePicker _picker = ImagePicker();
  String? _gambarUrl; // foto yang sudah tersimpan
  Uint8List? _fotoBaru; // foto baru yang dipilih (belum diunggah)
  bool _hapusFoto = false;

  bool get _edit => widget.menu != null;

  @override
  void initState() {
    super.initState();
    final m = widget.menu;
    _nama = TextEditingController(
        text: m == null ? '' : (m['nama'] ?? '').toString());
    final hargaAwal =
        m == null ? 0 : (m['harga'] is num ? (m['harga'] as num).toInt() : 0);
    _harga = TextEditingController(
      text: hargaAwal <= 0
          ? ''
          : _FormatterRupiah.beriTitik(hargaAwal.toString()),
    );
    _catatan = TextEditingController(
        text: m == null ? '' : (m['catatan'] ?? '').toString());
    _kategoriBaru = TextEditingController();
    _tipeBaru = TextEditingController();

    if (m != null) {
      _tersedia = m['tersedia'] == true;
      final fotoLama = (m['gambar_url'] ?? '').toString().trim();
      if (fotoLama.isNotEmpty) _gambarUrl = fotoLama;
      final k = (m['kategori'] ?? '').toString();
      if (k.isNotEmpty) {
        if (widget.kategoriList.contains(k)) {
          _kategori = k;
        } else {
          _kategoriModeBaru = true;
          _kategoriBaru.text = k;
        }
      }
      final t = (m['tipe'] ?? '').toString();
      if (t.isNotEmpty) {
        if (widget.tipeList.contains(t)) {
          _tipe = t;
        } else {
          _tipeModeBaru = true;
          _tipeBaru.text = t;
        }
      }
    } else {
      if (widget.tipeList.isNotEmpty) _tipe = widget.tipeList.first;
    }
  }

  @override
  void dispose() {
    _nama.dispose();
    _harga.dispose();
    _catatan.dispose();
    _kategoriBaru.dispose();
    _tipeBaru.dispose();
    super.dispose();
  }

  InputDecoration _dekor(String label, {String? hint, Widget? suffix}) {
    OutlineInputBorder tepi(Color c) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c),
        );
    return InputDecoration(
      labelText: label,
      hintText: hint,
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: tepi(AppColors.border),
      focusedBorder: tepi(AppColors.forestGreen),
      border: tepi(AppColors.border),
    );
  }

  Future<void> _pilihFoto(ImageSource sumber) async {
    try {
      final file = await _picker.pickImage(
        source: sumber,
        maxWidth: 900,
        maxHeight: 900,
        imageQuality: 80,
      );
      if (file == null) return;

      final bytes = await file.readAsBytes();
      if (!mounted) return;

      if (bytes.length > 3 * 1024 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto terlalu besar (maksimal 3 MB)'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      setState(() {
        _fotoBaru = bytes;
        _hapusFoto = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memilih foto: $e'),
          backgroundColor: AppColors.statusBatal,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Mengunggah foto baru ke Supabase Storage, mengembalikan alamat (URL)-nya.
  Future<String> _unggahFoto() async {
    final storage = Supabase.instance.client.storage.from('menu-images');
    final path = 'menu/${DateTime.now().millisecondsSinceEpoch}.jpg';

    await storage.uploadBinary(
      path,
      _fotoBaru!,
      fileOptions: const FileOptions(contentType: 'image/jpeg'),
    );

    return storage.getPublicUrl(path);
  }

  Widget _bagianFoto() {
    final adaFotoLama = !_hapusFoto && (_gambarUrl ?? '').isNotEmpty;
    final punyaFoto = _fotoBaru != null || adaFotoLama;
    final bisaKamera = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);

    final Widget pratinjau;
    if (_fotoBaru != null) {
      pratinjau = Image.memory(_fotoBaru!, fit: BoxFit.cover);
    } else if (adaFotoLama) {
      pratinjau = Image.network(
        _gambarUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.broken_image_outlined,
          color: Colors.black38,
        ),
      );
    } else {
      pratinjau = const Icon(
        Icons.add_photo_alternate_outlined,
        size: 34,
        color: AppColors.forestGreen,
      );
    }

    return Row(
      children: [
        InkWell(
          onTap: _menyimpan ? null : () => _pilihFoto(ImageSource.gallery),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 96,
            height: 96,
            clipBehavior: Clip.antiAlias,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.forestGreen.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: pratinjau,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Foto menu',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              const Text(
                'Opsional. Foto dikecilkan otomatis.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  OutlinedButton.icon(
                    onPressed: _menyimpan
                        ? null
                        : () => _pilihFoto(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined, size: 18),
                    label: const Text('Galeri'),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  if (bisaKamera)
                    OutlinedButton.icon(
                      onPressed: _menyimpan
                          ? null
                          : () => _pilihFoto(ImageSource.camera),
                      icon: const Icon(Icons.photo_camera_outlined, size: 18),
                      label: const Text('Kamera'),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  if (punyaFoto)
                    TextButton.icon(
                      onPressed: _menyimpan
                          ? null
                          : () => setState(() {
                                _fotoBaru = null;
                                _hapusFoto = true;
                              }),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Hapus'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.statusBatal,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    final kategori =
        _kategoriModeBaru ? _kategoriBaru.text.trim() : (_kategori ?? '');
    if (kategori.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kategori belum dipilih'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final tipe = _tipeModeBaru ? _tipeBaru.text.trim() : (_tipe ?? '');
    final harga = int.parse(_harga.text.replaceAll('.', ''));

    setState(() => _menyimpan = true);
    try {
      final client = Supabase.instance.client;
      final payload = <String, dynamic>{
        'nama': _nama.text.trim(),
        'kategori': kategori,
        'harga': harga,
        'tersedia': _tersedia,
        'catatan': _catatan.text.trim().isEmpty ? null : _catatan.text.trim(),
      };
      if (tipe.isNotEmpty) payload['tipe'] = tipe;

      // Foto: unggah kalau ada foto baru, atau kosongkan kalau dihapus.
      if (_fotoBaru != null) {
        payload['gambar_url'] = await _unggahFoto();
      } else if (_hapusFoto) {
        payload['gambar_url'] = null;
      }

      if (_edit) {
        await client
            .from('menu_items')
            .update(payload)
            .eq('id', widget.menu!['id']);
      } else {
        await client.from('menu_items').insert(payload);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _menyimpan = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal nyimpen menu: $e'),
          backgroundColor: AppColors.statusBatal,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _hapusDariForm() async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus menu ini?'),
        content: Text(
          '"${_nama.text.trim()}" bakal dihapus permanen dari daftar menu. Lanjut?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus',
                style: TextStyle(color: AppColors.statusBatal)),
          ),
        ],
      ),
    );
    if (yakin != true) return;
    setState(() => _menyimpan = true);
    try {
      await Supabase.instance.client
          .from('menu_items')
          .delete()
          .eq('id', widget.menu!['id']);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _menyimpan = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal hapus: $e'),
          backgroundColor: AppColors.statusBatal,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  _edit ? 'Edit Menu' : 'Tambah Menu Baru',
                  style: AppTextStyles.displayMedium,
                ),
                const SizedBox(height: 16),
                _bagianFoto(),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nama,
                  textCapitalization: TextCapitalization.words,
                  decoration:
                      _dekor('Nama menu', hint: 'contoh: Kopi Susu Sapuangin'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Nama menu belum diisi'
                      : null,
                ),
                const SizedBox(height: 12),
                _fieldKategori(),
                const SizedBox(height: 12),
                _fieldTipe(),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _harga,
                  keyboardType: TextInputType.number,
                  inputFormatters: [_FormatterRupiah()],
                  decoration: _dekor('Harga', hint: '25000')
                      .copyWith(prefixText: 'Rp '),
                  validator: (v) {
                    final digit = (v ?? '').replaceAll('.', '');
                    if (digit.isEmpty) return 'Harga belum diisi';
                    if (int.parse(digit) <= 0) {
                      return 'Harga harus lebih dari 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 4),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _tersedia,
                  onChanged: (v) => setState(() => _tersedia = v),
                  title: const Text('Tersedia',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: const Text(
                    'Matikan kalau menu ini lagi habis',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _catatan,
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: _dekor('Catatan (opsional)',
                      hint: 'contoh: bisa less sugar, extra shot'),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _menyimpan ? null : _simpan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.forestGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _menyimpan
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : Text(_edit ? 'Simpan Perubahan' : 'Tambah Menu',
                            style: AppTextStyles.button),
                  ),
                ),
                if (_edit) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: _menyimpan ? null : _hapusDariForm,
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Hapus Menu Ini'),
                      style: TextButton.styleFrom(
                          foregroundColor: AppColors.statusBatal),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _fieldKategori() {
    if (_kategoriModeBaru) {
      return TextFormField(
        controller: _kategoriBaru,
        textCapitalization: TextCapitalization.words,
        decoration: _dekor(
          'Kategori baru',
          hint: 'contoh: Kopi, Non-Kopi, Snack',
          suffix: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => setState(() => _kategoriModeBaru = false),
          ),
        ),
        validator: (v) =>
            (v == null || v.trim().isEmpty) ? 'Kategori belum diisi' : null,
      );
    }
    return DropdownButtonFormField<String>(
      initialValue: _kategori,
      isExpanded: true,
      decoration: _dekor('Kategori', hint: 'pilih atau bikin baru'),
      items: [
        for (final k in widget.kategoriList)
          DropdownMenuItem(
              value: k, child: Text(k, overflow: TextOverflow.ellipsis)),
        const DropdownMenuItem(
          value: '__baru__',
          child: Text('+ Bikin kategori baru...',
              style: TextStyle(fontStyle: FontStyle.italic)),
        ),
      ],
      onChanged: (v) {
        if (v == '__baru__') {
          setState(() => _kategoriModeBaru = true);
        } else {
          setState(() => _kategori = v);
        }
      },
      validator: (v) => v == null ? 'Kategori belum dipilih' : null,
    );
  }

  Widget _fieldTipe() {
    if (_tipeModeBaru) {
      return TextFormField(
        controller: _tipeBaru,
        textCapitalization: TextCapitalization.words,
        decoration: _dekor(
          'Tipe menu',
          hint: 'contoh: minuman, makanan',
          suffix: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => setState(() => _tipeModeBaru = false),
          ),
        ),
      );
    }
    return DropdownButtonFormField<String>(
      initialValue: _tipe,
      isExpanded: true,
      decoration: _dekor('Tipe menu', hint: 'contoh: minuman, makanan'),
      items: [
        for (final t in widget.tipeList)
          DropdownMenuItem(
              value: t, child: Text(t, overflow: TextOverflow.ellipsis)),
        const DropdownMenuItem(
          value: '__baru__',
          child: Text('+ Tulis tipe sendiri...',
              style: TextStyle(fontStyle: FontStyle.italic)),
        ),
      ],
      onChanged: (v) {
        if (v == '__baru__') {
          setState(() => _tipeModeBaru = true);
        } else {
          setState(() => _tipe = v);
        }
      },
    );
  }
}

// ================= FORMAT RUPIAH DI INPUT =================

class _FormatterRupiah extends TextInputFormatter {
  static String beriTitik(String digit) {
    final buffer = StringBuffer();
    for (int i = 0; i < digit.length; i++) {
      buffer.write(digit[i]);
      final sisa = digit.length - i - 1;
      if (sisa > 0 && sisa % 3 == 0) buffer.write('.');
    }
    return buffer.toString();
  }

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digit = newValue.text.replaceAll(RegExp('[^0-9]'), '');
    if (digit.isEmpty) return const TextEditingValue(text: '');
    final hasil = beriTitik(digit);
    return TextEditingValue(
      text: hasil,
      selection: TextSelection.collapsed(offset: hasil.length),
    );
  }
}