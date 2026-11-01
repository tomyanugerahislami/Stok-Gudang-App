import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../../shared/models/user_profile.dart';
import '../../shared/models/warehouse.dart';
import '../../shared/models/category.dart';
import '../../shared/models/product.dart';
import '../../shared/models/party.dart';
import '../../shared/models/inventory_item.dart';
import '../../shared/models/stock_transaction.dart';
import '../../shared/models/stock_opname.dart';
import '../utils/formatters.dart';

class SupabaseService {
  static final SupabaseService instance = SupabaseService._internal();
  SupabaseService._internal();

  SupabaseClient? get _client =>
      SupabaseConfig.isConfigured ? SupabaseConfig.client : null;

  // --- In-Memory Mock Store for Offline / Demo Mode ---
  final List<UserProfile> _mockProfiles = [
    UserProfile(
      id: 'demo-admin-id',
      email: 'admin@stokgudang.com',
      nama: 'Budi Santoso (Admin)',
      role: 'Admin',
      status: 'active',
    ),
    UserProfile(
      id: 'demo-staff-id',
      email: 'staff@stokgudang.com',
      nama: 'Siti Rahma (Staff)',
      role: 'Staff Gudang',
      status: 'active',
    ),
    UserProfile(
      id: 'demo-manager-id',
      email: 'manager@stokgudang.com',
      nama: 'Ahmad Fauzi (Manager)',
      role: 'Manager',
      status: 'active',
    ),
  ];

  UserProfile? _currentMockUser;

  final List<Warehouse> _mockWarehouses = [
    Warehouse(
      id: 'wh-01',
      kode: 'GDG-01',
      nama: 'Gudang Utama Jakarta',
      alamat: 'Jl. Industri Raya No. 10',
    ),
    Warehouse(
      id: 'wh-02',
      kode: 'GDG-02',
      nama: 'Gudang Transit Bekasi',
      alamat: 'Kawasan Industri MM2100',
    ),
  ];

  final List<ProductCategory> _mockCategories = [
    ProductCategory(
      id: 'cat-01',
      nama: 'Elektronik & Sparepart',
      deskripsi: 'Perangkat barcode dan elektronik',
    ),
    ProductCategory(
      id: 'cat-02',
      nama: 'Alat Tulis Kantor',
      deskripsi: 'Kebutuhan ATK',
    ),
    ProductCategory(
      id: 'cat-03',
      nama: 'Bahan Baku & Material',
      deskripsi: 'Kemasan dan material kardus',
    ),
  ];

  final List<Supplier> _mockSuppliers = [
    Supplier(
      id: 'sup-01',
      nama: 'PT Maju Logistik Sentosa',
      kontak: '081234567890',
      alamat: 'Jl. Gatot Subroto No. 45',
    ),
    Supplier(
      id: 'sup-02',
      nama: 'CV Sumber Makmur Abadi',
      kontak: '081398765432',
      alamat: 'Jl. Raya Bogor KM 28',
    ),
  ];

  final List<Customer> _mockCustomers = [
    Customer(
      id: 'cust-01',
      nama: 'Toko Berkah Sejahtera',
      kontak: '082111223344',
      alamat: 'Pasar Tanah Abang',
    ),
    Customer(
      id: 'cust-02',
      nama: 'PT Cipta Kreasi Digital',
      kontak: '085712349988',
      alamat: 'Wisma Antara Lt. 8',
    ),
  ];

  final List<Product> _mockProducts = [
    Product(
      id: 'prod-01',
      sku: 'PRD-ELK-001',
      nama: 'Scanner Barcode Wireless 2D',
      categoryId: 'cat-01',
      categoryName: 'Elektronik & Sparepart',
      unit: 'unit',
      barcode: '899100100001',
      minimumStock: 5,
      costPrice: 450000,
      status: 'active',
      currentStock: 18,
    ),
    Product(
      id: 'prod-02',
      sku: 'PRD-ELK-002',
      nama: 'Thermal Label Printer 80mm',
      categoryId: 'cat-01',
      categoryName: 'Elektronik & Sparepart',
      unit: 'unit',
      barcode: '899100100002',
      minimumStock: 5,
      costPrice: 850000,
      status: 'active',
      currentStock: 4, // Low stock
    ),
    Product(
      id: 'prod-03',
      sku: 'PRD-ATK-001',
      nama: 'Kertas Thermal Roll 80x80',
      categoryId: 'cat-02',
      categoryName: 'Alat Tulis Kantor',
      unit: 'roll',
      barcode: '899100100003',
      minimumStock: 20,
      costPrice: 15000,
      status: 'active',
      currentStock: 85,
    ),
    Product(
      id: 'prod-04',
      sku: 'PRD-MAT-001',
      nama: 'Kardus Packing Karton Double Wall',
      categoryId: 'cat-03',
      categoryName: 'Bahan Baku & Material',
      unit: 'pcs',
      barcode: '899100100004',
      minimumStock: 50,
      costPrice: 8500,
      status: 'active',
      currentStock: 120,
    ),
    Product(
      id: 'prod-05',
      sku: 'PRD-MAT-002',
      nama: 'Lakban Fragile 48mm x 100m',
      categoryId: 'cat-03',
      categoryName: 'Bahan Baku & Material',
      unit: 'roll',
      barcode: '899100100005',
      minimumStock: 15,
      costPrice: 12000,
      status: 'active',
      currentStock: 8, // Low stock
    ),
  ];

