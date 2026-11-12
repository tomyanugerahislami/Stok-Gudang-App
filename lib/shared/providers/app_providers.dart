import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/supabase_service.dart';
import '../models/user_profile.dart';
import '../models/warehouse.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../models/party.dart';
import '../models/inventory_item.dart';
import '../models/stock_transaction.dart';

final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService.instance;
});

// Profile Provider
final currentProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final service = ref.watch(supabaseServiceProvider);
  return await service.getCurrentProfile();
});

// Warehouses
final warehousesProvider = FutureProvider<List<Warehouse>>((ref) async {
  final service = ref.watch(supabaseServiceProvider);
  return await service.getWarehouses();
});

// Selected Warehouse Notifier
class SelectedWarehouseNotifier extends Notifier<Warehouse?> {
  @override
  Warehouse? build() => null;
  void set(Warehouse? warehouse) => state = warehouse;
}

final selectedWarehouseProvider =
    NotifierProvider<SelectedWarehouseNotifier, Warehouse?>(SelectedWarehouseNotifier.new);

// Categories
final categoriesProvider = FutureProvider<List<ProductCategory>>((ref) async {
  final service = ref.watch(supabaseServiceProvider);
  return await service.getCategories();
});

// Suppliers
final suppliersProvider = FutureProvider<List<Supplier>>((ref) async {
  final service = ref.watch(supabaseServiceProvider);
  return await service.getSuppliers();
});

// Customers
final customersProvider = FutureProvider<List<Customer>>((ref) async {
  final service = ref.watch(supabaseServiceProvider);
  return await service.getCustomers();
});

// Products Filter State
class ProductFilter {
  final String query;
  final String? categoryId;
  final String status;

  ProductFilter({
    this.query = '',
    this.categoryId,
    this.status = 'active',
  });

  ProductFilter copyWith({
    String? query,
    String? categoryId,
    String? status,
  }) {
    return ProductFilter(
      query: query ?? this.query,
      categoryId: categoryId ?? this.categoryId,
      status: status ?? this.status,
    );
  }
}

class ProductFilterNotifier extends Notifier<ProductFilter> {
  @override
  ProductFilter build() => ProductFilter();
  void set(ProductFilter filter) => state = filter;
}

final productFilterProvider =
    NotifierProvider<ProductFilterNotifier, ProductFilter>(ProductFilterNotifier.new);

final productsProvider = FutureProvider<List<Product>>((ref) async {
  final service = ref.watch(supabaseServiceProvider);
  final filter = ref.watch(productFilterProvider);
  return await service.getProducts(
    query: filter.query,
    categoryId: filter.categoryId,
    status: filter.status,
  );
});

// Inventory Provider
final inventoryProvider = FutureProvider<List<InventoryItem>>((ref) async {
  final service = ref.watch(supabaseServiceProvider);
  final selectedWh = ref.watch(selectedWarehouseProvider);
  return await service.getInventory(warehouseId: selectedWh?.id);
});

// Dashboard Metrics Provider
final dashboardMetricsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.watch(supabaseServiceProvider);
  return await service.getDashboardMetrics();
});

// Transactions Provider with filter
class TransactionFilter {
  final String? tipe;
  final String? warehouseId;
  final DateTime? startDate;
  final DateTime? endDate;

  TransactionFilter({
    this.tipe,
    this.warehouseId,
    this.startDate,
    this.endDate,
  });

  TransactionFilter copyWith({
    String? tipe,
    String? warehouseId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return TransactionFilter(
      tipe: tipe ?? this.tipe,
      warehouseId: warehouseId ?? this.warehouseId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}

class TransactionFilterNotifier extends Notifier<TransactionFilter> {
  @override
  TransactionFilter build() => TransactionFilter();
  void set(TransactionFilter filter) => state = filter;
}

final transactionFilterProvider =
    NotifierProvider<TransactionFilterNotifier, TransactionFilter>(TransactionFilterNotifier.new);

final transactionsProvider = FutureProvider<List<StockTransaction>>((ref) async {
  final service = ref.watch(supabaseServiceProvider);
  final filter = ref.watch(transactionFilterProvider);
  return await service.getTransactions(
    tipe: filter.tipe,
    warehouseId: filter.warehouseId,
    startDate: filter.startDate,
    endDate: filter.endDate,
  );
});
