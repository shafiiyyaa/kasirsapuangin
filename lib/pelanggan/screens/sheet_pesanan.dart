import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../theme/app_theme.dart';
import '../config_pelanggan.dart';
import '../pelanggan_provider.dart';
import 'menu_pelanggan_screen.dart' show StepperJumlah;

/// Lembar pesanan (bottom sheet): cek keranjang, isi data, pilih pembayaran, kirim.
class SheetPesanan extends StatefulWidget {
  const SheetPesanan({super.key});

  @override
  State<SheetPesanan> createState() => _SheetPesananState();
}

class _SheetPesananState extends State<SheetPesanan> {
  late final TextEditingController _namaController;
  late final TextEditingController _mejaController;

  @override
  void initState() {
    super.initState();
    final prov = context.read<PelangganProvider>();
    _namaController = TextEditingController(text: prov.namaPemesan);
    _mejaController = TextEditingController(text: prov.meja);
  }

  @override
  void dispose() {
    _namaController.dispose();
    _mejaController.dispose();
    super.dispose();
  }

  Future<void> _editCatatan(ItemKeranjang item) async {
    final controller = TextEditingController(text: item.catatan ?? '');

    final hasil = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Catatan untuk ${item.menu.nama}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 120,
          maxLines: 2,
          decoration: const InputDecoration(
            hintText: 'Mis. less sugar, tanpa es',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (hasil != null && mounted) {
      context.read<PelangganProvider>().ubahCatatan(item.menu.id, hasil);
    }
  }

  Future<void> _kirim() async {
    final prov = context.read<PelangganProvider>();
    final router = GoRouter.of(context);
    final navigator = Navigator.of(context);

    final id = await prov.kirimPesanan();
    if (id == null) return; // pesan kesalahan sudah tampil di lembar ini

    if (mounted) navigator.pop();
    router.go('/pesanan/$id');
  }

  String _infoPembayaran(String metode) {
    switch (metode) {
      case 'qris':
        return kInfoQris;
      case 'transfer':
        return kInfoTransfer;
      default:
        return kInfoCash;
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<PelangganProvider>();
    final keyboard = MediaQuery.of(context).viewInsets.bottom;
    final dineIn = prov.jenisPesanan == 'dine_in';

    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.lightBorder,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: prov.keranjang.isEmpty
                  ? _kosong()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Pesanan Kamu',
                                style: AppTextStyles.displaySmall,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.sageLight.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${prov.jumlahItem} item',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.forestGreenDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        for (final item in prov.keranjang) _barisItem(prov, item),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _namaController,
                          onChanged: prov.setNama,
                          maxLength: 60,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Nama pemesan *',
                            prefixIcon: Icon(Icons.person_outline),
                            counterText: '',
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: SegmentedButton<String>(
                            showSelectedIcon: false,
                            segments: const [
                              ButtonSegment(
                                value: 'dine_in',
                                label: Text('Dine-in'),
                                icon: Icon(Icons.restaurant_rounded),
                              ),
                              ButtonSegment(
                                value: 'takeaway',
                                label: Text('Take away'),
                                icon: Icon(Icons.shopping_bag_outlined),
                              ),
                            ],
                            selected: {prov.jenisPesanan},
                            onSelectionChanged: (pilihan) =>
                                prov.setJenis(pilihan.first),
                          ),
                        ),
                        if (dineIn) ...[
                          const SizedBox(height: 12),
                          TextField(
                            controller: _mejaController,
                            onChanged: prov.setMeja,
                            maxLength: 10,
                            decoration: InputDecoration(
                              labelText: 'Nomor meja *',
                              prefixIcon: const Icon(Icons.event_seat_outlined),
                              counterText: '',
                              helperText: prov.mejaDariQr
                                  ? 'Terisi otomatis dari QR meja'
                                  : null,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        const Text(
                          'Pembayaran',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            _chipBayar(prov, 'cash', 'Cash'),
                            _chipBayar(prov, 'qris', 'QRIS'),
                            _chipBayar(prov, 'transfer', 'Transfer'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.lightSurfaceAlt,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _infoPembayaran(prov.metodePembayaran),
                            style: const TextStyle(fontSize: 12, height: 1.4),
                          ),
                        ),
                        if (prov.errorKirim != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline,
                                    size: 18, color: AppColors.error),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    prov.errorKirim!,
                                    style: const TextStyle(
                                        fontSize: 13, color: AppColors.error),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                      ],
                    ),
            ),
          ),
          if (prov.keranjang.isNotEmpty)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                        const Spacer(),
                        Text(
                          rupiah(prov.total),
                          style: AppTextStyles.priceLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    FilledButton(
                      onPressed: prov.mengirim ? null : _kirim,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child: prov.mengirim
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Kirim Pesanan'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _kosong() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          const Icon(Icons.shopping_basket_outlined, size: 40),
          const SizedBox(height: 12),
          const Text('Keranjang masih kosong.'),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Pilih menu'),
          ),
        ],
      ),
    );
  }

  Widget _chipBayar(PelangganProvider prov, String nilai, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: prov.metodePembayaran == nilai,
      onSelected: (_) => prov.setMetode(nilai),
    );
  }

  Widget _barisItem(PelangganProvider prov, ItemKeranjang item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.menu.nama,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                rupiah(item.subtotal),
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _editCatatan(item),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.edit_note_rounded,
                            size: 18, color: AppColors.forestGreen),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.catatan ?? 'Tambah catatan',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: item.catatan == null
                                  ? AppColors.forestGreen
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              StepperJumlah(
                jumlah: item.jumlah,
                onTambah: () => prov.tambah(item.menu),
                onKurang: () => prov.kurang(item.menu.id),
              ),
            ],
          ),
        ],
      ),
    );
  }
}