  final List<InventoryItem> _mockInventory = [
    InventoryItem(
      id: 'inv-01',
      productId: 'prod-01',
      productName: 'Scanner Barcode Wireless 2D',
      productSku: 'PRD-ELK-001',
      productUnit: 'unit',
      barcode: '899100100001',
      warehouseId: 'wh-01',
      warehouseName: 'Gudang Utama Jakarta',
      quantity: 18,
      minimumStock: 5,
    ),
    InventoryItem(
      id: 'inv-02',
      productId: 'prod-02',
      productName: 'Thermal Label Printer 80mm',
      productSku: 'PRD-ELK-002',
      productUnit: 'unit',
      barcode: '899100100002',
      warehouseId: 'wh-01',
      warehouseName: 'Gudang Utama Jakarta',
      quantity: 4,
      minimumStock: 5,
    ),
    InventoryItem(
      id: 'inv-03',
      productId: 'prod-03',
      productName: 'Kertas Thermal Roll 80x80',
      productSku: 'PRD-ATK-001',
      productUnit: 'roll',
      barcode: '899100100003',
      warehouseId: 'wh-01',
      warehouseName: 'Gudang Utama Jakarta',
      quantity: 85,
      minimumStock: 20,
    ),
    InventoryItem(
      id: 'inv-04',
      productId: 'prod-04',
      productName: 'Kardus Packing Karton Double Wall',
      productSku: 'PRD-MAT-001',
      productUnit: 'pcs',
      barcode: '899100100004',
      warehouseId: 'wh-01',
      warehouseName: 'Gudang Utama Jakarta',
      quantity: 120,
      minimumStock: 50,
    ),
    InventoryItem(
      id: 'inv-05',
      productId: 'prod-05',
      productName: 'Lakban Fragile 48mm x 100m',
      productSku: 'PRD-MAT-002',
      productUnit: 'roll',
      barcode: '899100100005',
      warehouseId: 'wh-01',
      warehouseName: 'Gudang Utama Jakarta',
      quantity: 8,
      minimumStock: 15,
    ),
  ];

  final List<StockTransaction> _mockTransactions = [
    StockTransaction(
      id: 'tx-01',
      nomorTransaksi: 'TRX-IN-20261101-001',
      tipe: 'IN',
      warehouseId: 'wh-01',
      warehouseName: 'Gudang Utama Jakarta',
      supplierId: 'sup-01',
      supplierName: 'PT Maju Logistik Sentosa',
      documentNumber: 'SJ-2026-9901',
      tanggal: DateTime.now().subtract(const Duration(days: 3)),
      status: 'COMPLETED',
      catatan: 'Pengiriman batch pertama scanner & printer',
      createdBy: 'demo-admin-id',
      creatorName: 'Budi Santoso (Admin)',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      items: [
        StockTransactionItem(
          productId: 'prod-01',
          productName: 'Scanner Barcode Wireless 2D',
          productSku: 'PRD-ELK-001',
          quantity: 20,
          unitCost: 450000,
        ),
        StockTransactionItem(
          productId: 'prod-02',
          productName: 'Thermal Label Printer 80mm',
          productSku: 'PRD-ELK-002',
          quantity: 5,
          unitCost: 850000,
        ),
      ],
    ),
    StockTransaction(
      id: 'tx-02',
      nomorTransaksi: 'TRX-OUT-20261103-002',
      tipe: 'OUT',
      warehouseId: 'wh-01',
      warehouseName: 'Gudang Utama Jakarta',
      customerId: 'cust-01',
      customerName: 'Toko Berkah Sejahtera',
      documentNumber: 'DO-2026-1044',
      tanggal: DateTime.now().subtract(const Duration(days: 1)),
      status: 'COMPLETED',
      catatan: 'Pesanan unit scanner Toko Berkah',
      createdBy: 'demo-staff-id',
      creatorName: 'Siti Rahma (Staff)',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      items: [
        StockTransactionItem(
          productId: 'prod-01',
          productName: 'Scanner Barcode Wireless 2D',
          productSku: 'PRD-ELK-001',
          quantity: 2,
          unitCost: 450000,
        ),
        StockTransactionItem(
          productId: 'prod-02',
          productName: 'Thermal Label Printer 80mm',
          productSku: 'PRD-ELK-002',
          quantity: 1,
          unitCost: 850000,
        ),
      ],
    ),
  ];

