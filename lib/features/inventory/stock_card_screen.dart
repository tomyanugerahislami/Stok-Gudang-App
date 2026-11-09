import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/providers/app_providers.dart';
import '../../core/utils/formatters.dart';
import '../../shared/models/inventory_item.dart';
import '../../shared/models/product.dart';

class StockCardRow {
  final DateTime date;
  final String txNumber;
  final String type;
  final String warehouse;
  final double inQty;
  final double outQty;
  final double balance;
  final String? document;
  final String? notes;

  StockCardRow({
    required this.date,
    required this.txNumber,
    required this.type,
    required this.warehouse,
    required this.inQty,
    required this.outQty,
    required this.balance,
    this.document,
    this.notes,
  });
}

class StockCardScreen extends ConsumerStatefulWidget {
  final String productId;
  final InventoryItem? inventoryItem;

  const StockCardScreen({
    super.key,
    required this.productId,
    this.inventoryItem,
  });

  @override
  ConsumerState<StockCardScreen> createState() => _StockCardScreenState();
}

class _StockCardScreenState extends ConsumerState<StockCardScreen> {
  Product? _product;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final service = ref.read(supabaseServiceProvider);
    final products = await service.getProducts();
    _product = products.firstWhere(
      (p) => p.id == widget.productId,
      orElse: () => products.first,
    );
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final prod = _product;
    final transactionsAsync = ref.watch(transactionsProvider);
    final selectedWh = ref.watch(selectedWarehouseProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Kartu Stok: ${prod?.nama ?? ""}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Product summary card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(25),
                      child: Icon(Icons.inventory_2, color: Theme.of(context).colorScheme.primary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(prod?.nama ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('SKU: ${prod?.sku} • Barcode: ${prod?.barcode} • Satuan: ${prod?.unit}'),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Total Stok Terkini:', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        Text(
                          '${Formatters.number(prod?.currentStock)} ${prod?.unit}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: (prod?.isLowStock == true) ? Colors.red : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Stock Card Entries Table
            transactionsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text('Gagal memuat mutasi: $err'),
              data: (transactions) {
                // Filter transactions that contain this product
                final relevantTxs = transactions.where((t) {
                  if (selectedWh != null && t.warehouseId != selectedWh.id) return false;
                  return t.items.any((i) => i.productId == widget.productId);
                }).toList();

                // Sort ascending by date to compute running balance
                relevantTxs.sort((a, b) => a.tanggal.compareTo(b.tanggal));

                double runningStock = 0;
                final List<StockCardRow> rows = [];

                for (var tx in relevantTxs) {
                  for (var item in tx.items.where((i) => i.productId == widget.productId)) {
                    double inQty = 0;
                    double outQty = 0;

                    if (tx.tipe == 'IN') {
                      inQty = item.quantity;
                      runningStock += inQty;
                    } else if (tx.tipe == 'OUT') {
                      outQty = item.quantity;
                      runningStock -= outQty;
                    } else if (tx.tipe == 'ADJUSTMENT') {
                      if (item.quantity >= 0) {
                        inQty = item.quantity;
                        runningStock += inQty;
                      } else {
                        outQty = item.quantity.abs();
                        runningStock -= outQty;
                      }
                    }

                    rows.add(
                      StockCardRow(
                        date: tx.tanggal,
                        txNumber: tx.nomorTransaksi,
                        type: tx.tipe,
                        warehouse: tx.warehouseName ?? 'Gudang',
                        inQty: inQty,
                        outQty: outQty,
                        balance: runningStock,
                        document: tx.documentNumber,
                        notes: tx.catatan,
                      ),
                    );
                  }
                }

                // Show most recent at top for display
                final displayRows = rows.reversed.toList();

                if (displayRows.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: Text('Belum ada riwayat mutasi untuk produk ini.')),
                    ),
                  );
                }

                return Card(
                  child: SingleChildScrollView(
                    child: SizedBox(
                      width: double.infinity,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                        columns: const [
                          DataColumn(label: Text('Tanggal', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('No Transaksi', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Tipe', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Gudang', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Masuk (+)', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Keluar (-)', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Saldo Stok', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Keterangan', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: displayRows.map((r) {
                          return DataRow(
                            cells: [
                              DataCell(Text(Formatters.date(r.date))),
                              DataCell(Text(r.txNumber, style: const TextStyle(fontWeight: FontWeight.w600))),
                              DataCell(Text(r.type)),
                              DataCell(Text(r.warehouse)),
                              DataCell(
                                Text(
                                  r.inQty > 0 ? '+${Formatters.number(r.inQty)}' : '-',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: r.inQty > 0 ? const Color(0xFF16A34A) : null,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  r.outQty > 0 ? '-${Formatters.number(r.outQty)}' : '-',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: r.outQty > 0 ? const Color(0xFFDC2626) : null,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  Formatters.number(r.balance),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataCell(Text(r.document ?? r.notes ?? '-')),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

