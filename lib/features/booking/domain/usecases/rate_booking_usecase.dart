import 'package:car_maintenance_system_new/features/booking/domain/repositories/booking_repository.dart';

/// Use case to rate a booking
class RateBookingUseCase {
  final BookingRepository repository;

  RateBookingUseCase(this.repository);

  Future<void> call({
    required String bookingId,
    required double rating,
    required String comment,
  }) async {
    await repository.rateBooking(
      bookingId: bookingId,
      rating: rating,
      comment: comment,
    );
  }
}

