import 'package:cloud_firestore/cloud_firestore.dart';

enum RefundStatus { requested, approved, rejected, processed }

class RefundEntity {
  final String id;
  final String bookingId;
  final double originalAmount;
  final double refundAmount;
  final String reason;
  final String? customerNotes;
  final RefundStatus status;
  final String requestedBy;
  final DateTime requestedAt;
  final String? approvedBy;
  final DateTime? approvedAt;
  final DateTime? processedAt;
  final String? originalPaymentMethod;
  final String? refundMethod;

  RefundEntity({
    required this.id,
    required this.bookingId,
    required this.originalAmount,
    required this.refundAmount,
    required this.reason,
    this.customerNotes,
    required this.status,
    required this.requestedBy,
    required this.requestedAt,
    this.approvedBy,
    this.approvedAt,
    this.processedAt,
    this.originalPaymentMethod,
    this.refundMethod,
  });

  factory RefundEntity.fromFirestore(Map<String, dynamic> map, String id) {
    return RefundEntity(
      id: id,
      bookingId: map['bookingId'] ?? '',
      originalAmount: (map['originalAmount'] ?? 0).toDouble(),
      refundAmount: (map['refundAmount'] ?? 0).toDouble(),
      reason: map['reason'] ?? '',
      customerNotes: map['customerNotes'],
      status: RefundStatus.values.firstWhere(
        (e) => e.toString() == 'RefundStatus.${map['status']}',
        orElse: () => RefundStatus.requested,
      ),
      requestedBy: map['requestedBy'] ?? '',
      requestedAt: map['requestedAt'] != null
          ? (map['requestedAt'] as Timestamp).toDate()
          : DateTime.now(),
      approvedBy: map['approvedBy'],
      approvedAt: map['approvedAt'] != null
          ? (map['approvedAt'] as Timestamp).toDate()
          : null,
      processedAt: map['processedAt'] != null
          ? (map['processedAt'] as Timestamp).toDate()
          : null,
      originalPaymentMethod: map['originalPaymentMethod'],
      refundMethod: map['refundMethod'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'bookingId': bookingId,
      'originalAmount': originalAmount,
      'refundAmount': refundAmount,
      'reason': reason,
      'customerNotes': customerNotes,
      'status': status.toString().split('.').last,
      'requestedBy': requestedBy,
      'requestedAt': Timestamp.fromDate(requestedAt),
      'approvedBy': approvedBy,
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'processedAt': processedAt != null ? Timestamp.fromDate(processedAt!) : null,
      'originalPaymentMethod': originalPaymentMethod,
      'refundMethod': refundMethod,
    };
  }
}
