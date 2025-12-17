import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:car_maintenance_system_new/core/models/service_item_model.dart';

enum BookingStatus { pending, confirmed, inProgress, completedPendingPayment, completed, cancelled }
enum MaintenanceType { regular, repair, inspection, emergency }
enum PaymentMethod { cash, card, digital }

class BookingEntity {
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
  
  // Invoice/Service details
  final List<ServiceItemEntity>? serviceItems;
  final double? laborCost;
  final double? tax;
  final String? technicianNotes;
  
  // Discount/Offer details
  final String? offerCode; // Applied offer code
  final String? offerTitle; // Offer title for display
  final int? discountPercentage; // Discount percentage from offer
  
  // Rating system
  final double? rating; // Customer rating (1-5)
  final String? ratingComment; // Optional comment
  final DateTime? ratedAt;
  
  // Payment system
  final bool isPaid; // Payment status
  final DateTime? paidAt; // When payment was completed
  final String? cashierId; // ID of cashier who processed payment
  final PaymentMethod? paymentMethod; // How customer paid
  
  // Calculate hours worked
  double get hoursWorked {
    if (startedAt == null || completedAt == null) return 0.0;
    final duration = completedAt!.difference(startedAt!);
    return duration.inMinutes / 60.0;
  }
  
  // Calculate total cost
  double get subtotal {
    if (serviceItems == null || serviceItems!.isEmpty) return laborCost ?? 0;
    final itemsTotal = serviceItems!.fold<double>(0, (sum, item) => sum + item.totalPrice);
    return itemsTotal + (laborCost ?? 0);
  }
  
  // Calculate discount amount
  double get discountAmount {
    if (discountPercentage == null || discountPercentage == 0) return 0.0;
    return subtotal * (discountPercentage! / 100.0);
  }
  
  // Calculate subtotal after discount
  double get subtotalAfterDiscount {
    return subtotal - discountAmount;
  }
  
  double get totalCost {
    final taxAmount = tax ?? (subtotalAfterDiscount * 0.10); // 10% default tax on discounted amount
    return subtotalAfterDiscount + taxAmount;
  }

