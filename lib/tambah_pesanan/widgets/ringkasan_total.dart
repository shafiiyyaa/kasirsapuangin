import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class RingkasanTotal extends StatelessWidget {
  final int subtotal;
  final int diskon;
  final int total;
  final String? labelDiskon;

  const RingkasanTotal({
    super.key,
    required this.subtotal,
    required this.diskon,
    required this.total,
    this.labelDiskon,
  });

  static String _rp(int n) =>
      'Rp${n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (diskon > 0) ...[
          Row(
            children: [
              const Expanded(
                child: Text('Harga asli', style: AppTextStyles.bodyMedium),
              ),
              Text(_rp(subtotal), style: AppTextStyles.bodyMedium),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  (labelDiskon == null || labelDiskon!.isEmpty)
                      ? 'Diskon'
                      : labelDiskon!,
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.warning),
                ),
              ),
              Text(
                '-${_rp(diskon)}',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.warning),
              ),
            ],
          ),
          const Divider(height: 16),
        ],
        Row(
          children: [
            const Expanded(
              child: Text('Total', style: AppTextStyles.titleMedium),
            ),
            Text(_rp(total), style: AppTextStyles.priceLarge),
          ],
        ),
      ],
    );
  }
}