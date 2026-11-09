import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/providers/app_providers.dart';
import '../../core/utils/formatters.dart';
import '../../shared/models/product.dart';
import '../../shared/models/stock_opname.dart';

class StockOpnameScreen extends ConsumerStatefulWidget {
  const StockOpnameScreen({super.key});

  @override
  ConsumerState<StockOpnameScreen> createState() => _StockOpnameScreenState();
}

class _StockOpnameScreenState extends ConsumerState<StockOpnameScreen> {
  String? _selectedWarehouseId;
  DateTime _selectedDate = DateTime.now();
  final _catatanController = TextEditingController();

  final Map<String, double> _physicalCounts = {};
  final Map<String, TextEditingController> _countControllers = {};
  bool _isPosting = false;

  @override
  void dispose() {
    _catatanController.dispose();
    for (var c in _countControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submitOpname(List<Product> products) async {
    if (_selectedWarehouseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih gudang yang akan di-opname')),
      );
      return;
    }

    final service = ref.read(supabaseServiceProvider);
    final List<StockOpnameItem> opnameItems = [];

    for (var prod in products.where((p) => p.isActive)) {
      final systemStock = await service.getStock(prod.id, _selectedWarehouseId!);
      final physicalStock = _physicalCounts[prod.id] ?? systemStock;
      final diff = physicalStock - systemStock;

      opnameItems.add(
        StockOpnameItem(
          productId: prod.id,
          productName: prod.nama,
          productSku: prod.sku,
          productUnit: prod.unit,
          systemQuantity: systemStock,
          physicalQuantity: physicalStock,
          difference: diff,
          notes: diff != 0 ? 'Selisih opname: $diff' : 'Sesuai',
        ),
      );
    }

    final diffItemsCount = opnameItems.where((i) => i.difference != 0).length;

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Posting Stok Opname'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total produk dihitung: ${opnameItems.length}'),
            Text('Produk dengan selisih: $diffItemsCount'),
            const SizedBox(height: 12),
            const Text(
              'Selisih fisik akan otomatis dicatat sebagai transaksi penyesuaian (ADJUSTMENT) dengan audit trail lengkap.',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Posting Opname'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isPosting = true);
    try {
      final opnNumber = await service.createAndPostOpname(
        warehouseId: _selectedWarehouseId!,
        tanggal: _selectedDate,
        catatan: _catatanController.text.trim(),
        items: opnameItems,
      );

      ref.invalidate(inventoryProvider);
      ref.invalidate(productsProvider);
      ref.invalidate(dashboardMetricsProvider);
      ref.invalidate(transactionsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF16A34A),
            content: Text('Stok Opname berhasil diposting! No: $opnNumber'),
          ),
        );
        context.go('/inventory');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red, content: Text('Gagal posting opname: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final warehousesAsync = ref.watch(warehousesProvider);
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stok Opname & Penyesuaian Fisik'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/inventory'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Config card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pemeriksaan Fisik Gudang',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Bandingkan stok yang tercatat pada sistem dengan hasil hitung fisik langsung di gudang.',
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                        ),
                        const Divider(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: warehousesAsync.when(
                                data: (warehouses) {
                                  if (_selectedWarehouseId == null && warehouses.isNotEmpty) {
                                    _selectedWarehouseId = warehouses.first.id;
                                  }
                                  return DropdownButtonFormField<String>(
                                    initialValue: _selectedWarehouseId,
                                    decoration: const InputDecoration(
                                      labelText: 'Pilih Gudang Opname *',
                                      prefixIcon: Icon(Icons.warehouse_outlined),
                                    ),
                                    items: warehouses.map((w) {
                                      return DropdownMenuItem(value: w.id, child: Text(w.nama));
                                    }).toList(),
                                    onChanged: (val) {
                                      setState(() {
                                        _selectedWarehouseId = val;
                                        _physicalCounts.clear();
                                      });
                                    },
                                  );
                                },
                                loading: () => const LinearProgressIndicator(),
                                error: (_, _) => const SizedBox.shrink(),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: _selectedDate,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime.now(),
                                  );
                                  if (picked != null) {
                                    setState(() => _selectedDate = picked);
                                  }
                                },
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Tanggal Opname',
                                    prefixIcon: Icon(Icons.calendar_today),
                                  ),
                                  child: Text(Formatters.date(_selectedDate)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _catatanController,
                          decoration: const InputDecoration(
                            labelText: 'Catatan Pelaksanaan Opname',
                            hintText: 'Opname berkala akhir bulan / audit fisik',
                            prefixIcon: Icon(Icons.notes),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Table of products to compare
                productsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Text('Gagal memuat daftar produk: $err'),
                  data: (products) {
                    final activeProds = products.where((p) => p.isActive).toList();

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Input Hitungan Fisik per Produk',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const Divider(height: 20),
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: activeProds.length,
                              separatorBuilder: (_, _) => const Divider(height: 1),
                              itemBuilder: (context, idx) {
                                final prod = activeProds[idx];

                                if (!_countControllers.containsKey(prod.id)) {
                                  _countControllers[prod.id] = TextEditingController(
                                    text: prod.currentStock.toStringAsFixed(0),
                                  );
                                  _physicalCounts[prod.id] = prod.currentStock;
                                }

                                final physical = _physicalCounts[prod.id] ?? prod.currentStock;
                                final diff = physical - prod.currentStock;

                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 4,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(prod.nama, style: const TextStyle(fontWeight: FontWeight.bold)),
                                            Text('${prod.sku} • ${prod.barcode}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('Sistem', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                                            Text(
                                              '${Formatters.number(prod.currentStock)} ${prod.unit}',
                                              style: const TextStyle(fontWeight: FontWeight.w600),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: SizedBox(
                                          height: 44,
                                          child: TextField(
                                            controller: _countControllers[prod.id],
                                            keyboardType: TextInputType.number,
                                            decoration: InputDecoration(
                                              labelText: 'Fisik (${prod.unit})',
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                            ),
                                            onChanged: (val) {
                                              final entered = double.tryParse(val) ?? prod.currentStock;
                                              setState(() {
                                                _physicalCounts[prod.id] = entered;
                                              });
                                            },
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        flex: 2,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            const Text('Selisih', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                                            Text(
                                              diff == 0
                                                  ? '0'
                                                  : diff > 0
                                                      ? '+${Formatters.number(diff)}'
                                                      : Formatters.number(diff),
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: diff == 0
                                                    ? Colors.grey
                                                    : diff > 0
                                                        ? const Color(0xFF16A34A)
                                                        : const Color(0xFFDC2626),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              onPressed: _isPosting ? null : () => _submitOpname(activeProds),
                              icon: _isPosting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.fact_check),
                              label: Text(_isPosting ? 'Menyimpan Opname...' : 'Posting Hasil Opname & Koreksi Stok'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

