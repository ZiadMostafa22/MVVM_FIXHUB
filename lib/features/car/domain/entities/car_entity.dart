/// Car entity - pure domain model without external dependencies
enum CarType { sedan, suv, hatchback, coupe, convertible, truck, van }

class CarEntity {
  final String id;
  final String userId;
  final String make;
  final String model;
  final int year;
  final String color;
  final String licensePlate;
  final CarType type;
  final String? vin;
  final String? engineType;
  final int? mileage;
  final List<String>? images;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get displayName => '$year $make $model';
  String get fullInfo => '$displayName - $color - $licensePlate';

  CarEntity({
    required this.id,
    required this.userId,
    required this.make,
    required this.model,
    required this.year,
    required this.color,
    required this.licensePlate,
    required this.type,
    this.vin,
    this.engineType,
    this.mileage,
    this.images,
    required this.createdAt,
    required this.updatedAt,
  });

  CarEntity copyWith({
    String? id,
    String? userId,
    String? make,
    String? model,
    int? year,
    String? color,
    String? licensePlate,
    CarType? type,
    String? vin,
    String? engineType,
    int? mileage,
    List<String>? images,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CarEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      color: color ?? this.color,
      licensePlate: licensePlate ?? this.licensePlate,
      type: type ?? this.type,
      vin: vin ?? this.vin,
      engineType: engineType ?? this.engineType,
      mileage: mileage ?? this.mileage,
      images: images ?? this.images,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

