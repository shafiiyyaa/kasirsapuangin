import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../menu_board/models/order.dart';
import '../../menu_board/providers/order_provider.dart';
import '../../theme/app_theme.dart';

/// Langkah pesanan, SAMA PERSIS dengan yang dilihat pelanggan di halaman status:
/// Diterima -> Disiapkan -> Siap diantar -> Sudah diantar.
enum LangkahPesanan { diterima, disiapkan, siap, diantar, batal }

LangkahPesanan langkahDari(Order o) {
  if (o.status == OrderStatus.batal) return LangkahPesanan.batal;
  if (o.statusPengantaran == 'sudah_diantar') return LangkahPesanan.diantar;
  if (o.status == OrderStatus.selesai) return LangkahPesanan.siap;
  if (o.status == OrderStatus.diproses) return LangkahPesanan.disiapkan;
  return LangkahPesanan.diterima;
}

bool apakahTakeaway(Order o) => o.jenisPesanan == 'takeaway';

String labelLangkah(LangkahPesanan l, {bool takeaway = false}) {
  switch (l) {
    case LangkahPesanan.diterima:
      return 'Pesanan diterima';
    case LangkahPesanan.disiapkan:
      return 'Sedang disiapkan';
    case LangkahPesanan.siap:
      return takeaway ? 'Siap diambil' : 'Siap diantar';
    case LangkahPesanan.diantar:
      return takeaway ? 'Sudah diambil' : 'Sudah diantar';
    case LangkahPesanan.batal:
      return 'Dibatalkan';
  }
}

Color warnaLangkah(LangkahPesanan l) {
  switch (l) {
    case LangkahPesanan.diterima:
      return AppColors.statusBaru;
    case LangkahPesanan.disiapkan:
      return AppColors.statusDiproses;
    case LangkahPesanan.siap:
      return AppColors.gold;
    case LangkahPesanan.diantar:
      return AppColors.statusSelesai;
    case LangkahPesanan.batal:
      return AppColors.statusBatal;
  }
}

IconData ikonLangkah(LangkahPesanan l) {
  switch (l) {
    case LangkahPesanan.diterima:
      return Icons.inbox_rounded;
    case LangkahPesanan.disiapkan:
      return Icons.coffee_maker_rounded;
    case LangkahPesanan.siap:
      return Icons.room_service_rounded;
    case LangkahPesanan.diantar:
      return Icons.done_all_rounded;
    case LangkahPesanan.batal:
      return Icons.cancel_rounded;
  }
}

/// Tulisan tombol untuk melangkah ke tahap berikutnya (null = sudah selesai).
String? labelAksi(LangkahPesanan l, {bool takeaway = false}) {
  switch (l) {
    case LangkahPesanan.diterima:
      return 'Mulai siapkan';
    case LangkahPesanan.disiapkan:
      return takeaway ? 'Siap diambil' : 'Siap diantar';
    case LangkahPesanan.siap:
      return takeaway ? 'Sudah diambil' : 'Sudah diantar';
    case LangkahPesanan.diantar:
    case LangkahPesanan.batal:
      return null;
  }
}

IconData ikonAksi(LangkahPesanan l) {
  switch (l) {
    case LangkahPesanan.diterima:
      return Icons.play_arrow_rounded;
    case LangkahPesanan.disiapkan:
      return Icons.room_service_rounded;
    case LangkahPesanan.siap:
      return Icons.delivery_dining_rounded;
    case LangkahPesanan.diantar:
    case LangkahPesanan.batal:
      return Icons.check_rounded;
  }
}

/// Pesan sukses setelah melangkah DARI [l] ke tahap berikutnya.
String pesanSetelahMaju(LangkahPesanan l, {bool takeaway = false}) {
  switch (l) {
    case LangkahPesanan.diterima:
      return 'Pesanan mulai disiapkan.';
    case LangkahPesanan.disiapkan:
      return takeaway ? 'Pesanan siap diambil.' : 'Pesanan siap diantar.';
    case LangkahPesanan.siap:
      return takeaway
          ? 'Pesanan sudah diambil pelanggan.'
          : 'Pesanan sudah diantar.';
    case LangkahPesanan.diantar:
    case LangkahPesanan.batal:
      return 'Status diperbarui.';
  }
}

