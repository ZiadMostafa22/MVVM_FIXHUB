import 'package:car_maintenance_system_new/features/booking/domain/entities/service_item_entity.dart';

/// Booking entity - pure domain model without external dependencies
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
  final String? offerCode;
  final String? offerTitle;
  final int? discountPercentage;
  
  // Rating system
  final double? rating;
  final String? ratingComment;
  final DateTime? ratedAt;
  
  // Payment system
  final bool isPaid;
  final DateTime? paidAt;
  final String? cashierId;
  final PaymentMethod? paymentMethod;
  
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
    final taxAmount = tax ?? (subtotalAfterDiscount * 0.10);
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

