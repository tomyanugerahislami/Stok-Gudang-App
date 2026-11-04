class Product {
  final String id;
  final String sku;
  final String nama;
  final String? categoryId;
  final String? categoryName;
  final String unit;
  final String barcode;
  final double minimumStock;
  final double costPrice;
  final String status; // 'active', 'inactive', 'archived'
  final double currentStock;

  Product({
    required this.id,
    required this.sku,
    required this.nama,
    this.categoryId,
    this.categoryName,
    this.unit = 'pcs',
    required this.barcode,
    this.minimumStock = 0,
    this.costPrice = 0,
    this.status = 'active',
    this.currentStock = 0,
  });

  bool get isActive => status == 'active';
  bool get isArchived => status == 'archived';
  bool get isLowStock => currentStock <= minimumStock && minimumStock > 0;

  factory Product.fromJson(Map<String, dynamic> json) {
    String? catName;
    if (json['categories'] != null && json['categories'] is Map) {
      catName = json['categories']['nama'] as String?;
    } else if (json['category_name'] != null) {
      catName = json['category_name'] as String?;
    }

    return Product(
      id: json['id'] as String,
      sku: json['sku'] as String? ?? '',
      nama: json['nama'] as String? ?? '',
      categoryId: json['category_id'] as String?,
      categoryName: catName,
      unit: json['unit'] as String? ?? 'pcs',
      barcode: json['barcode'] as String? ?? '',
      minimumStock: (json['minimum_stock'] as num?)?.toDouble() ?? 0.0,
      costPrice: (json['cost_price'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'active',
      currentStock: (json['current_stock'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sku': sku,
      'nama': nama,
      'category_id': categoryId,
      'unit': unit,
      'barcode': barcode,
      'minimum_stock': minimumStock,
      'cost_price': costPrice,
      'status': status,
    };
  }

  Product copyWith({
    String? id,
    String? sku,
    String? nama,
    String? categoryId,
    String? categoryName,
    String? unit,
    String? barcode,
    double? minimumStock,
    double? costPrice,
    String? status,
    double? currentStock,
  }) {
    return Product(
      id: id ?? this.id,
      sku: sku ?? this.sku,
      nama: nama ?? this.nama,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      unit: unit ?? this.unit,
      barcode: barcode ?? this.barcode,
      minimumStock: minimumStock ?? this.minimumStock,
      costPrice: costPrice ?? this.costPrice,
      status: status ?? this.status,
      currentStock: currentStock ?? this.currentStock,
    );
  }
}