/// Maju satu tahap. Melempar error kalau gagal (ditangkap pemanggil).
Future<void> majuSatuLangkah(BuildContext context, Order o) async {
  final provider = context.read<OrderProvider>();

  switch (langkahDari(o)) {
    case LangkahPesanan.diterima:
      await provider.updateOrderStatus(o.id, OrderStatus.diproses);
      break;
    case LangkahPesanan.disiapkan:
      await provider.updateOrderStatus(o.id, OrderStatus.selesai);
      break;
    case LangkahPesanan.siap:
      await provider.updateStatusPengantaran(o.id, sudahDiantar: true);
      break;
    case LangkahPesanan.diantar:
    case LangkahPesanan.batal:
      break;
  }
}

/// Mundur satu tahap (kalau kasir salah tekan). Pesanan batal -> diaktifkan lagi.
Future<void> mundurSatuLangkah(BuildContext context, Order o) async {
  final provider = context.read<OrderProvider>();

  switch (langkahDari(o)) {
    case LangkahPesanan.diantar:
      await provider.updateStatusPengantaran(o.id, sudahDiantar: false);
      break;
    case LangkahPesanan.siap:
      await provider.updateOrderStatus(o.id, OrderStatus.diproses);
      break;
    case LangkahPesanan.disiapkan:
      await provider.updateOrderStatus(o.id, OrderStatus.baru);
      break;
    case LangkahPesanan.batal:
      await provider.updateOrderStatus(o.id, OrderStatus.baru);
      break;
    case LangkahPesanan.diterima:
      break;
  }
}

Future<void> batalkanPesanan(BuildContext context, Order o) async {
  final provider = context.read<OrderProvider>();
  await provider.updateOrderStatus(o.id, OrderStatus.batal);
}

/// Label status berbentuk pil. Berganti dengan animasi saat status berubah.
class StatusPill extends StatelessWidget {
  final Order order;

  const StatusPill({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final langkah = langkahDari(order);
    final warna = warnaLangkah(langkah);
    final perluPerhatian =
        order.sumberPesanan == 'qr' && langkah == LangkahPesanan.diterima;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animasi) {
        return FadeTransition(
          opacity: animasi,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.85, end: 1.0).animate(animasi),
            child: child,
          ),
        );
      },
      child: Container(
        key: ValueKey(langkah),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: warna.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (perluPerhatian) ...[
              TitikBerkedip(warna: warna),
              const SizedBox(width: 6),
            ],
            Icon(ikonLangkah(langkah), size: 13, color: warna),
            const SizedBox(width: 5),
            Text(
              labelLangkah(langkah, takeaway: apakahTakeaway(order)),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: warna,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tombol kecil di kartu pesanan untuk langsung maju satu tahap
/// (tanpa perlu membuka rincian pesanan).
class AksiCepat extends StatefulWidget {
  final Order order;

  const AksiCepat({super.key, required this.order});

  @override
  State<AksiCepat> createState() => _AksiCepatState();
}

class _AksiCepatState extends State<AksiCepat> {
  bool _sibuk = false;

  Future<void> _jalan() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _sibuk = true);

    try {
      await majuSatuLangkah(context, widget.order);
    } catch (error) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(content: Text('Gagal memperbarui status: $error')),
      );
    } finally {
      if (mounted) setState(() => _sibuk = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final langkah = langkahDari(widget.order);
    final label = labelAksi(
      langkah,
      takeaway: apakahTakeaway(widget.order),
    );

    if (label == null) return const SizedBox.shrink();

    return FilledButton.icon(
      onPressed: _sibuk ? null : _jalan,
      style: FilledButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        minimumSize: const Size(0, 34),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
      icon: _sibuk
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(ikonAksi(langkah), size: 16),
      label: Text(label),
    );
  }
}

