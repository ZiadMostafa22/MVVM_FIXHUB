import 'dart:async';
import 'package:car_maintenance_system_new/features/booking/domain/entities/booking_entity.dart';

/// Repository interface for booking operations
abstract class BookingRepository {
  /// Load bookings for a user or all bookings for admin/technician/cashier
  Future<List<BookingEntity>> loadBookings({
    required String userId,
    String? role,
  });

  /// Create a real-time stream of bookings
  Stream<List<BookingEntity>> watchBookings({
    required String userId,
    String? role,
  });

  /// Create a new booking
  Future<String> createBooking(BookingEntity booking);

  /// Update a booking
  Future<void> updateBooking(
    String bookingId,
    Map<String, dynamic> updates,
  );

  /// Get a single booking by ID
  Future<BookingEntity?> getBookingById(String bookingId);

  /// Update booking status
  Future<void> updateBookingStatus(
    String bookingId,
    BookingStatus status, {
    DateTime? completedAt,
  });

  /// Rate a booking
  Future<void> rateBooking({
    required String bookingId,
    required double rating,
    required String comment,
  });

  /// Process payment for a booking
  Future<void> processPayment({
    required String bookingId,
    required String cashierId,
    required PaymentMethod paymentMethod,
    double? totalCost,
  });
}

