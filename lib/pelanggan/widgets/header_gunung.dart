import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'latar_gunung.dart';

/// Sapaan sesuai jam, mis. "Selamat pagi".
String sapaanWaktu() {
  final jam = DateTime.now().hour;
  if (jam < 11) return 'Selamat pagi';
  if (jam < 15) return 'Selamat siang';
  if (jam < 18) return 'Selamat sore';
  return 'Selamat malam';
}

/// Kepala halaman menu: pemandangan gunung + nama toko + nomor meja.
class HeaderGunung extends StatelessWidget {
  final String namaToko;
  final String? meja;
  final bool memuat;
  final VoidCallback onRefresh;

  const HeaderGunung({
    super.key,
    required this.namaToko,
    required this.meja,
    required this.memuat,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final atas = MediaQuery.of(context).padding.top;
    final malam = DateTime.now().hour >= 18;

    return LatarGunung(
      tinggi: 192 + atas,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, atas + 14, 6, 0),
        child: Align(
          alignment: Alignment.topLeft,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          malam
                              ? Icons.nights_stay_rounded
                              : Icons.wb_sunny_rounded,
                          size: 15,
                          color: AppColors.goldSoft,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          sapaanWaktu(),
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.goldSoft,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        namaToko,
                        maxLines: 1,
                        style: AppTextStyles.displaySmall.copyWith(
                          color: AppColors.textOnGreen,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Hangatnya kopi, sejuknya pegunungan',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textOnGreen,
                      ),
                    ),
                    if (meja != null && meja!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.gold,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Meja $meja',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.forestGreenDark,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Muat ulang menu',
                color: AppColors.textOnGreen,
                onPressed: memuat ? null : onRefresh,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}