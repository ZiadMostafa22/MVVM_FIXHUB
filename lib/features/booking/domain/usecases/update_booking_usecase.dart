import 'package:car_maintenance_system_new/features/booking/domain/repositories/booking_repository.dart';

/// Use case to update a booking
class UpdateBookingUseCase {
  final BookingRepository repository;

  UpdateBookingUseCase(this.repository);

  Future<void> call(
    String bookingId,
    Map<String, dynamic> updates,
  ) async {
    await repository.updateBooking(bookingId, updates);
  }
}

