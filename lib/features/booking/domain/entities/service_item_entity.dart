/// Service item entity - pure domain model
enum ServiceItemType { part, labor, service }

class ServiceItemEntity {
  final String id;
  final String name;
  final ServiceItemType type;
  final double price;
  final int quantity;
  final String? description;

  double get totalPrice => price * quantity;

  ServiceItemEntity({
    required this.id,
    required this.name,
    required this.type,
    required this.price,
    this.quantity = 1,
    this.description,
  });

  ServiceItemEntity copyWith({
    String? id,
    String? name,
    ServiceItemType? type,
    double? price,
    int? quantity,
    String? description,
  }) {
    return ServiceItemEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      description: description ?? this.description,
    );
  }
}

