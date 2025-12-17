import 'package:car_maintenance_system_new/features/booking/domain/repositories/booking_repository.dart';
import 'package:car_maintenance_system_new/features/booking/domain/entities/booking_entity.dart';

/// Use case to get bookings
class GetBookingsUseCase {
  final BookingRepository repository;

  GetBookingsUseCase(this.repository);

  Future<List<BookingEntity>> call({
    required String userId,
    String? role,
  }) async {
    return await repository.loadBookings(userId: userId, role: role);
  }
}

