import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/providers/app_providers.dart';
import '../../core/utils/formatters.dart';
import '../../shared/models/product.dart';
import '../../shared/models/stock_transaction.dart';

class StockOutScreen extends ConsumerStatefulWidget {
  const StockOutScreen({super.key});

  @override
  ConsumerState<StockOutScreen> createState() => _StockOutScreenState();
}

class _StockOutScreenState extends ConsumerState<StockOutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _docNumberController = TextEditingController();
  final _recipientController = TextEditingController();
  final _catatanController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String? _selectedWarehouseId;
  String? _selectedCustomerId;

  final List<StockTransactionItem> _items = [];
  bool _isPosting = false;

  @override
  void dispose() {
    _docNumberController.dispose();
    _recipientController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  void _showAddProductDialog() async {
    if (_selectedWarehouseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih gudang asal terlebih dahulu')),
      );
      return;
    }

    final products = await ref.read(productsProvider.future);
    final service = ref.read(supabaseServiceProvider);
    if (!mounted) return;

    Product? selectedProduct;
    double currentWarehouseStock = 0;
    final qtyController = TextEditingController(text: '1');
    String? stockErrorMessage;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Pilih Produk Keluar'),
            content: SizedBox(
              width: 450,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
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
                    onChanged: (p) async {
                      if (p != null) {
                        final stock = await service.getStock(p.id, _selectedWarehouseId!);
                        setDialogState(() {
                          selectedProduct = p;
                          currentWarehouseStock = stock;
                          stockErrorMessage = null;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  if (selectedProduct != null)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: currentWarehouseStock > 0 ? const Color(0xFFF1F5F9) : const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Stok Tersedia di Gudang:', style: TextStyle(fontSize: 12)),
                          Text(
                            '${Formatters.number(currentWarehouseStock)} ${selectedProduct!.unit}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: currentWarehouseStock > 0 ? const Color(0xFF0F172A) : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: qtyController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Jumlah Keluar (${selectedProduct?.unit ?? "pcs"})',
                      prefixIcon: const Icon(Icons.remove_shopping_cart),
                      errorText: stockErrorMessage,
                    ),
                    onChanged: (val) {
                      final entered = double.tryParse(val) ?? 0;
                      if (entered > currentWarehouseStock) {
                        setDialogState(() {
                          stockErrorMessage = 'Jumlah melebihi stok tersedia (${Formatters.number(currentWarehouseStock)})!';
                        });
                      } else {
                        setDialogState(() => stockErrorMessage = null);
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEA580C)),
                onPressed: () {
                  if (selectedProduct == null) return;
                  final qty = double.tryParse(qtyController.text) ?? 0;
                  if (qty <= 0) return;

                  if (qty > currentWarehouseStock) {
                    setDialogState(() {
                      stockErrorMessage = 'Stok tidak mencukupi!';
                    });
                    return;
                  }

                  setState(() {
                    _items.add(
                      StockTransactionItem(
                        productId: selectedProduct!.id,
                        productName: selectedProduct!.nama,
                        productSku: selectedProduct!.sku,
                        productUnit: selectedProduct!.unit,
                        quantity: qty,
                        unitCost: selectedProduct!.costPrice,
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

  Future<void> _submitStockOut() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedWarehouseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih gudang asal pengeluaran barang')),
      );
      return;
    }

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tambahkan minimal satu produk keluar')),
      );
      return;
    }

    // Confirm dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Pengeluaran Barang'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total jenis produk: ${_items.length} item'),
            Text('Total kuantitas keluar: ${Formatters.number(_items.fold(0.0, (acc, i) => acc + i.quantity))}'),
            const SizedBox(height: 12),
            const Text(
              'Stok akan berkurang secara atomik di sistem setelah dikonfirmasi.',
              style: TextStyle(color: Color(0xFFEA580C), fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEA580C)),
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
        tipe: 'OUT',
        warehouseId: _selectedWarehouseId!,
        customerId: _selectedCustomerId,
        recipient: _recipientController.text.trim(),
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
            backgroundColor: const Color(0xFFEA580C),
            content: Text('Barang Keluar berhasil diposting! No: $txNumber'),
          ),
        );
        context.go('/inventory');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red, content: Text('Gagal pengeluaran stok: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final warehousesAsync = ref.watch(warehousesProvider);
    final customersAsync = ref.watch(customersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pencatatan Barang Keluar (Stock Out)'),
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
                            'Informasi Pengeluaran Barang',
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
                                        labelText: 'Gudang Asal *',
                                        prefixIcon: Icon(Icons.warehouse_outlined),
                                      ),
                                      items: warehouses.map((w) {
                                        return DropdownMenuItem(value: w.id, child: Text(w.nama));
                                      }).toList(),
                                      onChanged: (val) {
                                        setState(() {
                                          _selectedWarehouseId = val;
                                          _items.clear(); // Reset items because stock depends on warehouse
                                        });
                                      },
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

                          // Customer & Recipient Row
                          Row(
                            children: [
                              Expanded(
                                child: customersAsync.when(
                                  data: (customers) => DropdownButtonFormField<String?>(
                                    initialValue: _selectedCustomerId,
                                    decoration: const InputDecoration(
                                      labelText: 'Pelanggan / Customer',
                                      prefixIcon: Icon(Icons.person_outline),
                                    ),
                                    items: [
                                      const DropdownMenuItem(value: null, child: Text('-- Pilih Pelanggan --')),
                                      ...customers.map((c) => DropdownMenuItem(value: c.id, child: Text(c.nama))),
                                    ],
                                    onChanged: (val) => setState(() => _selectedCustomerId = val),
                                  ),
                                  loading: () => const LinearProgressIndicator(),
                                  error: (_, _) => const SizedBox.shrink(),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: _recipientController,
                                  decoration: const InputDecoration(
                                    labelText: 'Penerima / Tujuan Kirim',
                                    hintText: 'Nama cabang/penerima',
                                    prefixIcon: Icon(Icons.local_shipping_outlined),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Document number & Notes
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _docNumberController,
                                  decoration: const InputDecoration(
                                    labelText: 'Nomor Delivery Order (DO)',
                                    hintText: 'DO-2026-001',
                                    prefixIcon: Icon(Icons.receipt_long),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: _catatanController,
                                  decoration: const InputDecoration(
                                    labelText: 'Catatan Pengeluaran',
                                    prefixIcon: Icon(Icons.notes),
                                  ),
                                ),
                              ),
                            ],
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
                                'Daftar Barang Keluar',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEA580C)),
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
                                    backgroundColor: const Color(0xFFEA580C).withAlpha(25),
                                    child: const Icon(Icons.remove, color: Color(0xFFEA580C)),
                                  ),
                                  title: Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text(item.productSku),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '-${Formatters.number(item.quantity)} ${item.productUnit}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Color(0xFFEA580C),
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
                      backgroundColor: const Color(0xFFEA580C),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _isPosting ? null : _submitStockOut,
                    icon: _isPosting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: Text(
                      _isPosting ? 'Memproses Pengeluaran...' : 'Simpan & Kurangi Stok',
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

