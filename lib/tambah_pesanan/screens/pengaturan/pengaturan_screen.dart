import 'package:flutter/material.dart';
import '../../widgets/app_scaffold.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../menu_board/providers/theme_provider.dart';

// PENTING: samain 2 import di bawah ini dengan path theme yang dipake
// file lain di project kamu (tinggal copy dari dashboard_screen.dart).
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

import 'kelola_menu_screen.dart';

class PengaturanScreen extends StatelessWidget {
  const PengaturanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppScaffold.isWide(context) ? null : AppBar(
        title: const Text('Pengaturan'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          tooltip: 'Buka menu',
          onPressed: () => AppScaffold.openMenu(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          // ===== kartu toko =====
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.forestGreen,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.store, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sapuangin Coffee & Farm',
                        style: AppTextStyles.displayMedium
                            .copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Kasir Sapuangin • versi 1.0.0',
                        style: TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ===== menu =====
          _judul('MENU'),
          _kartu(
            ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              leading: _ikon(Icons.restaurant_menu),
              title: const Text('Kelola Menu',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              subtitle: const Text(
                'Tambah, edit nama & harga, hapus, atau tandai habis',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              trailing:
                  const Icon(Icons.chevron_right, color: AppColors.forestGreen),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const KelolaMenuScreen()),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // ===== tampilan =====
          _judul('TAMPILAN'),
          _kartu(
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, _) {
                final gelap = themeProvider.themeMode == ThemeMode.dark;
                return SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 6),
                  secondary: _ikon(gelap ? Icons.dark_mode : Icons.light_mode),
                  title: const Text('Mode Gelap / Terang',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  subtitle: Text(
                    gelap ? 'Mode gelap aktif' : 'Mode terang aktif',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  value: gelap,
                  activeThumbColor: AppColors.forestGreen,
                  onChanged: (_) => themeProvider.toggleTheme(),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // ===== akun =====
          _judul('AKUN'),
          _kartu(
            ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              leading: _ikon(Icons.logout),
              title: const Text('Keluar',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              subtitle: Text(
                Supabase.instance.client.auth.currentUser?.email ??
                    'Belum masuk',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              onTap: () => _konfirmasiKeluar(context),
            ),
          ),
          const SizedBox(height: 24),

          // ===== tentang =====
          _judul('TENTANG'),
          _kartu(
            const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Kasir Sapuangin',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  SizedBox(height: 4),
                  Text(
                    'Aplikasi Kasir Sapuangin dibuat untuk membantu pekerjaan kasir Sapuangin Coffee & Farm: mencatat pesanan, mengelola menu, serta mencatat keuangan agar transparan dan mudah diperiksa.',
                    style: TextStyle(
                        fontSize: 12, color: Colors.black54, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Center(
            child: Text(
              'Dirancang khusus untuk Sapuangin Coffee & Farm',
              style: TextStyle(fontSize: 11, color: Colors.black38),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _konfirmasiKeluar(BuildContext context) async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar dari akun?'),
        content: const Text(
            'Kamu perlu masuk lagi untuk melihat pesanan dan mengelola menu.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (yakin == true) {
      await Supabase.instance.client.auth.signOut();
    }
  }

  Widget _judul(String teks) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          teks,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: AppColors.forestGreenDark,
          ),
        ),
      );

  Widget _kartu(Widget anak) => Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        child: anak,
      );

  Widget _ikon(IconData data) => CircleAvatar(
        radius: 22,
        backgroundColor: AppColors.forestGreen.withValues(alpha: 0.12),
        child: Icon(data, color: AppColors.forestGreen, size: 22),
      );
}