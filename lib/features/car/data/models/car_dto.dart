import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:car_maintenance_system_new/features/car/domain/entities/car_entity.dart';

/// Data Transfer Object for Car
class CarDto {
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

  CarDto({
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

  /// Convert from Firestore document to DTO
  factory CarDto.fromFirestore(Map<String, dynamic> data, String id) {
    return CarDto(
      id: id,
      userId: data['userId'] ?? '',
      make: data['make'] ?? '',
      model: data['model'] ?? '',
      year: data['year'] ?? 0,
      color: data['color'] ?? '',
      licensePlate: data['licensePlate'] ?? '',
      type: CarType.values.firstWhere(
        (e) => e.toString() == 'CarType.${data['type']}',
        orElse: () => CarType.sedan,
      ),
      vin: data['vin'],
      engineType: data['engineType'],
      mileage: data['mileage'],
      images: data['images'] != null ? List<String>.from(data['images']) : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Convert DTO to domain entity
  CarEntity toEntity() {
    return CarEntity(
      id: id,
      userId: userId,
      make: make,
      model: model,
      year: year,
      color: color,
      licensePlate: licensePlate,
      type: type,
      vin: vin,
      engineType: engineType,
      mileage: mileage,
      images: images,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Convert domain entity to DTO
  factory CarDto.fromEntity(CarEntity entity) {
    return CarDto(
      id: entity.id,
      userId: entity.userId,
      make: entity.make,
      model: entity.model,
      year: entity.year,
      color: entity.color,
      licensePlate: entity.licensePlate,
      type: entity.type,
      vin: entity.vin,
      engineType: entity.engineType,
      mileage: entity.mileage,
      images: entity.images,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// Convert DTO to Firestore document
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
}

