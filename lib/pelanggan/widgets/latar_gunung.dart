import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Pemandangan pegunungan: langit hijau, matahari, awan yang bergerak pelan,
/// punggung gunung berlapis, dan pohon cemara. Bisa diberi [child] di atasnya.
class LatarGunung extends StatefulWidget {
  final double tinggi;
  final Widget? child;

  const LatarGunung({super.key, required this.tinggi, this.child});

  @override
  State<LatarGunung> createState() => _LatarGunungState();
}

class _LatarGunungState extends State<LatarGunung>
    with SingleTickerProviderStateMixin {
  late final AnimationController _awan;

  @override
  void initState() {
    super.initState();
    _awan = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 45),
    )..repeat();
  }

  @override
  void dispose() {
    _awan.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.tinggi,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.forestGreenDark, AppColors.forestGreen],
              ),
            ),
          ),
          RepaintBoundary(
            child: CustomPaint(painter: _GunungPainter(_awan)),
          ),
          if (widget.child != null) widget.child!,
        ],
      ),
    );
  }
}

class _GunungPainter extends CustomPainter {
  final Animation<double> animasi;

  _GunungPainter(this.animasi) : super(repaint: animasi);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // matahari + cahayanya
    final pusatMatahari = Offset(w * 0.84, h * 0.26);
    canvas.drawCircle(
      pusatMatahari,
      38,
      Paint()..color = AppColors.gold.withValues(alpha: 0.16),
    );
    canvas.drawCircle(
      pusatMatahari,
      21,
      Paint()..color = AppColors.gold.withValues(alpha: 0.95),
    );

    // awan yang melintas pelan
    final warnaAwan = Paint()..color = Colors.white.withValues(alpha: 0.28);
    final t = animasi.value;
    _awanKecil(canvas, Offset(t * (w + 140) - 70, h * 0.20), warnaAwan);
    _awanKecil(
      canvas,
      Offset(((t + 0.55) % 1.0) * (w + 140) - 70, h * 0.38),
      warnaAwan,
    );

    // gunung jauh
    final jauh = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.62)
      ..lineTo(w * 0.16, h * 0.40)
      ..lineTo(w * 0.30, h * 0.58)
      ..lineTo(w * 0.47, h * 0.28)
      ..lineTo(w * 0.66, h * 0.60)
      ..lineTo(w * 0.80, h * 0.44)
      ..lineTo(w, h * 0.62)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(
      jauh,
      Paint()..color = const Color(0xFF5FA98D).withValues(alpha: 0.45),
    );

    // gunung tengah
    final tengah = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.72)
      ..lineTo(w * 0.22, h * 0.52)
      ..lineTo(w * 0.40, h * 0.68)
      ..lineTo(w * 0.60, h * 0.46)
      ..lineTo(w * 0.80, h * 0.70)
      ..lineTo(w, h * 0.58)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(tengah, Paint()..color = const Color(0xFF2C6E58));

    // pohon cemara
    final warnaPohon = Paint()..color = AppColors.forestGreenDark;
    for (final x in [0.07, 0.13, 0.46, 0.53, 0.91]) {
      _pohon(canvas, Offset(w * x, h * 0.76), 30, warnaPohon);
    }

    // punggung terdepan, warnanya sama dengan latar halaman
    final depan = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.82)
      ..quadraticBezierTo(w * 0.25, h * 0.64, w * 0.50, h * 0.82)
      ..quadraticBezierTo(w * 0.75, h * 0.98, w, h * 0.76)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(depan, Paint()..color = AppColors.lightBackground);
  }

  void _awanKecil(Canvas canvas, Offset pusat, Paint p) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: pusat, width: 58, height: 15),
        const Radius.circular(8),
      ),
      p,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: pusat + const Offset(-7, -9), width: 32, height: 14),
        const Radius.circular(7),
      ),
      p,
    );
  }

  void _pohon(Canvas canvas, Offset dasar, double tinggi, Paint p) {
    final atas = Path()
      ..moveTo(dasar.dx, dasar.dy - tinggi)
      ..lineTo(dasar.dx - tinggi * 0.30, dasar.dy - tinggi * 0.35)
      ..lineTo(dasar.dx + tinggi * 0.30, dasar.dy - tinggi * 0.35)
      ..close();
    final bawah = Path()
      ..moveTo(dasar.dx, dasar.dy - tinggi * 0.72)
      ..lineTo(dasar.dx - tinggi * 0.40, dasar.dy)
      ..lineTo(dasar.dx + tinggi * 0.40, dasar.dy)
      ..close();
    canvas.drawPath(atas, p);
    canvas.drawPath(bawah, p);
  }

  @override
  bool shouldRepaint(covariant _GunungPainter oldDelegate) =>
      oldDelegate.animasi != animasi;
}