  BookingEntity({
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

  factory BookingEntity.fromMap(Map<String, dynamic> map) {
    return BookingEntity(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      carId: map['carId'] ?? '',
      serviceId: map['serviceId'] ?? '',
      maintenanceType: MaintenanceType.values.firstWhere(
        (e) => e.toString() == 'MaintenanceType.${map['maintenanceType']}',
        orElse: () => MaintenanceType.regular,
      ),
      scheduledDate: (map['scheduledDate'] as Timestamp).toDate(),
      timeSlot: map['timeSlot'] ?? '',
      status: BookingStatus.values.firstWhere(
        (e) => e.toString() == 'BookingStatus.${map['status']}',
        orElse: () => BookingStatus.pending,
      ),
      description: map['description'],
      assignedTechnicians: map['assignedTechnicians'] != null 
          ? List<String>.from(map['assignedTechnicians']) 
          : null,
      notes: map['notes'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      completedAt: map['completedAt'] != null 
          ? (map['completedAt'] as Timestamp).toDate() 
          : null,
      startedAt: map['startedAt'] != null 
          ? (map['startedAt'] as Timestamp).toDate() 
          : null,
      serviceItems: map['serviceItems'] != null
          ? (map['serviceItems'] as List).map((item) => ServiceItemEntity.fromMap(item)).toList()
          : null,
      laborCost: map['laborCost']?.toDouble(),
      tax: map['tax']?.toDouble(),
      technicianNotes: map['technicianNotes'],
      offerCode: map['offerCode'],
      offerTitle: map['offerTitle'],
      discountPercentage: map['discountPercentage'],
      rating: map['rating']?.toDouble(),
      ratingComment: map['ratingComment'],
      ratedAt: map['ratedAt'] != null 
          ? (map['ratedAt'] as Timestamp).toDate() 
          : null,
      isPaid: map['isPaid'] ?? false,
      paidAt: map['paidAt'] != null 
          ? (map['paidAt'] as Timestamp).toDate() 
          : null,
      cashierId: map['cashierId'],
      paymentMethod: map['paymentMethod'] != null
          ? PaymentMethod.values.firstWhere(
              (e) => e.toString() == 'PaymentMethod.${map['paymentMethod']}',
              orElse: () => PaymentMethod.cash,
            )
          : null,
    );
  }

  factory BookingEntity.fromFirestore(Map<String, dynamic> map, String id) {
    return BookingEntity(
      id: id,
      userId: map['userId'] ?? '',
      carId: map['carId'] ?? '',
      serviceId: map['serviceId'] ?? '',
      maintenanceType: MaintenanceType.values.firstWhere(
        (e) => e.toString() == 'MaintenanceType.${map['maintenanceType']}',
        orElse: () => MaintenanceType.regular,
      ),
      scheduledDate: (map['scheduledDate'] as Timestamp).toDate(),
      timeSlot: map['timeSlot'] ?? '',
      status: BookingStatus.values.firstWhere(
        (e) => e.toString() == 'BookingStatus.${map['status']}',
        orElse: () => BookingStatus.pending,
      ),
      description: map['description'],
      assignedTechnicians: map['assignedTechnicians'] != null 
          ? List<String>.from(map['assignedTechnicians']) 
          : null,
      notes: map['notes'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      completedAt: map['completedAt'] != null 
          ? (map['completedAt'] as Timestamp).toDate() 
          : null,
      startedAt: map['startedAt'] != null
          ? (map['startedAt'] as Timestamp).toDate()
          : null,
          serviceItems: map['serviceItems'] != null
              ? (map['serviceItems'] as List).map((item) => ServiceItemEntity.fromMap(item as Map<String, dynamic>)).toList()
              : null,
          laborCost: map['laborCost']?.toDouble(),
          tax: map['tax']?.toDouble(),
          technicianNotes: map['technicianNotes'],
          offerCode: map['offerCode'],
          offerTitle: map['offerTitle'],
          discountPercentage: map['discountPercentage'],
          rating: map['rating']?.toDouble(),
          ratingComment: map['ratingComment'],
          ratedAt: map['ratedAt'] != null ? (map['ratedAt'] as Timestamp).toDate() : null,
          isPaid: map['isPaid'] ?? false,
          paidAt: map['paidAt'] != null ? (map['paidAt'] as Timestamp).toDate() : null,
          cashierId: map['cashierId'],
          paymentMethod: map['paymentMethod'] != null
              ? PaymentMethod.values.firstWhere(
                  (e) => e.toString() == 'PaymentMethod.${map['paymentMethod']}',
                  orElse: () => PaymentMethod.cash,
                )
              : null,
        );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
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
      'serviceItems': serviceItems?.map((item) => item.toMap()).toList(),
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
      'serviceItems': serviceItems?.map((item) => item.toMap()).toList(),
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

  BookingEntity copyWith({
    String? id,
    String? userId,
    String? carId,
    String? serviceId,
    MaintenanceType? maintenanceType,
    DateTime? scheduledDate,
    String? timeSlot,
    BookingStatus? status,
    String? description,
    List<String>? assignedTechnicians,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
    DateTime? startedAt,
    List<ServiceItemEntity>? serviceItems,
    double? laborCost,
    double? tax,
    String? technicianNotes,
    String? offerCode,
    String? offerTitle,
    int? discountPercentage,
    double? rating,
    String? ratingComment,
    DateTime? ratedAt,
    bool? isPaid,
    DateTime? paidAt,
    String? cashierId,
    PaymentMethod? paymentMethod,
  }) {
    return BookingEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      carId: carId ?? this.carId,
      serviceId: serviceId ?? this.serviceId,
      maintenanceType: maintenanceType ?? this.maintenanceType,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      timeSlot: timeSlot ?? this.timeSlot,
      status: status ?? this.status,
      description: description ?? this.description,
      assignedTechnicians: assignedTechnicians ?? this.assignedTechnicians,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      startedAt: startedAt ?? this.startedAt,
      serviceItems: serviceItems ?? this.serviceItems,
      laborCost: laborCost ?? this.laborCost,
      tax: tax ?? this.tax,
      technicianNotes: technicianNotes ?? this.technicianNotes,
      offerCode: offerCode ?? this.offerCode,
      offerTitle: offerTitle ?? this.offerTitle,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      rating: rating ?? this.rating,
      ratingComment: ratingComment ?? this.ratingComment,
      ratedAt: ratedAt ?? this.ratedAt,
      isPaid: isPaid ?? this.isPaid,
      paidAt: paidAt ?? this.paidAt,
      cashierId: cashierId ?? this.cashierId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }
}
