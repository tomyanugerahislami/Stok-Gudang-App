import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/providers/app_providers.dart';
import '../../core/utils/formatters.dart';
import '../../shared/models/product.dart';

class ProductFormScreen extends ConsumerStatefulWidget {
  final Product? productToEdit;

  const ProductFormScreen({super.key, this.productToEdit});

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _skuController;
  late final TextEditingController _nameController;
  late final TextEditingController _barcodeController;
  late final TextEditingController _unitController;
  late final TextEditingController _minimumStockController;
  late final TextEditingController _costPriceController;

  String? _selectedCategoryId;
  String _status = 'active';
  bool _isSaving = false;

  final List<String> _commonUnits = ['pcs', 'unit', 'box', 'karton', 'roll', 'kg', 'meter', 'liter', 'pack'];

  @override
  void initState() {
    super.initState();
    final p = widget.productToEdit;
    _skuController = TextEditingController(text: p?.sku ?? Formatters.generateSKU());
    _nameController = TextEditingController(text: p?.nama ?? '');
    _barcodeController = TextEditingController(text: p?.barcode ?? Formatters.generateBarcode());
    _unitController = TextEditingController(text: p?.unit ?? 'pcs');
    _minimumStockController = TextEditingController(text: p != null ? p.minimumStock.toString() : '5');
    _costPriceController = TextEditingController(text: p != null ? p.costPrice.toStringAsFixed(0) : '0');
    _selectedCategoryId = p?.categoryId;
    _status = p?.status ?? 'active';
  }

  @override
  void dispose() {
    _skuController.dispose();
    _nameController.dispose();
    _barcodeController.dispose();
    _unitController.dispose();
    _minimumStockController.dispose();
    _costPriceController.dispose();
    super.dispose();
  }

  void _generateNewBarcode() {
    setState(() {
      _barcodeController.text = Formatters.generateBarcode();
    });
  }

  void _generateNewSKU() {
    setState(() {
      _skuController.text = Formatters.generateSKU();
    });
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final product = Product(
        id: widget.productToEdit?.id ?? '',
        sku: _skuController.text.trim(),
        nama: _nameController.text.trim(),
        categoryId: _selectedCategoryId,
        unit: _unitController.text.trim(),
        barcode: _barcodeController.text.trim(),
        minimumStock: double.tryParse(_minimumStockController.text) ?? 0,
        costPrice: double.tryParse(_costPriceController.text) ?? 0,
        status: _status,
        currentStock: widget.productToEdit?.currentStock ?? 0,
      );

      final service = ref.read(supabaseServiceProvider);
      await service.saveProduct(product);

      ref.invalidate(productsProvider);
      ref.invalidate(inventoryProvider);
      ref.invalidate(dashboardMetricsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.productToEdit == null
                  ? 'Produk berhasil ditambahkan'
                  : 'Produk berhasil diperbarui',
            ),
          ),
        );
        context.go('/products');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Gagal menyimpan produk: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final isEditing = widget.productToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Produk' : 'Tambah Produk Baru'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/products'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEditing ? 'Perbarui Data Produk' : 'Informasi Master Produk',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Pastikan SKU dan Barcode unik untuk mencegah kesalahan identifikasi stok.',
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                      ),
                      const Divider(height: 32),

                      // Nama Produk
                      TextFormField(
                        key: const Key('input_product_name'),
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nama Produk *',
                          hintText: 'Contoh: Scanner Barcode Wireless 2D',
                          prefixIcon: Icon(Icons.inventory_2_outlined),
                        ),
                        validator: (val) =>
                            val == null || val.trim().isEmpty ? 'Nama produk wajib diisi' : null,
                      ),
                      const SizedBox(height: 16),

                      // SKU & Barcode Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              key: const Key('input_product_sku'),
                              controller: _skuController,
                              decoration: InputDecoration(
                                labelText: 'SKU / Kode Produk *',
                                prefixIcon: const Icon(Icons.tag),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.refresh, size: 20),
                                  tooltip: 'Generate SKU Otomatis',
                                  onPressed: _generateNewSKU,
                                ),
                              ),
                              validator: (val) =>
                                  val == null || val.trim().isEmpty ? 'SKU wajib diisi' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              key: const Key('input_product_barcode'),
                              controller: _barcodeController,
                              decoration: InputDecoration(
                                labelText: 'Barcode (Code 128 / EAN) *',
                                prefixIcon: const Icon(Icons.qr_code),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.auto_fix_high, size: 20),
                                  tooltip: 'Generate Barcode Otomatis',
                                  onPressed: _generateNewBarcode,
                                ),
                              ),
                              validator: (val) =>
                                  val == null || val.trim().isEmpty ? 'Barcode wajib diisi' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Category Dropdown
                      categoriesAsync.when(
                        data: (categories) => DropdownButtonFormField<String?>(
                          initialValue: _selectedCategoryId,
                          decoration: const InputDecoration(
                            labelText: 'Kategori Produk',
                            prefixIcon: Icon(Icons.category_outlined),
                          ),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('-- Pilih Kategori --')),
                            ...categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.nama))),
                          ],
                          onChanged: (val) => setState(() => _selectedCategoryId = val),
                        ),
                        loading: () => const LinearProgressIndicator(),
                        error: (_, _) => const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 16),

                      // Unit & Minimum Stock Row
                      Row(
                        children: [
                          Expanded(
                            child: Autocomplete<String>(
                              initialValue: TextEditingValue(text: _unitController.text),
                              optionsBuilder: (textVal) {
                                if (textVal.text.isEmpty) return _commonUnits;
                                return _commonUnits.where((u) => u.toLowerCase().contains(textVal.text.toLowerCase()));
                              },
                              onSelected: (val) => _unitController.text = val,
                              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                                controller.addListener(() {
                                  _unitController.text = controller.text;
                                });
                                return TextFormField(
                                  controller: controller,
                                  focusNode: focusNode,
                                  decoration: const InputDecoration(
                                    labelText: 'Satuan Unit *',
                                    hintText: 'pcs, box, unit...',
                                    prefixIcon: Icon(Icons.straighten),
                                  ),
                                  validator: (val) =>
                                      val == null || val.trim().isEmpty ? 'Satuan wajib diisi' : null,
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _minimumStockController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Stok Minimum Peringatan *',
                                prefixIcon: Icon(Icons.warning_amber),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return 'Wajib diisi';
                                if (double.tryParse(val) == null) return 'Harus angka';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Cost Price & Status Row
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _costPriceController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Harga Modal (Rp)',
                                prefixIcon: Icon(Icons.payments_outlined),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _status,
                              decoration: const InputDecoration(
                                labelText: 'Status Produk',
                                prefixIcon: Icon(Icons.toggle_on_outlined),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'active', child: Text('Aktif')),
                                DropdownMenuItem(value: 'inactive', child: Text('Nonaktif')),
                                DropdownMenuItem(value: 'archived', child: Text('Arsip')),
                              ],
                              onChanged: (val) {
                                if (val != null) setState(() => _status = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            key: const Key('btn_cancel_product'),
                            onPressed: () => context.go('/products'),
                            child: const Text('Batal'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            key: const Key('btn_save_product'),
                            onPressed: _isSaving ? null : _saveProduct,
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.save),
                            label: Text(_isSaving ? 'Menyimpan...' : 'Simpan Produk'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