  final List<StockOpname> _mockOpnames = [];

  // =================================================================
  // AUTHENTICATION & PROFILES
  // =================================================================

  Future<UserProfile?> getCurrentProfile() async {
    final client = _client;
    if (client != null && client.auth.currentUser != null) {
      try {
        final userId = client.auth.currentUser!.id;
        final res = await client
            .from('profiles')
            .select()
            .eq('id', userId)
            .maybeSingle();
        if (res != null) {
          return UserProfile.fromJson(res);
        }
      } catch (e) {
        debugPrint("Error fetching profile from Supabase: $e");
      }
    }
    // Return mock user if in mock mode
    return _currentMockUser ?? _mockProfiles.first;
  }

  Future<void> signInWithEmail(String email, String password) async {
    final client = _client;
    if (client != null) {
      await client.auth.signInWithPassword(email: email, password: password);
    } else {
      // Offline/Mock Login
      final user = _mockProfiles.firstWhere(
        (p) => p.email.toLowerCase() == email.toLowerCase(),
        orElse: () => UserProfile(
          id: 'user-${DateTime.now().millisecondsSinceEpoch}',
          email: email,
          nama: email.split('@').first,
          role: 'Staff Gudang',
        ),
      );
      _currentMockUser = user;
    }
  }

  void switchMockRole(String role) {
    final user = _mockProfiles.firstWhere(
      (p) => p.role == role,
      orElse: () => _mockProfiles.first,
    );
    _currentMockUser = user;
  }

  Future<void> signOut() async {
    final client = _client;
    if (client != null) {
      await client.auth.signOut();
    }
    _currentMockUser = null;
  }

  Future<void> resetPassword(String email) async {
    final client = _client;
    if (client != null) {
      await client.auth.resetPasswordForEmail(email);
    }
  }

  Future<List<UserProfile>> getAllProfiles() async {
    final client = _client;
    if (client != null) {
      final res = await client.from('profiles').select().order('created_at');
      return (res as List).map((e) => UserProfile.fromJson(e)).toList();
    }
    return _mockProfiles;
  }

  Future<void> updateUserRole(String userId, String newRole) async {
    final client = _client;
    if (client != null) {
      await client.from('profiles').update({'role': newRole}).eq('id', userId);
    } else {
      final index = _mockProfiles.indexWhere((p) => p.id == userId);
      if (index != -1) {
        _mockProfiles[index] = _mockProfiles[index].copyWith(role: newRole);
      }
    }
  }

  // =================================================================
  // WAREHOUSES
  // =================================================================

  Future<List<Warehouse>> getWarehouses() async {
    final client = _client;
    if (client != null) {
      final res = await client
          .from('warehouses')
          .select()
          .eq('status', 'active')
          .order('nama');
      return (res as List).map((e) => Warehouse.fromJson(e)).toList();
    }
    return _mockWarehouses.where((w) => w.status == 'active').toList();
  }

  Future<Warehouse> createWarehouse(Warehouse warehouse) async {
    final client = _client;
    if (client != null) {
      final res = await client
          .from('warehouses')
          .insert(warehouse.toJson())
          .select()
          .single();
      return Warehouse.fromJson(res);
    }
    final newWh = Warehouse(
      id: 'wh-${DateTime.now().millisecondsSinceEpoch}',
      kode: warehouse.kode,
      nama: warehouse.nama,
      alamat: warehouse.alamat,
      status: warehouse.status,
    );
    _mockWarehouses.add(newWh);
    return newWh;
  }

  // =================================================================
  // CATEGORIES
  // =================================================================

  Future<List<ProductCategory>> getCategories() async {
    final client = _client;
    if (client != null) {
      final res = await client.from('categories').select().order('nama');
      return (res as List).map((e) => ProductCategory.fromJson(e)).toList();
    }
    return _mockCategories;
  }

