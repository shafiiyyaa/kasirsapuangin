import 'package:flutter/material.dart';

import '../../menu_board/models/menu_item.dart';
import '../../theme/app_theme.dart';

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
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.nama,
                        style: AppTextStyles.bodyLarge,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (habis) _BadgeHabis(),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.kategori,
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatRupiah(item.harga),
                      style: AppTextStyles.price,
                    ),
                    if (trailing != null) trailing!,
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BadgeHabis extends StatelessWidget {
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

/// Format angka jadi "Rp15.000" tanpa perlu paket intl tambahan khusus
/// untuk kasus sederhana ini.
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