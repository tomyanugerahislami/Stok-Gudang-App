class StockTransactionItem {
  final String? id;
  final String? transactionId;
  final String productId;
  final String productName;
  final String productSku;
  final String productUnit;
  final double quantity;
  final double unitCost;
  final String? notes;

  StockTransactionItem({
    this.id,
    this.transactionId,
    required this.productId,
    required this.productName,
    required this.productSku,
    this.productUnit = 'pcs',
    required this.quantity,
    this.unitCost = 0,
    this.notes,
  });

  factory StockTransactionItem.fromJson(Map<String, dynamic> json) {
    final prod = json['products'] as Map<String, dynamic>? ?? {};
    return StockTransactionItem(
      id: json['id'] as String?,
      transactionId: json['transaction_id'] as String?,
      productId: json['product_id'] as String? ?? (prod['id'] as String? ?? ''),
      productName: prod['nama'] as String? ?? 'Produk',
      productSku: prod['sku'] as String? ?? '',
      productUnit: prod['unit'] as String? ?? 'pcs',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      unitCost: (json['unit_cost'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'quantity': quantity,
      'unit_cost': unitCost,
      'notes': notes,
    };
  }
}

class StockTransaction {
  final String id;
  final String nomorTransaksi;
  final String tipe; // 'IN', 'OUT', 'ADJUSTMENT', 'TRANSFER'
  final String warehouseId;
  final String? warehouseName;
  final String? toWarehouseId;
  final String? toWarehouseName;
  final String? supplierId;
  final String? supplierName;
  final String? customerId;
  final String? customerName;
  final String? recipient;
  final String? documentNumber;
  final DateTime tanggal;
  final String status; // 'DRAFT', 'COMPLETED', 'CANCELLED'
  final String? catatan;
  final String? createdBy;
  final String? creatorName;
  final DateTime? createdAt;
  final List<StockTransactionItem> items;

  StockTransaction({
    required this.id,
    required this.nomorTransaksi,
    required this.tipe,
    required this.warehouseId,
    this.warehouseName,
    this.toWarehouseId,
    this.toWarehouseName,
    this.supplierId,
    this.supplierName,
    this.customerId,
    this.customerName,
    this.recipient,
    this.documentNumber,
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
  bool get isCancelled => status == 'CANCELLED';

  factory StockTransaction.fromJson(Map<String, dynamic> json) {
    final wh = json['warehouses'] as Map<String, dynamic>?;
    final toWh = json['to_warehouse'] as Map<String, dynamic>?;
    final sup = json['suppliers'] as Map<String, dynamic>?;
    final cust = json['customers'] as Map<String, dynamic>?;
    final prof = json['profiles'] as Map<String, dynamic>?;

    final rawItems = json['stock_transaction_items'] as List<dynamic>? ?? [];
    final itemsList = rawItems
        .map((item) => StockTransactionItem.fromJson(item as Map<String, dynamic>))
        .toList();

    return StockTransaction(
      id: json['id'] as String,
      nomorTransaksi: json['nomor_transaksi'] as String? ?? '',
      tipe: json['tipe'] as String? ?? 'IN',
      warehouseId: json['warehouse_id'] as String? ?? '',
      warehouseName: wh != null ? wh['nama'] as String? : null,
      toWarehouseId: json['to_warehouse_id'] as String?,
      toWarehouseName: toWh != null ? toWh['nama'] as String? : null,
      supplierId: json['supplier_id'] as String?,
      supplierName: sup != null ? sup['nama'] as String? : null,
      customerId: json['customer_id'] as String?,
      customerName: cust != null ? cust['nama'] as String? : null,
      recipient: json['recipient'] as String?,
      documentNumber: json['document_number'] as String?,
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
      items: itemsList,
    );
  }
}