  Future<ProductCategory> createCategory(String nama, String? deskripsi) async {
    final client = _client;
    if (client != null) {
      final res = await client
          .from('categories')
          .insert({'nama': nama, 'deskripsi': deskripsi})
          .select()
          .single();
      return ProductCategory.fromJson(res);
    }
    final newCat = ProductCategory(
      id: 'cat-${DateTime.now().millisecondsSinceEpoch}',
      nama: nama,
      deskripsi: deskripsi,
    );
    _mockCategories.add(newCat);
    return newCat;
  }

  // =================================================================
  // SUPPLIERS & CUSTOMERS
  // =================================================================

  Future<List<Supplier>> getSuppliers() async {
    final client = _client;
    if (client != null) {
      final res = await client.from('suppliers').select().order('nama');
      return (res as List).map((e) => Supplier.fromJson(e)).toList();
    }
    return _mockSuppliers;
  }

  Future<Supplier> createSupplier(Supplier s) async {
    final client = _client;
    if (client != null) {
      final res = await client
          .from('suppliers')
          .insert(s.toJson())
          .select()
          .single();
      return Supplier.fromJson(res);
    }
    final newSup = Supplier(
      id: 'sup-${DateTime.now().millisecondsSinceEpoch}',
      nama: s.nama,
      kontak: s.kontak,
      alamat: s.alamat,
    );
    _mockSuppliers.add(newSup);
    return newSup;
  }

  Future<List<Customer>> getCustomers() async {
    final client = _client;
    if (client != null) {
      final res = await client.from('customers').select().order('nama');
      return (res as List).map((e) => Customer.fromJson(e)).toList();
    }
    return _mockCustomers;
  }

  Future<Customer> createCustomer(Customer c) async {
    final client = _client;
    if (client != null) {
      final res = await client
          .from('customers')
          .insert(c.toJson())
          .select()
          .single();
      return Customer.fromJson(res);
    }
    final newCust = Customer(
      id: 'cust-${DateTime.now().millisecondsSinceEpoch}',
      nama: c.nama,
      kontak: c.kontak,
      alamat: c.alamat,
    );
    _mockCustomers.add(newCust);
    return newCust;
  }

  // =================================================================
  // PRODUCTS
  // =================================================================

  Future<List<Product>> getProducts({
    String? query,
    String? categoryId,
    String? status,
  }) async {
    final client = _client;
    if (client != null) {
      var q = client.from('products').select('''
        *,
        categories (nama),
        inventory (quantity)
      ''');

      if (status != null && status.isNotEmpty) {
        q = q.eq('status', status);
      }
      if (categoryId != null && categoryId.isNotEmpty) {
        q = q.eq('category_id', categoryId);
      }

      final res = await q.order('nama');
      final list = (res as List).map((e) {
        // Calculate total stock across warehouses
        final invList = e['inventory'] as List<dynamic>? ?? [];
        double totalStock = 0;
        for (var inv in invList) {
          totalStock += (inv['quantity'] as num?)?.toDouble() ?? 0.0;
        }
        final prodMap = Map<String, dynamic>.from(e);
        prodMap['current_stock'] = totalStock;
        return Product.fromJson(prodMap);
      }).toList();

      if (query != null && query.trim().isNotEmpty) {
        final lower = query.toLowerCase().trim();
        return list
            .where(
              (p) =>
                  p.nama.toLowerCase().contains(lower) ||
                  p.sku.toLowerCase().contains(lower) ||
                  p.barcode.toLowerCase().contains(lower),
            )
            .toList();
      }
      return list;
    }

    // Mock Mode
    var list = List<Product>.from(_mockProducts);
    if (status != null && status.isNotEmpty) {
      list = list.where((p) => p.status == status).toList();
    }
    if (categoryId != null && categoryId.isNotEmpty) {
      list = list.where((p) => p.categoryId == categoryId).toList();
    }
    if (query != null && query.trim().isNotEmpty) {
      final lower = query.toLowerCase().trim();
      list = list
          .where(
            (p) =>
                p.nama.toLowerCase().contains(lower) ||
                p.sku.toLowerCase().contains(lower) ||
                p.barcode.toLowerCase().contains(lower),
          )
          .toList();
    }
    return list;
  }

