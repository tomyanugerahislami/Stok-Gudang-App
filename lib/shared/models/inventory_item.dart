class InventoryItem {
  final String id;
  final String productId;
  final String productName;
  final String productSku;
  final String productUnit;
  final String barcode;
  final String warehouseId;
  final String warehouseName;
  final double quantity;
  final double minimumStock;
  final DateTime? updatedAt;

  InventoryItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productSku,
    required this.productUnit,
    required this.barcode,
    required this.warehouseId,
    required this.warehouseName,
    required this.quantity,
    this.minimumStock = 0,
    this.updatedAt,
  });

  bool get isLowStock => quantity <= minimumStock && minimumStock > 0;

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    final product = json['products'] as Map<String, dynamic>? ?? {};
    final warehouse = json['warehouses'] as Map<String, dynamic>? ?? {};

    return InventoryItem(
      id: json['id'] as String? ?? '',
      productId: json['product_id'] as String? ?? (product['id'] as String? ?? ''),
      productName: product['nama'] as String? ?? 'Produk',
      productSku: product['sku'] as String? ?? '',
      productUnit: product['unit'] as String? ?? 'pcs',
      barcode: product['barcode'] as String? ?? '',
      warehouseId: json['warehouse_id'] as String? ?? (warehouse['id'] as String? ?? ''),
      warehouseName: warehouse['nama'] as String? ?? 'Gudang',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      minimumStock: (product['minimum_stock'] as num?)?.toDouble() ?? 0.0,
      updatedAt: json['updated_at'] != null 
          ? DateTime.tryParse(json['updated_at'] as String) 
          : null,
    );
  }
}

