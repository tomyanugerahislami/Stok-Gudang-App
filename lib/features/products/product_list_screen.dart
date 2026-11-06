import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/providers/app_providers.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../shared/models/product.dart';

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final filter = ref.watch(productFilterProvider);
    final profileAsync = ref.watch(currentProfileProvider);
    final user = profileAsync.value;
    final canEdit = user?.canManageMasterData ?? true;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header & Action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Katalog Produk',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Kelola data master barang, barcode, dan stok minimum',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                    ),
                  ],
                ),
                if (canEdit)
                  ElevatedButton.icon(
                    onPressed: () => context.go('/products/new'),
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah Produk'),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Search & Filter Toolbar
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Search bar
                    SizedBox(
                      width: 260,
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Cari nama, SKU, barcode...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    ref.read(productFilterProvider.notifier).set(
                                      filter.copyWith(query: ''),
                                    );
                                  },
                                )
                              : null,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        onChanged: (val) {
                          ref.read(productFilterProvider.notifier).set(
                            filter.copyWith(query: val),
                          );
                        },
                      ),
                    ),

                    // Category dropdown filter
                    categoriesAsync.when(
                      data: (categories) => SizedBox(
                        width: 200,
                        child: DropdownButtonFormField<String?>(
                          initialValue: filter.categoryId,
                          isDense: true,
                          decoration: const InputDecoration(
                            labelText: 'Kategori',
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('Semua Kategori')),
                            ...categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.nama))),
                          ],
                          onChanged: (val) {
                            ref.read(productFilterProvider.notifier).set(
                              filter.copyWith(categoryId: val),
                            );
                          },
                        ),
                      ),
                      loading: () => const SizedBox(width: 150, height: 40),
                      error: (_, _) => const SizedBox.shrink(),
                    ),

                    // Status Filter (Aktif / Arsip)
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'active', label: Text('Aktif')),
                        ButtonSegment(value: 'archived', label: Text('Arsip')),
                      ],
                      selected: {filter.status},
                      onSelectionChanged: (set) {
                        ref.read(productFilterProvider.notifier).set(
                          filter.copyWith(status: set.first),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Products Content
            Expanded(
              child: productsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(
                  child: Text('Gagal memuat produk: $err', style: const TextStyle(color: Colors.red)),
                ),
                data: (products) {
                  if (products.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 54, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text(
                            'Tidak ada produk ditemukan',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 6),
                          const Text('Coba ubah kata kunci pencarian atau tambah produk baru'),
                        ],
                      ),
                    );
                  }

                  final isDesktop = Responsive.isDesktop(context);

                  if (isDesktop) {
                    return _buildProductDataTable(context, ref, products, canEdit);
                  } else {
                    return _buildProductListView(context, products);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductDataTable(
    BuildContext context,
    WidgetRef ref,
    List<Product> products,
    bool canEdit,
  ) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        child: SizedBox(
          width: double.infinity,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
            columns: const [
              DataColumn(label: Text('SKU / Kode', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Nama Produk', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Kategori', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Barcode', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Stok / Min', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Harga Modal', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Aksi', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: products.map((prod) {
              final isLow = prod.isLowStock;
              return DataRow(
                cells: [
                  DataCell(
                    Text(prod.sku, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                    onTap: () => context.go('/products/detail/${prod.id}', extra: prod),
                  ),
                  DataCell(
                    Text(prod.nama, style: const TextStyle(fontWeight: FontWeight.w600)),
                    onTap: () => context.go('/products/detail/${prod.id}', extra: prod),
                  ),
                  DataCell(Text(prod.categoryName ?? '-')),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.qr_code, size: 16, color: Color(0xFF64748B)),
                        const SizedBox(width: 4),
                        Text(prod.barcode, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                      ],
                    ),
                  ),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${Formatters.number(prod.currentStock)} ${prod.unit}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isLow ? const Color(0xFFDC2626) : const Color(0xFF0F172A),
                          ),
                        ),
                        if (isLow) ...[
                          const SizedBox(width: 6),
                          const Tooltip(
                            message: 'Di bawah stok minimum',
                            child: Icon(Icons.warning_amber, size: 16, color: Color(0xFFDC2626)),
                          ),
                        ],
                      ],
                    ),
                  ),
                  DataCell(Text(Formatters.currency(prod.costPrice))),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (prod.isActive ? Colors.green : Colors.grey).withAlpha(25),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        prod.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: prod.isActive ? Colors.green.shade800 : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.qr_code_2, size: 20),
                          tooltip: 'Cetak Label Barcode',
                          onPressed: () => context.go('/barcode/print', extra: prod),
                        ),
                        if (canEdit)
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            tooltip: 'Edit Produk',
                            onPressed: () => context.go('/products/edit', extra: prod),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildProductListView(BuildContext context, List<Product> products) {
    return ListView.builder(
      itemCount: products.length,
      itemBuilder: (context, index) {
        final prod = products[index];
        final isLow = prod.isLowStock;

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            onTap: () => context.go('/products/detail/${prod.id}', extra: prod),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    prod.nama,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                if (isLow)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.warning, size: 12, color: Colors.red),
                        SizedBox(width: 4),
                        Text('Stok Menipis', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('SKU: ${prod.sku} • Barcode: ${prod.barcode}', style: const TextStyle(fontSize: 12)),
                Text('Kategori: ${prod.categoryName ?? "-"} • Biaya: ${Formatters.currency(prod.costPrice)}', style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  'Stok: ${Formatters.number(prod.currentStock)} ${prod.unit} (Min: ${Formatters.number(prod.minimumStock)})',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isLow ? Colors.red : Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.qr_code_2),
              tooltip: 'Cetak Barcode',
              onPressed: () => context.go('/barcode/print', extra: prod),
            ),
          ),
        );
      },
    );
  }
}