  Future<Product?> getProductByBarcode(String barcode) async {
    final client = _client;
    if (client != null) {
      final res = await client
          .from('products')
          .select('*, categories(nama)')
          .eq('barcode', barcode.trim())
          .maybeSingle();
      if (res != null) {
        return Product.fromJson(res);
      }
      return null;
    }
    try {
      return _mockProducts.firstWhere((p) => p.barcode == barcode.trim());
    } catch (_) {
      return null;
    }
  }

  Future<Product> saveProduct(Product product) async {
    final client = _client;
    if (client != null) {
      if (product.id.isEmpty) {
        final res = await client
            .from('products')
            .insert(product.toJson())
            .select('*, categories(nama)')
            .single();
        return Product.fromJson(res);
      } else {
        final res = await client
            .from('products')
            .update(product.toJson())
            .eq('id', product.id)
            .select('*, categories(nama)')
            .single();
        return Product.fromJson(res);
      }
    }

    // Mock Mode
    if (product.id.isEmpty) {
      String? catName;
      if (product.categoryId != null) {
        try {
          catName = _mockCategories
              .firstWhere((c) => c.id == product.categoryId)
              .nama;
        } catch (_) {}
      }
      final newProd = product.copyWith(
        id: 'prod-${DateTime.now().millisecondsSinceEpoch}',
        categoryName:
            catName ??
            (_mockCategories.isNotEmpty ? _mockCategories.first.nama : null),
      );
      _mockProducts.add(newProd);
      return newProd;
    } else {
      final idx = _mockProducts.indexWhere((p) => p.id == product.id);
      if (idx != -1) {
        _mockProducts[idx] = product;
        return product;
      }
      _mockProducts.add(product);
      return product;
    }
  }

  Future<bool> hasProductTransactions(String productId) async {
    final client = _client;
    if (client != null) {
      final res = await client
          .from('stock_transaction_items')
          .select('id')
          .eq('product_id', productId)
          .limit(1);
      return (res as List).isNotEmpty;
    }
    return _mockTransactions.any(
      (tx) => tx.items.any((item) => item.productId == productId),
    );
  }

  Future<void> archiveProduct(String productId) async {
    final client = _client;
    if (client != null) {
      await client
          .from('products')
          .update({'status': 'archived'})
          .eq('id', productId);
    } else {
      final idx = _mockProducts.indexWhere((p) => p.id == productId);
      if (idx != -1) {
        _mockProducts[idx] = _mockProducts[idx].copyWith(status: 'archived');
      }
    }
  }

  // =================================================================
  // INVENTORY & STOCK
  // =================================================================

  Future<List<InventoryItem>> getInventory({String? warehouseId}) async {
    final client = _client;
    if (client != null) {
      var q = client.from('inventory').select('''
        id,
        quantity,
        updated_at,
        products (id, nama, sku, unit, barcode, minimum_stock),
        warehouses (id, nama)
      ''');

      if (warehouseId != null && warehouseId.isNotEmpty) {
        q = q.eq('warehouse_id', warehouseId);
      }

      final res = await q.order('updated_at', ascending: false);
      return (res as List).map((e) => InventoryItem.fromJson(e)).toList();
    }

    // Mock Mode
    if (warehouseId != null && warehouseId.isNotEmpty) {
      return _mockInventory.where((i) => i.warehouseId == warehouseId).toList();
    }
    return _mockInventory;
  }

  Future<double> getStock(String productId, String warehouseId) async {
    final client = _client;
    if (client != null) {
      final res = await client
          .from('inventory')
          .select('quantity')
          .eq('product_id', productId)
          .eq('warehouse_id', warehouseId)
          .maybeSingle();
      if (res != null) {
        return (res['quantity'] as num?)?.toDouble() ?? 0.0;
      }
      return 0.0;
    }

    final item = _mockInventory.firstWhere(
      (i) => i.productId == productId && i.warehouseId == warehouseId,
      orElse: () => InventoryItem(
        id: '',
        productId: productId,
        productName: '',
        productSku: '',
        productUnit: '',
        barcode: '',
        warehouseId: warehouseId,
        warehouseName: '',
        quantity: 0,
      ),
    );
    return item.quantity;
  }

  // =================================================================
  // TRANSACTIONS (IN / OUT / ADJUSTMENT)
  // =================================================================

