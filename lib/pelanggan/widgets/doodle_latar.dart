import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Latar belakang bergambar doodle bertema kopi & pegunungan
/// (biji kopi, daun, cangkir beruap, gunung, awan, kilau).
/// Digambar langsung dengan kode, tanpa file gambar.
class DoodleLatar extends StatelessWidget {
  const DoodleLatar({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _DoodlePainter(),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _DoodlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const sel = 112.0;
    final acak = math.Random(11);
    final kolom = (size.width / sel).ceil() + 1;
    final baris = (size.height / sel).ceil() + 1;

    final garisHijau = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = AppColors.forestGreen.withValues(alpha: 0.10);

    final garisEmas = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = AppColors.gold.withValues(alpha: 0.26);

    var urutan = 0;
    for (var r = 0; r < baris; r++) {
      for (var c = 0; c < kolom; c++) {
        final geserX = (acak.nextDouble() - 0.5) * 36;
        final geserY = (acak.nextDouble() - 0.5) * 36;
        final putar = (acak.nextDouble() - 0.5) * 1.1;
        final skala = 0.9 + acak.nextDouble() * 0.4;

        final pusat = Offset(
          c * sel + sel / 2 + (r.isOdd ? sel / 2 : 0) + geserX,
          r * sel + sel / 2 + geserY,
        );

        canvas.save();
        canvas.translate(pusat.dx, pusat.dy);
        canvas.rotate(putar);
        canvas.scale(skala);

        switch (urutan % 6) {
          case 0:
            _biji(canvas, garisHijau);
            break;
          case 1:
            _daun(canvas, garisHijau);
            break;
          case 2:
            _cangkir(canvas, garisEmas);
            break;
          case 3:
            _gunung(canvas, garisHijau);
            break;
          case 4:
            _kilau(canvas, garisEmas);
            break;
          default:
            _awan(canvas, garisHijau);
        }

        canvas.restore();
        urutan++;
      }
    }
  }

  void _biji(Canvas canvas, Paint p) {
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 20, height: 28),
      p,
    );
    final garis = Path()
      ..moveTo(0, -12)
      ..quadraticBezierTo(7, -4, 0, 0)
      ..quadraticBezierTo(-7, 4, 0, 12);
    canvas.drawPath(garis, p);
  }

  void _daun(Canvas canvas, Paint p) {
    final daun = Path()
      ..moveTo(0, -18)
      ..quadraticBezierTo(14, -4, 0, 18)
      ..quadraticBezierTo(-14, -4, 0, -18);
    canvas.drawPath(daun, p);
    canvas.drawLine(const Offset(0, -12), const Offset(0, 22), p);
  }

  void _cangkir(Canvas canvas, Paint p) {
    final badan = Path()
      ..moveTo(-14, -6)
      ..lineTo(-12, 12)
      ..quadraticBezierTo(0, 18, 12, 12)
      ..lineTo(14, -6)
      ..close();
    canvas.drawPath(badan, p);

    canvas.drawArc(
      Rect.fromCenter(center: const Offset(18, 3), width: 14, height: 12),
      -1.57,
      3.14,
      false,
      p,
    );

    final uapKiri = Path()
      ..moveTo(-5, -11)
      ..quadraticBezierTo(-9, -16, -5, -21)
      ..quadraticBezierTo(-1, -26, -5, -30);
    final uapKanan = Path()
      ..moveTo(5, -11)
      ..quadraticBezierTo(1, -16, 5, -21)
      ..quadraticBezierTo(9, -26, 5, -30);
    canvas.drawPath(uapKiri, p);
    canvas.drawPath(uapKanan, p);
  }

  void _gunung(Canvas canvas, Paint p) {
    final gunung = Path()
      ..moveTo(-24, 14)
      ..lineTo(-7, -12)
      ..lineTo(1, 0)
      ..lineTo(9, -8)
      ..lineTo(24, 14)
      ..close();
    canvas.drawPath(gunung, p);

    final salju = Path()
      ..moveTo(-12, -4)
      ..lineTo(-9, -1)
      ..lineTo(-6, -4)
      ..lineTo(-3, -1);
    canvas.drawPath(salju, p);
  }

  void _kilau(Canvas canvas, Paint p) {
    canvas.drawLine(const Offset(0, -9), const Offset(0, 9), p);
    canvas.drawLine(const Offset(-9, 0), const Offset(9, 0), p);
    canvas.drawCircle(const Offset(15, -11), 2, p);
    canvas.drawCircle(const Offset(-14, 12), 1.5, p);
  }

  void _awan(Canvas canvas, Paint p) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: 40, height: 14),
        const Radius.circular(7),
      ),
      p,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(-4, -9), width: 22, height: 12),
        const Radius.circular(6),
      ),
      p,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}