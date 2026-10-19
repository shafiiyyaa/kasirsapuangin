import 'package:flutter/material.dart';

import '../../menu_board/models/menu_item.dart';
import '../../theme/app_theme.dart';

/// Jumlah kolom grid menu menyesuaikan lebar area yang tersedia,
/// biar kartu gak melebar aneh pas landscape/laptop.
int kolomMenuUntukLebar(double lebar) {
  if (lebar >= 900) return 4;
  if (lebar >= 560) return 3;
  return 2;
}

/// Tinggi tetap kartu grid (mainAxisExtent) sesuai jumlah kolom —
/// dipilih biar isi kartu gak nabrak dinding kartu.
double tinggiKartuMenu(int kolom) => kolom <= 2 ? 120 : 108;

/// Kartu menu untuk tampilan GRID.
class MenuItemCard extends StatelessWidget {
  final MenuItem item;
  final VoidCallback? onTap;
  final Widget? trailing;

  const MenuItemCard({
    super.key,
    required this.item,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final habis = !item.tersedia;

    return Opacity(
      opacity: habis ? 0.55 : 1,
      child: Card(
        child: InkWell(
          onTap: habis ? null : onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.nama,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.15,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (habis) ...[
                      const SizedBox(width: 6),
                      const _BadgeHabis(),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  item.kategori,
                  style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(), // harga nempel di bawah, tinggi kartu tetap
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatRupiah(item.harga),
                        style: AppTextStyles.price.copyWith(fontSize: 15),
                      ),
                      if (trailing != null) ...[
                        const SizedBox(width: 4),
                        trailing!,
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Baris ramping untuk tampilan LIST — hemat ruang di layar landscape.
class MenuItemListTile extends StatelessWidget {
  final MenuItem item;
  final VoidCallback? onTap;
  final Widget? trailing;

  const MenuItemListTile({
    super.key,
    required this.item,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final habis = !item.tersedia;

    return Opacity(
      opacity: habis ? 0.55 : 1,
      child: Card(
        child: InkWell(
          onTap: habis ? null : onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.nama,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.kategori,
                        style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _formatRupiah(item.harga),
                  style: AppTextStyles.price.copyWith(fontSize: 14),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  trailing!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BadgeHabis extends StatelessWidget {
  const _BadgeHabis();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.statusBatal.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Habis',
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.statusBatal,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Format angka jadi "Rp15.000".
String _formatRupiah(int angka) {
  final str = angka.toString();
  final buffer = StringBuffer();
  for (int i = 0; i < str.length; i++) {
    final posFromRight = str.length - i;
    buffer.write(str[i]);
    if (posFromRight > 1 && posFromRight % 3 == 1) {
      buffer.write('.');
    }
  }
  return 'Rp$buffer';
}