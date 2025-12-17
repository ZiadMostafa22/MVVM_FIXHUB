import 'package:car_maintenance_system_new/features/booking/domain/repositories/booking_repository.dart';
import 'package:car_maintenance_system_new/features/booking/domain/entities/booking_entity.dart';

/// Use case to create a new booking
class CreateBookingUseCase {
  final BookingRepository repository;

  CreateBookingUseCase(this.repository);

  Future<String> call(BookingEntity booking) async {
    return await repository.createBooking(booking);
  }
}

