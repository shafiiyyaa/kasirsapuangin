import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../menu_board/providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userC = TextEditingController();
  final _passC = TextEditingController();
  bool _lihatPassword = false;

  @override
  void dispose() {
    _userC.dispose();
    _passC.dispose();
    super.dispose();
  }

  Future<void> _masuk() async {
    FocusScope.of(context).unfocus();
    await context.read<AuthProvider>().masuk(_userC.text, _passC.text);
    // Pindah halaman ditangani otomatis oleh router setelah login berhasil.
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Doodle alam sebagai latar
          Positioned.fill(
            child: CustomPaint(
              painter: _LoginDoodlePainter(dark: dark),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: scheme.outlineVariant),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // LOGO (otomatis pakai ikon bila file logo belum ada)
                        Center(
                          child: Image.asset(
                            'assets/images/logo.png',
                            height: 88,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: scheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Icon(
                                  Icons.landscape_rounded,
                                  size: 38,
                                  color: scheme.primary,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Kasir Sapuangin',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Sapuangin Coffee & Farm',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _userC,
                          textInputAction: TextInputAction.next,
                          autocorrect: false,
                          enableSuggestions: false,
                          decoration: const InputDecoration(
                            labelText: 'Username',
                            prefixIcon: Icon(Icons.person_outline_rounded),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _passC,
                          obscureText: !_lihatPassword,
                          onSubmitted: (_) => _masuk(),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              tooltip: _lihatPassword
                                  ? 'Sembunyikan password'
                                  : 'Lihat password',
                              onPressed: () => setState(
                                () => _lihatPassword = !_lihatPassword,
                              ),
                              icon: Icon(
                                _lihatPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                            ),
                          ),
                        ),
                        if (auth.error != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            auth.error!,
                            style: TextStyle(
                              color: scheme.error,
                              fontSize: 13,
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 48,
                          child: FilledButton(
                            onPressed: auth.sedangMasuk ? null : _masuk,
                            child: auth.sedangMasuk
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Masuk'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Akun dibuat oleh admin. Lupa password? Hubungi admin.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Doodle alam untuk latar halaman login:
/// pegunungan di bawah, ranting berdaun di sudut atas, dan biji kopi.
class _LoginDoodlePainter extends CustomPainter {
  final bool dark;

  const _LoginDoodlePainter({required this.dark});

  @override
  void paint(Canvas canvas, Size size) {
    final warna =
        dark ? const Color(0xFF7FAE94) : const Color(0xFF8FA68B);

    final garis = Paint()
      ..color = warna.withValues(alpha: dark ? 0.32 : 0.38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final isi = Paint()
      ..color = warna.withValues(alpha: dark ? 0.12 : 0.16)
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;
    final tinggi = math.max(120.0, math.min(300.0, h * 0.34));
    final dasar = h;

    // ---------- Pegunungan ----------
    final gunung = Path()
      ..moveTo(0, dasar)
      ..lineTo(0, dasar - tinggi * 0.45)
      ..lineTo(w * 0.18, dasar - tinggi * 0.85)
      ..lineTo(w * 0.30, dasar - tinggi * 0.60)
      ..lineTo(w * 0.46, dasar - tinggi)
      ..lineTo(w * 0.66, dasar - tinggi * 0.55)
      ..lineTo(w * 0.80, dasar - tinggi * 0.75)
      ..lineTo(w, dasar - tinggi * 0.40)
      ..lineTo(w, dasar)
      ..close();

    canvas.drawPath(gunung, isi);
    canvas.drawPath(gunung, garis);

    // Bukit di depan
    final bukit = Path()
      ..moveTo(0, dasar - tinggi * 0.20)
      ..quadraticBezierTo(
        w * 0.25,
        dasar - tinggi * 0.45,
        w * 0.55,
        dasar - tinggi * 0.18,
      )
      ..quadraticBezierTo(
        w * 0.80,
        dasar - tinggi * 0.02,
        w,
        dasar - tinggi * 0.22,
      );

    canvas.drawPath(bukit, garis);

    // ---------- Daun ----------
    void daun(Offset pangkal, double panjang, double sudut) {
      final lebar = panjang * 0.36;

      canvas.save();
      canvas.translate(pangkal.dx, pangkal.dy);
      canvas.rotate(sudut);

      final bentuk = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(panjang * 0.5, -lebar, panjang, 0)
        ..quadraticBezierTo(panjang * 0.5, lebar, 0, 0)
        ..close();

      canvas.drawPath(bentuk, isi);
      canvas.drawPath(bentuk, garis);
      canvas.drawLine(Offset.zero, Offset(panjang * 0.85, 0), garis);

      canvas.restore();
    }

    // ---------- Ranting berdaun ----------
    void ranting(
      Offset awal,
      Offset kontrol,
      Offset akhir,
      double arah,
    ) {
      final batang = Path()
        ..moveTo(awal.dx, awal.dy)
        ..quadraticBezierTo(kontrol.dx, kontrol.dy, akhir.dx, akhir.dy);

      canvas.drawPath(batang, garis);

      const titik = [0.30, 0.52, 0.74, 1.0];
      for (var i = 0; i < titik.length; i++) {
        final t = titik[i];
        final mt = 1 - t;
        final x = mt * mt * awal.dx +
            2 * mt * t * kontrol.dx +
            t * t * akhir.dx;
        final y = mt * mt * awal.dy +
            2 * mt * t * kontrol.dy +
            t * t * akhir.dy;

        final miring = i.isEven ? -0.7 : 0.7;
        daun(Offset(x, y), 30 + t * 10, arah + miring);
      }
    }

    final lebarRanting = math.min(w * 0.24, 240.0);

    // Pojok kanan atas (mengarah ke kiri-bawah)
    ranting(
      Offset(w, h * 0.05),
      Offset(w - lebarRanting * 0.4, h * 0.07),
      Offset(w - lebarRanting, h * 0.17),
      math.pi - 0.25,
    );

    // Pojok kiri atas (mengarah ke kanan-bawah)
    ranting(
      Offset(0, h * 0.10),
      Offset(lebarRanting * 0.4, h * 0.12),
      Offset(lebarRanting * 0.85, h * 0.22),
      0.25,
    );

    // ---------- Biji kopi ----------
    void biji(Offset pusat, double ukuran, double sudut) {
      canvas.save();
      canvas.translate(pusat.dx, pusat.dy);
      canvas.rotate(sudut);

      final badan = Rect.fromCenter(
        center: Offset.zero,
        width: ukuran * 1.5,
        height: ukuran,
      );

      canvas.drawOval(badan, isi);
      canvas.drawOval(badan, garis);

      final alur = Path()
        ..moveTo(-ukuran * 0.65, 0)
        ..quadraticBezierTo(-ukuran * 0.2, -ukuran * 0.35, 0, 0)
        ..quadraticBezierTo(ukuran * 0.2, ukuran * 0.35, ukuran * 0.65, 0);

      canvas.drawPath(alur, garis);
      canvas.restore();
    }

    biji(Offset(w * 0.12, h * 0.40), 26, -0.5);
    biji(Offset(w * 0.90, h * 0.36), 22, 0.6);
    biji(Offset(w * 0.22, h * 0.56), 18, 0.3);
    biji(Offset(w * 0.80, h * 0.52), 20, -0.8);
  }

  @override
  bool shouldRepaint(covariant _LoginDoodlePainter oldDelegate) {
    return oldDelegate.dark != dark;
  }
}