class StockOpnameItem {
  final String? id;
  final String? opnameId;
  final String productId;
  final String productName;
  final String productSku;
  final String productUnit;
  final double systemQuantity;
  final double physicalQuantity;
  final double difference; // physicalQuantity - systemQuantity
  final String? notes;

  StockOpnameItem({
    this.id,
    this.opnameId,
    required this.productId,
    required this.productName,
    required this.productSku,
    this.productUnit = 'pcs',
    required this.systemQuantity,
    required this.physicalQuantity,
    required this.difference,
    this.notes,
  });

  factory StockOpnameItem.fromJson(Map<String, dynamic> json) {
    final prod = json['products'] as Map<String, dynamic>? ?? {};
    return StockOpnameItem(
      id: json['id'] as String?,
      opnameId: json['opname_id'] as String?,
      productId: json['product_id'] as String? ?? (prod['id'] as String? ?? ''),
      productName: prod['nama'] as String? ?? 'Produk',
      productSku: prod['sku'] as String? ?? '',
      productUnit: prod['unit'] as String? ?? 'pcs',
      systemQuantity: (json['system_quantity'] as num?)?.toDouble() ?? 0.0,
      physicalQuantity: (json['physical_quantity'] as num?)?.toDouble() ?? 0.0,
      difference: (json['difference'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'system_quantity': systemQuantity,
      'physical_quantity': physicalQuantity,
      'difference': difference,
      'notes': notes,
    };
  }
}

class StockOpname {
  final String id;
  final String nomorOpname;
  final String warehouseId;
  final String? warehouseName;
  final DateTime tanggal;
  final String status; // 'DRAFT', 'COMPLETED', 'CANCELLED'
  final String? catatan;
  final String? createdBy;
  final String? creatorName;
  final DateTime? createdAt;
  final List<StockOpnameItem> items;

  StockOpname({
    required this.id,
    required this.nomorOpname,
    required this.warehouseId,
    this.warehouseName,
    required this.tanggal,
    this.status = 'DRAFT',
    this.catatan,
    this.createdBy,
    this.creatorName,
    this.createdAt,
    this.items = const [],
  });

  bool get isDraft => status == 'DRAFT';
  bool get isCompleted => status == 'COMPLETED';

  factory StockOpname.fromJson(Map<String, dynamic> json) {
    final wh = json['warehouses'] as Map<String, dynamic>?;
    final prof = json['profiles'] as Map<String, dynamic>?;
    final rawItems = json['stock_opname_items'] as List<dynamic>? ?? [];

    return StockOpname(
      id: json['id'] as String,
      nomorOpname: json['nomor_opname'] as String? ?? '',
      warehouseId: json['warehouse_id'] as String? ?? '',
      warehouseName: wh != null ? wh['nama'] as String? : null,
      tanggal: json['tanggal'] != null 
          ? DateTime.tryParse(json['tanggal'] as String) ?? DateTime.now() 
          : DateTime.now(),
      status: json['status'] as String? ?? 'DRAFT',
      catatan: json['catatan'] as String?,
      createdBy: json['created_by'] as String?,
      creatorName: prof != null ? prof['nama'] as String? : null,
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'] as String) 
          : null,
      items: rawItems
          .map((i) => StockOpnameItem.fromJson(i as Map<String, dynamic>))
          .toList(),
    );
  }
}

