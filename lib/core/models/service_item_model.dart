enum ServiceItemType { part, labor, service }

class ServiceItemEntity {
  final String id;
  final String name;
  final ServiceItemType type;
  final double price;
  final int quantity;
  final String? description;
  final String? category; // regular, inspection, repair, emergency
  final bool isActive;
  
  double get totalPrice => price * quantity;

  ServiceItemEntity({
    required this.id,
    required this.name,
    required this.type,
    required this.price,
    this.quantity = 1,
    this.description,
    this.category,
    this.isActive = true,
  });

  factory ServiceItemEntity.fromMap(Map<String, dynamic> map) {
    return ServiceItemEntity(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      type: ServiceItemType.values.firstWhere(
        (e) => e.toString() == 'ServiceItemType.${map['type']}',
        orElse: () => ServiceItemType.service,
      ),
      price: (map['price'] ?? 0).toDouble(),
      quantity: map['quantity'] ?? 1,
      description: map['description'],
      category: map['category'],
      isActive: map['isActive'] ?? true,
    );
  }

  factory ServiceItemEntity.fromFirestore(Map<String, dynamic> map, String id) {
    return ServiceItemEntity(
      id: id,
      name: map['name'] ?? '',
      type: ServiceItemType.values.firstWhere(
        (e) => e.toString() == 'ServiceItemType.${map['type']}',
        orElse: () => ServiceItemType.service,
      ),
      price: (map['price'] ?? 0).toDouble(),
      quantity: map['quantity'] ?? 1,
      description: map['description'],
      category: map['category'],
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.toString().split('.').last,
      'price': price,
      'quantity': quantity,
      'description': description,
      'category': category,
      'isActive': isActive,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'type': type.toString().split('.').last,
      'price': price,
      'description': description,
      'category': category,
      'isActive': isActive,
    };
  }

  ServiceItemEntity copyWith({
    String? id,
    String? name,
    ServiceItemType? type,
    double? price,
    int? quantity,
    String? description,
    String? category,
    bool? isActive,
  }) {
    return ServiceItemEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      description: description ?? this.description,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
    );
  }
}
