import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/bahasa.dart';
import '../../../menu_board/providers/theme_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../widgets/app_scaffold.dart';
import 'diskon_pengaturan_card.dart';
import 'karyawan_pengaturan_card.dart';

class PengaturanScreen extends StatelessWidget {
  const PengaturanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Rebuild otomatis saat bahasa diganti.
    final bahasa = context.watch<Bahasa>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppScaffold.isWide(context)
          ? null
          : AppBar(
              title: Text(tr('Pengaturan')),
              leading: IconButton(
                icon: const Icon(Icons.menu),
                tooltip: tr('Buka menu'),
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
                      Text(
                        tr('Kasir Sapuangin • versi 1.0.0'),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ===== diskon =====
          _judul(tr('DISKON')),
          _kartu(const DiskonPengaturanCard()),
          const SizedBox(height: 24),

          // ===== akun karyawan =====
          _judul(tr('AKUN KARYAWAN')),
          _kartu(const KaryawanPengaturanCard()),
          const SizedBox(height: 24),

          // ===== bahasa =====
          _judul(tr('BAHASA')),
          _kartu(
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('Bahasa aplikasi'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tr('Pilih bahasa tampilan aplikasi dan struk.'),
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _LanguageToggle(
                    kode: bahasa.kode,
                    onChanged: (kode) =>
                        context.read<Bahasa>().atur(kode),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ===== tampilan =====
          _judul(tr('TAMPILAN')),
          _kartu(
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, _) {
                final gelap = themeProvider.themeMode == ThemeMode.dark;
                return SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  secondary: _ikon(gelap ? Icons.dark_mode : Icons.light_mode),
                  title: Text(
                    tr('Mode Gelap / Terang'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Text(
                    gelap ? tr('Mode gelap aktif') : tr('Mode terang aktif'),
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

          // ===== tentang =====
          _judul(tr('TENTANG')),
          _kartu(
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('Kasir Sapuangin'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tr(
                      'Aplikasi Kasir Sapuangin dibuat untuk membantu pekerjaan '
                      'kasir Sapuangin Coffee & Farm: mencatat pesanan, '
                      'mengelola menu, serta mencatat keuangan agar transparan '
                      'dan mudah diperiksa.',
                    ),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              tr('Dirancang khusus untuk Sapuangin Coffee & Farm'),
              style: const TextStyle(fontSize: 11, color: Colors.black38),
            ),
          ),
        ],
      ),
    );
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

/// Toggle bahasa berbentuk pill: dua sisi (Indonesia / English) dengan
/// jempol (thumb) yang meluncur ke sisi yang aktif. Lebih ringkas dan
/// rapi daripada SegmentedButton dua kolom lebar.
class _LanguageToggle extends StatelessWidget {
  final String kode; // 'id' atau 'en'
  final ValueChanged<String> onChanged;

  const _LanguageToggle({required this.kode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const sisi = ['id', 'en'];
    final indexAktif = kode == 'en' ? 1 : 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final lebar = constraints.maxWidth;
        const tinggi = 46.0;
        final lebarSisi = lebar / sisi.length;

        return Container(
          height: tinggi,
          width: lebar,
          decoration: BoxDecoration(
            color: AppColors.forestGreen.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(tinggi / 2),
            border: Border.all(
              color: AppColors.forestGreen.withValues(alpha: 0.30),
            ),
          ),
          child: Stack(
            children: [
              // Thumb yang meluncur ke sisi aktif.
              AnimatedAlign(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                alignment: Alignment(indexAktif == 0 ? -1.0 : 1.0, 0),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Container(
                    width: lebarSisi - 8,
                    decoration: BoxDecoration(
                      color: AppColors.forestGreen,
                      borderRadius: BorderRadius.circular((tinggi - 8) / 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.forestGreen
                              .withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Dua sisi yang bisa diketuk.
              Row(
                children: [
                  for (var i = 0; i < sisi.length; i++)
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(tinggi / 2),
                          onTap: () => onChanged(sisi[i]),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  sisi[i] == 'id' ? 'ID' : 'EN',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6,
                                    color: i == indexAktif
                                        ? Colors.white
                                        : AppColors.forestGreenDark,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  sisi[i] == 'id' ? 'Indonesia' : 'English',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: i == indexAktif
                                        ? Colors.white
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
