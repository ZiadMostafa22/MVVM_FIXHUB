import 'dart:async';
import 'package:car_maintenance_system_new/features/booking/domain/repositories/booking_repository.dart';
import 'package:car_maintenance_system_new/features/booking/domain/entities/booking_entity.dart';

/// Use case to watch bookings in real-time
class WatchBookingsUseCase {
  final BookingRepository repository;

  WatchBookingsUseCase(this.repository);

  Stream<List<BookingEntity>> call({
    required String userId,
    String? role,
  }) {
    return repository.watchBookings(userId: userId, role: role);
  }
}