/// Pelacak 4 tahap dengan garis yang terisi animasi.
class PelacakStatus extends StatelessWidget {
  final LangkahPesanan langkah;
  final bool takeaway;

  const PelacakStatus({
    super.key,
    required this.langkah,
    required this.takeaway,
  });

  int get _aktif {
    switch (langkah) {
      case LangkahPesanan.diterima:
        return 0;
      case LangkahPesanan.disiapkan:
        return 1;
      case LangkahPesanan.siap:
        return 2;
      case LangkahPesanan.diantar:
        return 3;
      case LangkahPesanan.batal:
        return -1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final aktif = _aktif;
    final judul = [
      'Diterima',
      'Disiapkan',
      takeaway ? 'Siap diambil' : 'Siap diantar',
      takeaway ? 'Diambil' : 'Diantar',
    ];
    final ikon = [
      Icons.inbox_rounded,
      Icons.coffee_maker_rounded,
      Icons.room_service_rounded,
      Icons.done_all_rounded,
    ];

    final tampil = <Widget>[];
    for (var i = 0; i < 4; i++) {
      tampil.add(
        _Titik(
          label: judul[i],
          ikon: ikon[i],
          selesai: aktif > i || aktif == 3,
          sedang: aktif == i && aktif != 3,
        ),
      );
      if (i < 3) {
        tampil.add(
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 17),
              child: _Garis(terisi: aktif > i),
            ),
          ),
        );
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: tampil,
    );
  }
}

class _Garis extends StatelessWidget {
  final bool terisi;

  const _Garis({required this.terisi});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      height: 4,
      decoration: BoxDecoration(
        color: terisi ? AppColors.forestGreen : scheme.outlineVariant,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _Titik extends StatelessWidget {
  final String label;
  final IconData ikon;
  final bool selesai;
  final bool sedang;

  const _Titik({
    required this.label,
    required this.ikon,
    required this.selesai,
    required this.sedang,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final Color warna;
    if (selesai) {
      warna = AppColors.forestGreen;
    } else if (sedang) {
      warna = AppColors.gold;
    } else {
      warna = scheme.outlineVariant;
    }

    return SizedBox(
      width: 62,
      child: Column(
        children: [
          AnimatedScale(
            scale: sedang ? 1.14 : 1.0,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutBack,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (selesai || sedang) ? warna : Colors.transparent,
                border: Border.all(color: warna, width: 2),
                boxShadow: sedang
                    ? [
                        BoxShadow(
                          color: warna.withValues(alpha: 0.45),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ]
                    : const [],
              ),
              child: Icon(
                selesai ? Icons.check_rounded : ikon,
                size: 19,
                color: (selesai || sedang)
                    ? Colors.white
                    : scheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: TextStyle(
              fontSize: 10.5,
              height: 1.15,
              fontWeight: (selesai || sedang) ? FontWeight.w700 : FontWeight.w500,
              color: (selesai || sedang)
                  ? scheme.onSurface
                  : scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Titik kecil yang berdenyut: tanda pesanan QR baru yang belum diurus kasir.
class TitikBerkedip extends StatefulWidget {
  final Color warna;

  const TitikBerkedip({super.key, required this.warna});

  @override
  State<TitikBerkedip> createState() => _TitikBerkedipState();
}

class _TitikBerkedipState extends State<TitikBerkedip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _denyut;

  @override
  void initState() {
    super.initState();
    _denyut = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _denyut.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _denyut,
      builder: (context, _) {
        final nilai = _denyut.value;
        return SizedBox(
          width: 14,
          height: 14,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 8 + nilai * 6,
                height: 8 + nilai * 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.warna.withValues(alpha: 0.35 * (1 - nilai)),
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.warna,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}