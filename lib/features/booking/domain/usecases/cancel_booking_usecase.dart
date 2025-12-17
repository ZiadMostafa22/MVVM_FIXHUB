import 'package:car_maintenance_system_new/features/booking/domain/repositories/booking_repository.dart';
import 'package:car_maintenance_system_new/features/booking/domain/entities/booking_entity.dart';

/// Use case to cancel a booking
class CancelBookingUseCase {
  final BookingRepository repository;

  CancelBookingUseCase(this.repository);

  Future<void> call(String bookingId) async {
    await repository.updateBookingStatus(
      bookingId,
      BookingStatus.cancelled,
    );
  }
}

