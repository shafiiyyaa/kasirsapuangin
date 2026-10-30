import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../config_pelanggan.dart';
import 'latar_gunung.dart';

// Dipakai agar sambutan hanya muncul SEKALI setiap halaman dibuka.
bool _sudahDisambut = false;

/// Pop-up sambutan saat QR baru di-scan.
Future<void> tampilkanSelamatDatang(
  BuildContext context, {
  required String meja,
}) async {
  if (_sudahDisambut) return;
  _sudahDisambut = true;

  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Tutup sambutan',
    barrierColor: Colors.black.withValues(alpha: 0.55),
    transitionDuration: const Duration(milliseconds: 500),
    pageBuilder: (ctx, _, __) => _KartuSambutan(meja: meja),
    transitionBuilder: (ctx, animasi, _, child) {
      final membal = CurvedAnimation(
        parent: animasi,
        curve: Curves.easeOutBack,
      );
      final halus = CurvedAnimation(
        parent: animasi,
        curve: Curves.easeOut,
      );
      return FadeTransition(
        opacity: halus,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.85, end: 1.0).animate(membal),
          child: child,
        ),
      );
    },
  );
}

class _KartuSambutan extends StatelessWidget {
  final String meja;

  const _KartuSambutan({required this.meja});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.lightBackground,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 30,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const LatarGunung(
                      tinggi: 176,
                      child: Align(
                        alignment: Alignment(0, -0.35),
                        child: _CangkirUap(),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 6, 24, 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Selamat datang di',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.lightTextSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            kNamaToko,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.displaySmall.copyWith(
                              color: AppColors.forestGreenDark,
                            ),
                          ),
                          if (meja.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.gold,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Meja $meja',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.forestGreenDark,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),
                          const Text(
                            'Selamat menikmati layanan kami. Pilih menu '
                            'favoritmu, dan pesananmu langsung kami siapkan.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13.5,
                              height: 1.45,
                              color: AppColors.lightTextSecondary,
                            ),
                          ),
                          const SizedBox(height: 20),
                          FilledButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(50),
                            ),
                            child: const Text('Mulai Pesan'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Cangkir kopi dengan uap yang naik terus-menerus.
class _CangkirUap extends StatefulWidget {
  const _CangkirUap();

  @override
  State<_CangkirUap> createState() => _CangkirUapState();
}

class _CangkirUapState extends State<_CangkirUap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _uap;

  @override
  void initState() {
    super.initState();
    _uap = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
  }

  @override
  void dispose() {
    _uap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      height: 110,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _UapPainter(_uap)),
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Icon(
              Icons.coffee_rounded,
              size: 62,
              color: AppColors.textOnGreen,
            ),
          ),
        ],
      ),
    );
  }
}

class _UapPainter extends CustomPainter {
  final Animation<double> animasi;

  _UapPainter(this.animasi) : super(repaint: animasi);

  @override
  void paint(Canvas canvas, Size size) {
    final tengah = size.width / 2;
    final dasar = size.height - 56;

    for (var i = 0; i < 3; i++) {
      final fase = (animasi.value + i / 3) % 1.0;
      final x = tengah + (i - 1) * 14 + math.sin(fase * math.pi * 2 + i) * 6;
      final y = dasar - fase * 52;
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: (1 - fase) * 0.65);
      canvas.drawCircle(Offset(x, y), 3 + fase * 6, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _UapPainter oldDelegate) =>
      oldDelegate.animasi != animasi;
}