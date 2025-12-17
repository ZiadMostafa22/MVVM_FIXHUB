import 'package:cloud_firestore/cloud_firestore.dart';

enum InventoryCategory { parts, supplies, tools }

class InventoryItemEntity {
  final String id;
  final String? serviceItemId;
  final String name;
  final String sku;
  final InventoryCategory category;
  final int currentStock;
  final int lowStockThreshold;
  final int reorderPoint;
  final double unitCost;
  final double unitPrice;
  final String? location;
  final String? supplier;
  final String? supplierContact;
  final DateTime? lastRestocked;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  InventoryItemEntity({
    required this.id,
    this.serviceItemId,
    required this.name,
    required this.sku,
    required this.category,
    required this.currentStock,
    this.lowStockThreshold = 10,
    this.reorderPoint = 15,
    required this.unitCost,
    required this.unitPrice,
    this.location,
    this.supplier,
    this.supplierContact,
    this.lastRestocked,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isLowStock => currentStock <= lowStockThreshold;
  bool get needsReorder => currentStock <= reorderPoint;
  double get profitMargin => unitPrice - unitCost;
  double get profitMarginPercent => unitCost > 0 ? ((profitMargin / unitCost) * 100) : 0;

  factory InventoryItemEntity.fromFirestore(Map<String, dynamic> map, String id) {
    return InventoryItemEntity(
      id: id,
      serviceItemId: map['serviceItemId'],
      name: map['name'] ?? '',
      sku: map['sku'] ?? '',
      category: InventoryCategory.values.firstWhere(
        (e) => e.toString() == 'InventoryCategory.${map['category']}',
        orElse: () => InventoryCategory.parts,
      ),
      currentStock: map['currentStock'] ?? 0,
      lowStockThreshold: map['lowStockThreshold'] ?? 10,
      reorderPoint: map['reorderPoint'] ?? 15,
      unitCost: (map['unitCost'] ?? 0).toDouble(),
      unitPrice: (map['unitPrice'] ?? 0).toDouble(),
      location: map['location'],
      supplier: map['supplier'],
      supplierContact: map['supplierContact'],
      lastRestocked: map['lastRestocked'] != null
          ? (map['lastRestocked'] as Timestamp).toDate()
          : null,
      isActive: map['isActive'] ?? true,
      createdAt: map['createdAt'] != null 
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null 
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'serviceItemId': serviceItemId,
      'name': name,
      'sku': sku,
      'category': category.toString().split('.').last,
      'currentStock': currentStock,
      'lowStockThreshold': lowStockThreshold,
      'reorderPoint': reorderPoint,
      'unitCost': unitCost,
      'unitPrice': unitPrice,
      'location': location,
      'supplier': supplier,
      'supplierContact': supplierContact,
      'lastRestocked': lastRestocked != null
          ? Timestamp.fromDate(lastRestocked!)
          : null,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  InventoryItemEntity copyWith({
    int? currentStock,
    DateTime? lastRestocked,
    DateTime? updatedAt,
  }) {
    return InventoryItemEntity(
      id: id,
      serviceItemId: serviceItemId,
      name: name,
      sku: sku,
      category: category,
      currentStock: currentStock ?? this.currentStock,
      lowStockThreshold: lowStockThreshold,
      reorderPoint: reorderPoint,
      unitCost: unitCost,
      unitPrice: unitPrice,
      location: location,
      supplier: supplier,
      supplierContact: supplierContact,
      lastRestocked: lastRestocked ?? this.lastRestocked,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

class InventoryTransactionEntity {
  final String id;
  final String inventoryItemId;
  final String type; // 'in', 'out', 'adjustment'
  final int quantity;
  final int quantityBefore;
  final int quantityAfter;
  final String? bookingId;
  final String? technicianId;
  final String? reason;
  final String? notes;
  final DateTime createdAt;
  final String createdBy;

  InventoryTransactionEntity({
    required this.id,
    required this.inventoryItemId,
    required this.type,
    required this.quantity,
    required this.quantityBefore,
    required this.quantityAfter,
    this.bookingId,
    this.technicianId,
    this.reason,
    this.notes,
    required this.createdAt,
    required this.createdBy,
  });

  factory InventoryTransactionEntity.fromFirestore(Map<String, dynamic> map, String id) {
    return InventoryTransactionEntity(
      id: id,
      inventoryItemId: map['inventoryItemId'] ?? '',
      type: map['type'] ?? 'out',
      quantity: map['quantity'] ?? 0,
      quantityBefore: map['quantityBefore'] ?? 0,
      quantityAfter: map['quantityAfter'] ?? 0,
      bookingId: map['bookingId'],
      technicianId: map['technicianId'],
      reason: map['reason'],
      notes: map['notes'],
      createdAt: map['createdAt'] != null 
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      createdBy: map['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'inventoryItemId': inventoryItemId,
      'type': type,
      'quantity': quantity,
      'quantityBefore': quantityBefore,
      'quantityAfter': quantityAfter,
      'bookingId': bookingId,
      'technicianId': technicianId,
      'reason': reason,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
    };
  }
}
