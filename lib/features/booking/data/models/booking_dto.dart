import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:car_maintenance_system_new/features/booking/domain/entities/booking_entity.dart';
import 'package:car_maintenance_system_new/features/booking/domain/entities/service_item_entity.dart';

/// Data Transfer Object for Booking
class BookingDto {
  final String id;
  final String userId;
  final String carId;
  final String serviceId;
  final MaintenanceType maintenanceType;
  final DateTime scheduledDate;
  final String timeSlot;
  final BookingStatus status;
  final String? description;
  final List<String>? assignedTechnicians;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final DateTime? startedAt;
  final List<ServiceItemEntity>? serviceItems;
  final double? laborCost;
  final double? tax;
  final String? technicianNotes;
  final String? offerCode;
  final String? offerTitle;
  final int? discountPercentage;
  final double? rating;
  final String? ratingComment;
  final DateTime? ratedAt;
  final bool isPaid;
  final DateTime? paidAt;
  final String? cashierId;
  final PaymentMethod? paymentMethod;

  BookingDto({
    required this.id,
    required this.userId,
    required this.carId,
    required this.serviceId,
    required this.maintenanceType,
    required this.scheduledDate,
    required this.timeSlot,
    required this.status,
    this.description,
    this.assignedTechnicians,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.startedAt,
    this.serviceItems,
    this.laborCost,
    this.tax,
    this.technicianNotes,
    this.offerCode,
    this.offerTitle,
    this.discountPercentage,
    this.rating,
    this.ratingComment,
    this.ratedAt,
    this.isPaid = false,
    this.paidAt,
    this.cashierId,
    this.paymentMethod,
  });

  /// Convert from Firestore document to DTO
  factory BookingDto.fromFirestore(Map<String, dynamic> data, String id) {
    return BookingDto(
      id: id,
      userId: data['userId'] ?? '',
      carId: data['carId'] ?? '',
      serviceId: data['serviceId'] ?? '',
      maintenanceType: MaintenanceType.values.firstWhere(
        (e) => e.toString() == 'MaintenanceType.${data['maintenanceType']}',
        orElse: () => MaintenanceType.regular,
      ),
      scheduledDate: (data['scheduledDate'] as Timestamp).toDate(),
      timeSlot: data['timeSlot'] ?? '',
      status: BookingStatus.values.firstWhere(
        (e) => e.toString() == 'BookingStatus.${data['status']}',
        orElse: () => BookingStatus.pending,
      ),
      description: data['description'],
      assignedTechnicians: data['assignedTechnicians'] != null
          ? List<String>.from(data['assignedTechnicians'])
          : null,
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      startedAt: data['startedAt'] != null
          ? (data['startedAt'] as Timestamp).toDate()
          : null,
      serviceItems: data['serviceItems'] != null
          ? (data['serviceItems'] as List).map((item) {
              return ServiceItemEntity(
                id: item['id'] ?? '',
                name: item['name'] ?? '',
                type: ServiceItemType.values.firstWhere(
                  (e) => e.toString() == 'ServiceItemType.${item['type']}',
                  orElse: () => ServiceItemType.service,
                ),
                price: (item['price'] ?? 0).toDouble(),
                quantity: item['quantity'] ?? 1,
                description: item['description'],
              );
            }).toList()
          : null,
      laborCost: data['laborCost']?.toDouble(),
      tax: data['tax']?.toDouble(),
      technicianNotes: data['technicianNotes'],
      offerCode: data['offerCode'],
      offerTitle: data['offerTitle'],
      discountPercentage: data['discountPercentage'],
      rating: data['rating']?.toDouble(),
      ratingComment: data['ratingComment'],
      ratedAt: data['ratedAt'] != null
          ? (data['ratedAt'] as Timestamp).toDate()
          : null,
      isPaid: data['isPaid'] ?? false,
      paidAt: data['paidAt'] != null
          ? (data['paidAt'] as Timestamp).toDate()
          : null,
      cashierId: data['cashierId'],
      paymentMethod: data['paymentMethod'] != null
          ? PaymentMethod.values.firstWhere(
              (e) => e.toString() == 'PaymentMethod.${data['paymentMethod']}',
              orElse: () => PaymentMethod.cash,
            )
          : null,
    );
  }

  /// Convert DTO to domain entity
  BookingEntity toEntity() {
    return BookingEntity(
      id: id,
      userId: userId,
      carId: carId,
      serviceId: serviceId,
      maintenanceType: maintenanceType,
      scheduledDate: scheduledDate,
      timeSlot: timeSlot,
      status: status,
      description: description,
      assignedTechnicians: assignedTechnicians,
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
      completedAt: completedAt,
      startedAt: startedAt,
      serviceItems: serviceItems,
      laborCost: laborCost,
      tax: tax,
      technicianNotes: technicianNotes,
      offerCode: offerCode,
      offerTitle: offerTitle,
      discountPercentage: discountPercentage,
      rating: rating,
      ratingComment: ratingComment,
      ratedAt: ratedAt,
      isPaid: isPaid,
      paidAt: paidAt,
      cashierId: cashierId,
      paymentMethod: paymentMethod,
    );
  }

  /// Convert domain entity to DTO
  factory BookingDto.fromEntity(BookingEntity entity) {
    return BookingDto(
      id: entity.id,
      userId: entity.userId,
      carId: entity.carId,
      serviceId: entity.serviceId,
      maintenanceType: entity.maintenanceType,
      scheduledDate: entity.scheduledDate,
      timeSlot: entity.timeSlot,
      status: entity.status,
      description: entity.description,
      assignedTechnicians: entity.assignedTechnicians,
      notes: entity.notes,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      completedAt: entity.completedAt,
      startedAt: entity.startedAt,
      serviceItems: entity.serviceItems,
      laborCost: entity.laborCost,
      tax: entity.tax,
      technicianNotes: entity.technicianNotes,
      offerCode: entity.offerCode,
      offerTitle: entity.offerTitle,
      discountPercentage: entity.discountPercentage,
      rating: entity.rating,
      ratingComment: entity.ratingComment,
      ratedAt: entity.ratedAt,
      isPaid: entity.isPaid,
      paidAt: entity.paidAt,
      cashierId: entity.cashierId,
      paymentMethod: entity.paymentMethod,
    );
  }

  /// Convert DTO to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'carId': carId,
      'serviceId': serviceId,
      'maintenanceType': maintenanceType.toString().split('.').last,
      'scheduledDate': Timestamp.fromDate(scheduledDate),
      'timeSlot': timeSlot,
      'status': status.toString().split('.').last,
      'description': description,
      'assignedTechnicians': assignedTechnicians,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
      'serviceItems': serviceItems?.map((item) => {
        'id': item.id,
        'name': item.name,
        'type': item.type.toString().split('.').last,
        'price': item.price,
        'quantity': item.quantity,
        'description': item.description,
      }).toList(),
      'laborCost': laborCost,
      'tax': tax,
      'technicianNotes': technicianNotes,
      'offerCode': offerCode,
      'offerTitle': offerTitle,
      'discountPercentage': discountPercentage,
      'rating': rating,
      'ratingComment': ratingComment,
      'ratedAt': ratedAt != null ? Timestamp.fromDate(ratedAt!) : null,
      'isPaid': isPaid,
      'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
      'cashierId': cashierId,
      'paymentMethod': paymentMethod?.toString().split('.').last,
    };
  }
}

