import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/providers/app_providers.dart';
import '../../core/utils/formatters.dart';
import '../../shared/models/product.dart';
import '../../shared/models/stock_transaction.dart';

class StockInScreen extends ConsumerStatefulWidget {
  const StockInScreen({super.key});

  @override
  ConsumerState<StockInScreen> createState() => _StockInScreenState();
}

class _StockInScreenState extends ConsumerState<StockInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _docNumberController = TextEditingController();
  final _catatanController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String? _selectedWarehouseId;
  String? _selectedSupplierId;

  final List<StockTransactionItem> _items = [];
  bool _isPosting = false;

  @override
  void dispose() {
    _docNumberController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  void _showAddProductDialog() async {
    final products = await ref.read(productsProvider.future);
    if (!mounted) return;

    Product? selectedProduct;
    final qtyController = TextEditingController(text: '1');
    final costController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Pilih Produk Masuk'),
            content: SizedBox(
              width: 450,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<Product>(
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Pilih Produk'),
                    items: products.where((p) => p.isActive).map((p) {
                      return DropdownMenuItem(
                        value: p,
                        child: Text('${p.nama} (${p.sku})', overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (p) {
                      setDialogState(() {
                        selectedProduct = p;
                        costController.text = p?.costPrice.toStringAsFixed(0) ?? '0';
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: qtyController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Jumlah (${selectedProduct?.unit ?? "pcs"})',
                            prefixIcon: const Icon(Icons.add_shopping_cart),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: costController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Biaya / Satuan (Rp)',
                            prefixIcon: Icon(Icons.payments_outlined),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
              ElevatedButton(
                onPressed: () {
                  if (selectedProduct == null) return;
                  final qty = double.tryParse(qtyController.text) ?? 0;
                  if (qty <= 0) return;
                  final cost = double.tryParse(costController.text) ?? 0;

                  setState(() {
                    _items.add(
                      StockTransactionItem(
                        productId: selectedProduct!.id,
                        productName: selectedProduct!.nama,
                        productSku: selectedProduct!.sku,
                        productUnit: selectedProduct!.unit,
                        quantity: qty,
                        unitCost: cost,
                      ),
                    );
                  });
                  Navigator.pop(ctx);
                },
                child: const Text('Tambah ke Daftar'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _submitStockIn() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedWarehouseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih gudang tujuan penerimaan barang')),
      );
      return;
    }

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tambahkan minimal satu produk masuk')),
      );
      return;
    }

    // Confirm dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Barang Masuk'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total jenis produk: ${_items.length} item'),
            Text('Total kuantitas: ${Formatters.number(_items.fold(0.0, (acc, i) => acc + i.quantity))}'),
            const SizedBox(height: 12),
            const Text(
              'Stok akan otomatis bertambah secara atomik di sistem.',
              style: TextStyle(color: Color(0xFF16A34A), fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16A34A)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Posting Transaksi'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isPosting = true);
    try {
      final service = ref.read(supabaseServiceProvider);
      final txNumber = await service.createAndPostTransaction(
        tipe: 'IN',
        warehouseId: _selectedWarehouseId!,
        supplierId: _selectedSupplierId,
        documentNumber: _docNumberController.text.trim(),
        tanggal: _selectedDate,
        catatan: _catatanController.text.trim(),
        items: _items,
      );

      // Invalidate caches
      ref.invalidate(inventoryProvider);
      ref.invalidate(productsProvider);
      ref.invalidate(dashboardMetricsProvider);
      ref.invalidate(transactionsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF16A34A),
            content: Text('Barang Masuk berhasil diposting! No: $txNumber'),
          ),
        );
        context.go('/inventory');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red, content: Text('Gagal posting: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final warehousesAsync = ref.watch(warehousesProvider);
    final suppliersAsync = ref.watch(suppliersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pencatatan Barang Masuk (Stock In)'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Info Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Informasi Penerimaan',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const Divider(height: 24),
                          // Warehouse & Date Row
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
                                        labelText: 'Gudang Tujuan *',
                                        prefixIcon: Icon(Icons.warehouse_outlined),
                                      ),
                                      items: warehouses.map((w) {
                                        return DropdownMenuItem(value: w.id, child: Text(w.nama));
                                      }).toList(),
                                      onChanged: (val) => setState(() => _selectedWarehouseId = val),
                                      validator: (val) => val == null ? 'Gudang wajib dipilih' : null,
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
                                      lastDate: DateTime.now().add(const Duration(days: 30)),
                                    );
                                    if (picked != null) {
                                      setState(() => _selectedDate = picked);
                                    }
                                  },
                                  child: InputDecorator(
                                    decoration: const InputDecoration(
                                      labelText: 'Tanggal Transaksi',
                                      prefixIcon: Icon(Icons.calendar_today),
                                    ),
                                    child: Text(Formatters.date(_selectedDate)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Supplier & Document Number Row
                          Row(
                            children: [
                              Expanded(
                                child: suppliersAsync.when(
                                  data: (suppliers) => DropdownButtonFormField<String?>(
                                    initialValue: _selectedSupplierId,
                                    decoration: const InputDecoration(
                                      labelText: 'Pemasok / Supplier',
                                      prefixIcon: Icon(Icons.local_shipping_outlined),
                                    ),
                                    items: [
                                      const DropdownMenuItem(value: null, child: Text('-- Pilih Supplier --')),
                                      ...suppliers.map((s) => DropdownMenuItem(value: s.id, child: Text(s.nama))),
                                    ],
                                    onChanged: (val) => setState(() => _selectedSupplierId = val),
                                  ),
                                  loading: () => const LinearProgressIndicator(),
                                  error: (_, _) => const SizedBox.shrink(),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: _docNumberController,
                                  decoration: const InputDecoration(
                                    labelText: 'Nomor Dokumen / Surat Jalan',
                                    hintText: 'SJ-2026-001',
                                    prefixIcon: Icon(Icons.receipt_long),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Notes
                          TextFormField(
                            controller: _catatanController,
                            decoration: const InputDecoration(
                              labelText: 'Catatan Transaksi (Opsional)',
                              prefixIcon: Icon(Icons.notes),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Items List Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Daftar Barang Masuk',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              ElevatedButton.icon(
                                onPressed: _showAddProductDialog,
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Pilih Produk'),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          if (_items.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 32),
                              child: Center(
                                child: Text(
                                  'Belum ada item ditambahkan. Klik "+ Pilih Produk" di atas.',
                                  style: TextStyle(color: Color(0xFF64748B)),
                                ),
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _items.length,
                              separatorBuilder: (_, _) => const Divider(height: 1),
                              itemBuilder: (context, idx) {
                                final item = _items[idx];
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: CircleAvatar(
                                    backgroundColor: const Color(0xFF16A34A).withAlpha(25),
                                    child: const Icon(Icons.add, color: Color(0xFF16A34A)),
                                  ),
                                  title: Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('${item.productSku} • Biaya: ${Formatters.currency(item.unitCost)}'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '+${Formatters.number(item.quantity)} ${item.productUnit}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Color(0xFF16A34A),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                                        onPressed: () {
                                          setState(() => _items.removeAt(idx));
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _isPosting ? null : _submitStockIn,
                    icon: _isPosting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: Text(
                      _isPosting ? 'Memproses Transaksi...' : 'Simpan & Tambah Stok',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

