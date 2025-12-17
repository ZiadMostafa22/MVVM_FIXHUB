import 'package:cloud_firestore/cloud_firestore.dart';

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

  factory CarEntity.fromMap(Map<String, dynamic> map) {
    return CarEntity(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      make: map['make'] ?? '',
      model: map['model'] ?? '',
      year: map['year'] ?? 0,
      color: map['color'] ?? '',
      licensePlate: map['licensePlate'] ?? '',
      type: CarType.values.firstWhere(
        (e) => e.toString() == 'CarType.${map['type']}',
        orElse: () => CarType.sedan,
      ),
      vin: map['vin'],
      engineType: map['engineType'],
      mileage: map['mileage'],
      images: map['images'] != null ? List<String>.from(map['images']) : null,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  factory CarEntity.fromFirestore(Map<String, dynamic> map, String id) {
    return CarEntity(
      id: id,
      userId: map['userId'] ?? '',
      make: map['make'] ?? '',
      model: map['model'] ?? '',
      year: map['year'] ?? 0,
      color: map['color'] ?? '',
      licensePlate: map['licensePlate'] ?? '',
      type: CarType.values.firstWhere(
        (e) => e.toString() == 'CarType.${map['type']}',
        orElse: () => CarType.sedan,
      ),
      vin: map['vin'],
      engineType: map['engineType'],
      mileage: map['mileage'],
      images: map['images'] != null ? List<String>.from(map['images']) : null,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'make': make,
      'model': model,
      'year': year,
      'color': color,
      'licensePlate': licensePlate,
      'type': type.toString().split('.').last,
      'vin': vin,
      'engineType': engineType,
      'mileage': mileage,
      'images': images,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'make': make,
      'model': model,
      'year': year,
      'color': color,
      'licensePlate': licensePlate,
      'type': type.toString().split('.').last,
      'vin': vin,
      'engineType': engineType,
      'mileage': mileage,
      'images': images,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

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

  String get displayName => '$year $make $model';
  String get fullInfo => '$displayName - $color - $licensePlate';
}