  Future<List<StockTransaction>> getTransactions({
    String? tipe,
    String? warehouseId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final client = _client;
    if (client != null) {
      var q = client.from('stock_transactions').select('''
        *,
        warehouses!stock_transactions_warehouse_id_fkey (nama),
        to_warehouse:warehouses!stock_transactions_to_warehouse_id_fkey (nama),
        suppliers (nama),
        customers (nama),
        stock_transaction_items (
          id, quantity, unit_cost, notes,
          products (id, nama, sku, unit)
        )
      ''');

      if (tipe != null && tipe.isNotEmpty) {
        q = q.eq('tipe', tipe);
      }
      if (warehouseId != null && warehouseId.isNotEmpty) {
        q = q.eq('warehouse_id', warehouseId);
      }
      if (startDate != null) {
        q = q.gte('tanggal', Formatters.dateIso(startDate));
      }
      if (endDate != null) {
        q = q.lte('tanggal', Formatters.dateIso(endDate));
      }

      final res = await q.order('created_at', ascending: false);
      return (res as List).map((e) => StockTransaction.fromJson(e)).toList();
    }

    // Mock Mode
    var list = List<StockTransaction>.from(_mockTransactions);
    if (tipe != null && tipe.isNotEmpty) {
      list = list.where((t) => t.tipe == tipe).toList();
    }
    if (warehouseId != null && warehouseId.isNotEmpty) {
      list = list.where((t) => t.warehouseId == warehouseId).toList();
    }
    if (startDate != null) {
      list = list
          .where(
            (t) =>
                t.tanggal.isAfter(startDate.subtract(const Duration(days: 1))),
          )
          .toList();
    }
    if (endDate != null) {
      list = list
          .where(
            (t) => t.tanggal.isBefore(endDate.add(const Duration(days: 1))),
          )
          .toList();
    }
    return list;
  }

  Future<String> createAndPostTransaction({
    required String tipe, // 'IN', 'OUT', 'ADJUSTMENT', 'TRANSFER'
    required String warehouseId,
    String? toWarehouseId,
    String? supplierId,
    String? customerId,
    String? recipient,
    String? documentNumber,
    required DateTime tanggal,
    String? catatan,
    required List<StockTransactionItem> items,
  }) async {
    final client = _client;
    final txNumber = Formatters.generateTransactionNumber(tipe);

    if (client != null) {
      final userId = client.auth.currentUser?.id;

      // 1. Insert header as DRAFT
      final txRes = await client
          .from('stock_transactions')
          .insert({
            'nomor_transaksi': txNumber,
            'tipe': tipe,
            'warehouse_id': warehouseId,
            'to_warehouse_id': toWarehouseId,
            'supplier_id': supplierId,
            'customer_id': customerId,
            'recipient': recipient,
            'document_number': documentNumber,
            'tanggal': Formatters.dateIso(tanggal),
            'status': 'DRAFT',
            'catatan': catatan,
            'created_by': userId,
          })
          .select()
          .single();

      final String txId = txRes['id'];

      // 2. Insert items
      final itemsPayload = items
          .map(
            (i) => {
              'transaction_id': txId,
              'product_id': i.productId,
              'quantity': i.quantity,
              'unit_cost': i.unitCost,
              'notes': i.notes,
            },
          )
          .toList();

      await client.from('stock_transaction_items').insert(itemsPayload);

      // 3. Post transaction atomically via RPC
      await client.rpc(
        'post_stock_transaction',
        params: {'p_transaction_id': txId},
      );

      return txNumber;
    }

    // Mock Mode: Apply logic directly
    for (var item in items) {
      final currentStock = await getStock(item.productId, warehouseId);
      if (tipe == 'OUT' && currentStock < item.quantity) {
        throw Exception(
          'Stok tidak mencukupi untuk ${item.productName}. Tersedia: $currentStock, diminta: ${item.quantity}',
        );
      }
    }

    // Apply stock adjustments in mock
    for (var item in items) {
      final invIndex = _mockInventory.indexWhere(
        (i) => i.productId == item.productId && i.warehouseId == warehouseId,
      );
      double current = invIndex != -1 ? _mockInventory[invIndex].quantity : 0;
      double newQty = current;

      if (tipe == 'IN') {
        newQty = current + item.quantity;
      } else if (tipe == 'OUT') {
        newQty = current - item.quantity;
      }

      final prod = _mockProducts.firstWhere((p) => p.id == item.productId);
      final wh = _mockWarehouses.firstWhere((w) => w.id == warehouseId);

      if (invIndex != -1) {
        _mockInventory[invIndex] = InventoryItem(
          id: _mockInventory[invIndex].id,
          productId: prod.id,
          productName: prod.nama,
          productSku: prod.sku,
          productUnit: prod.unit,
          barcode: prod.barcode,
          warehouseId: wh.id,
          warehouseName: wh.nama,
          quantity: newQty,
          minimumStock: prod.minimumStock,
          updatedAt: DateTime.now(),
        );
      } else {
        _mockInventory.add(
          InventoryItem(
            id: 'inv-${DateTime.now().millisecondsSinceEpoch}',
            productId: prod.id,
            productName: prod.nama,
            productSku: prod.sku,
            productUnit: prod.unit,
            barcode: prod.barcode,
            warehouseId: wh.id,
            warehouseName: wh.nama,
            quantity: newQty,
            minimumStock: prod.minimumStock,
            updatedAt: DateTime.now(),
          ),
        );
      }

      // Update product current stock
      final pIndex = _mockProducts.indexWhere((p) => p.id == item.productId);
      if (pIndex != -1) {
        _mockProducts[pIndex] = _mockProducts[pIndex].copyWith(
          currentStock:
              _mockProducts[pIndex].currentStock +
              (tipe == 'IN' ? item.quantity : -item.quantity),
        );
      }
    }

    final newTx = StockTransaction(
      id: 'tx-${DateTime.now().millisecondsSinceEpoch}',
      nomorTransaksi: txNumber,
      tipe: tipe,
      warehouseId: warehouseId,
      warehouseName: _mockWarehouses
          .firstWhere(
            (w) => w.id == warehouseId,
            orElse: () => _mockWarehouses.first,
          )
          .nama,
      supplierId: supplierId,
      supplierName: supplierId != null
          ? _mockSuppliers
                .firstWhere(
                  (s) => s.id == supplierId,
                  orElse: () => _mockSuppliers.first,
                )
                .nama
          : null,
      customerId: customerId,
      customerName: customerId != null
          ? _mockCustomers
                .firstWhere(
                  (c) => c.id == customerId,
                  orElse: () => _mockCustomers.first,
                )
                .nama
          : null,
      recipient: recipient,
      documentNumber: documentNumber,
      tanggal: tanggal,
      status: 'COMPLETED',
      catatan: catatan,
      createdBy: _currentMockUser?.id ?? 'demo-user',
      creatorName: _currentMockUser?.nama ?? 'Staff Demo',
      createdAt: DateTime.now(),
      items: items,
    );

    _mockTransactions.insert(0, newTx);
    return txNumber;
  }

  Future<void> cancelTransaction(String transactionId, String reason) async {
    final client = _client;
    if (client != null) {
      await client.rpc(
        'cancel_stock_transaction',
        params: {'p_transaction_id': transactionId, 'p_reason': reason},
      );
    } else {
      final idx = _mockTransactions.indexWhere((t) => t.id == transactionId);
      if (idx != -1) {
        final tx = _mockTransactions[idx];
        // Revert stock
        for (var item in tx.items) {
          final invIdx = _mockInventory.indexWhere(
            (i) =>
                i.productId == item.productId &&
                i.warehouseId == tx.warehouseId,
          );
          if (invIdx != -1) {
            double q = _mockInventory[invIdx].quantity;
            if (tx.tipe == 'IN') q -= item.quantity;
            if (tx.tipe == 'OUT') q += item.quantity;

            final old = _mockInventory[invIdx];
            _mockInventory[invIdx] = InventoryItem(
              id: old.id,
              productId: old.productId,
              productName: old.productName,
              productSku: old.productSku,
              productUnit: old.productUnit,
              barcode: old.barcode,
              warehouseId: old.warehouseId,
              warehouseName: old.warehouseName,
              quantity: q,
              minimumStock: old.minimumStock,
            );
          }
        }
        // Mark as cancelled
        _mockTransactions[idx] = StockTransaction(
          id: tx.id,
          nomorTransaksi: tx.nomorTransaksi,
          tipe: tx.tipe,
          warehouseId: tx.warehouseId,
          warehouseName: tx.warehouseName,
          tanggal: tx.tanggal,
          status: 'CANCELLED',
          catatan: '${tx.catatan ?? ''}\n[DIBATALKAN: $reason]',
          items: tx.items,
        );
      }
    }
  }

  // =================================================================
  // STOCK OPNAME
  // =================================================================

  Future<List<StockOpname>> getStockOpnames({String? warehouseId}) async {
    final client = _client;
    if (client != null) {
      var q = client.from('stock_opnames').select('''
        *,
        warehouses (nama),
        profiles (nama),
        stock_opname_items (
          id, system_quantity, physical_quantity, difference, notes,
          products (id, nama, sku, unit)
        )
      ''');

      if (warehouseId != null && warehouseId.isNotEmpty) {
        q = q.eq('warehouse_id', warehouseId);
      }
      final res = await q.order('created_at', ascending: false);
      return (res as List).map((e) => StockOpname.fromJson(e)).toList();
    }
    return _mockOpnames;
  }

  Future<String> createAndPostOpname({
    required String warehouseId,
    required DateTime tanggal,
    String? catatan,
    required List<StockOpnameItem> items,
  }) async {
    final client = _client;
    final opnNumber = Formatters.generateOpnameNumber();

    if (client != null) {
      final userId = client.auth.currentUser?.id;

      // 1. Insert header
      final opnRes = await client
          .from('stock_opnames')
          .insert({
            'nomor_opname': opnNumber,
            'warehouse_id': warehouseId,
            'tanggal': Formatters.dateIso(tanggal),
            'status': 'DRAFT',
            'catatan': catatan,
            'created_by': userId,
          })
          .select()
          .single();

      final String opnId = opnRes['id'];

      // 2. Insert items
      final itemsPayload = items
          .map(
            (i) => {
              'opname_id': opnId,
              'product_id': i.productId,
              'system_quantity': i.systemQuantity,
              'physical_quantity': i.physicalQuantity,
              'difference': i.difference,
              'notes': i.notes,
            },
          )
          .toList();

      await client.from('stock_opname_items').insert(itemsPayload);

      // 3. Post opname via atomic RPC
      await client.rpc('post_stock_opname', params: {'p_opname_id': opnId});

      return opnNumber;
    }

    // Mock Mode
    for (var item in items) {
      final invIdx = _mockInventory.indexWhere(
        (i) => i.productId == item.productId && i.warehouseId == warehouseId,
      );
      if (invIdx != -1) {
        final old = _mockInventory[invIdx];
        _mockInventory[invIdx] = InventoryItem(
          id: old.id,
          productId: old.productId,
          productName: old.productName,
          productSku: old.productSku,
          productUnit: old.productUnit,
          barcode: old.barcode,
          warehouseId: old.warehouseId,
          warehouseName: old.warehouseName,
          quantity: item.physicalQuantity,
          minimumStock: old.minimumStock,
          updatedAt: DateTime.now(),
        );
      }
      final pIdx = _mockProducts.indexWhere((p) => p.id == item.productId);
      if (pIdx != -1) {
        _mockProducts[pIdx] = _mockProducts[pIdx].copyWith(
          currentStock: item.physicalQuantity,
        );
      }
    }

    final newOpn = StockOpname(
      id: 'opn-${DateTime.now().millisecondsSinceEpoch}',
      nomorOpname: opnNumber,
      warehouseId: warehouseId,
      warehouseName: _mockWarehouses
          .firstWhere(
            (w) => w.id == warehouseId,
            orElse: () => _mockWarehouses.first,
          )
          .nama,
      tanggal: tanggal,
      status: 'COMPLETED',
      catatan: catatan,
      createdBy: _currentMockUser?.id ?? 'demo-user',
      creatorName: _currentMockUser?.nama ?? 'Staff Demo',
      createdAt: DateTime.now(),
      items: items,
    );
    _mockOpnames.insert(0, newOpn);
    return opnNumber;
  }

  // =================================================================
  // DASHBOARD METRICS
  // =================================================================

  Future<Map<String, dynamic>> getDashboardMetrics() async {
    final products = await getProducts(status: 'active');
    final inventory = await getInventory();

    double totalProducts = products.length.toDouble();
    double totalStock = 0;
    for (var item in inventory) {
      totalStock += item.quantity;
    }

    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = DateTime(today.year, today.month, today.day, 23, 59, 59);

    final transactions = await getTransactions(
      startDate: todayStart,
      endDate: todayEnd,
    );

    double inToday = 0;
    double outToday = 0;

    for (var tx in transactions) {
      if (tx.isCompleted) {
        for (var item in tx.items) {
          if (tx.tipe == 'IN') inToday += item.quantity;
          if (tx.tipe == 'OUT') outToday += item.quantity;
        }
      }
    }

    final lowStockItems = inventory.where((i) => i.isLowStock).toList();
    final recentTransactions = await getTransactions();

    return {
      'totalProducts': totalProducts,
      'totalStock': totalStock,
      'inToday': inToday,
      'outToday': outToday,
      'lowStockCount': lowStockItems.length,
      'lowStockItems': lowStockItems,
      'recentTransactions': recentTransactions.take(5).toList(),
    };
  }
}
