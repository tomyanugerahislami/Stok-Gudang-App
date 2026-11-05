import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:barcode_widget/barcode_widget.dart';
import '../../shared/providers/app_providers.dart';
import '../../core/utils/formatters.dart';
import '../../shared/models/product.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;
  final Product? product;

  const ProductDetailScreen({
    super.key,
    required this.productId,
    this.product,
  });

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  Product? _product;
  bool _isLoading = true;
  bool _hasTransactions = false;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    final service = ref.read(supabaseServiceProvider);
    if (widget.product != null) {
      _product = widget.product;
    } else {
      final list = await service.getProducts();
      _product = list.firstWhere(
        (p) => p.id == widget.productId,
        orElse: () => throw Exception('Produk tidak ditemukan'),
      );
    }
    _hasTransactions = await service.hasProductTransactions(widget.productId);
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _handleArchive() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Arsipkan Produk?'),
        content: Text(
          'Produk "${_product?.nama}" akan diarsipkan dan disembunyikan dari transaksi aktif.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade800),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Arsipkan'),
          ),
        ],
      ),
    );

    if (confirmed == true && _product != null) {
      await ref.read(supabaseServiceProvider).archiveProduct(_product!.id);
      ref.invalidate(productsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produk berhasil diarsipkan')),
        );
        context.go('/products');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final prod = _product;
    if (prod == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Produk tidak ditemukan')),
      );
    }

    final inventoryAsync = ref.watch(inventoryProvider);
    final profileAsync = ref.watch(currentProfileProvider);
    final user = profileAsync.value;

    return Scaffold(
      appBar: AppBar(
        title: Text(prod.nama),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/products'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_2),
            tooltip: 'Cetak Label Barcode',
            onPressed: () => context.go('/barcode/print', extra: prod),
          ),
          if (user?.canManageMasterData ?? true) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit Produk',
              onPressed: () => context.go('/products/edit', extra: prod),
            ),
            IconButton(
              icon: const Icon(Icons.archive_outlined),
              tooltip: 'Arsipkan Produk',
              onPressed: _handleArchive,
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Detail & Barcode Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Details
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary.withAlpha(25),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      prod.sku,
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: (prod.isActive ? Colors.green : Colors.grey).withAlpha(25),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      prod.status.toUpperCase(),
                                      style: TextStyle(
                                        color: prod.isActive ? Colors.green.shade800 : Colors.grey.shade700,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                prod.nama,
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Kategori: ${prod.categoryName ?? "Umum"}',
                                style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
                              ),
                              const Divider(height: 24),
                              Wrap(
                                spacing: 24,
                                runSpacing: 12,
                                children: [
                                  _buildInfoItem('Total Stok', '${Formatters.number(prod.currentStock)} ${prod.unit}'),
                                  _buildInfoItem('Stok Minimum', '${Formatters.number(prod.minimumStock)} ${prod.unit}'),
                                  _buildInfoItem('Harga Modal', Formatters.currency(prod.costPrice)),
                                  _buildInfoItem('Satuan', prod.unit),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 24),

                        // Right Barcode Widget
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'Label Barcode',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  height: 80,
                                  child: BarcodeWidget(
                                    barcode: Barcode.code128(),
                                    data: prod.barcode,
                                    drawText: true,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.print, size: 16),
                                  label: const Text('Cetak Label', style: TextStyle(fontSize: 12)),
                                  onPressed: () => context.go('/barcode/print', extra: prod),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Stock distribution by warehouse
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sebaran Stok per Gudang',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const Divider(height: 20),
                        inventoryAsync.when(
                          data: (items) {
                            final prodItems = items.where((i) => i.productId == prod.id).toList();
                            if (prodItems.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Text('Belum ada stok tercatat di gudang manapun.'),
                              );
                            }
                            return ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: prodItems.length,
                              separatorBuilder: (_, _) => const Divider(height: 1),
                              itemBuilder: (context, idx) {
                                final item = prodItems[idx];
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(Icons.warehouse_outlined),
                                  title: Text(item.warehouseName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  trailing: Text(
                                    '${Formatters.number(item.quantity)} ${item.productUnit}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                );
                              },
                            );
                          },
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (err, _) => Text('Gagal memuat stok: $err'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Transaction History Info Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.history_toggle_off, color: Color(0xFF1E3A8A)),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Riwayat Mutasi & Transaksi', style: TextStyle(fontWeight: FontWeight.bold)),
                                Text(
                                  _hasTransactions
                                      ? 'Produk memiliki riwayat mutasi masuk/keluar (dilindungi dari penghapusan)'
                                      : 'Belum ada transaksi untuk produk ini',
                                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                        OutlinedButton(
                          onPressed: () => context.go('/inventory'),
                          child: const Text('Buka Kartu Stok'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    );
  }
}

