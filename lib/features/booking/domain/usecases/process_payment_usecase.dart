import 'package:car_maintenance_system_new/features/booking/domain/repositories/booking_repository.dart';
import 'package:car_maintenance_system_new/features/booking/domain/entities/booking_entity.dart';

/// Use case to process payment for a booking
class ProcessPaymentUseCase {
  final BookingRepository repository;

  ProcessPaymentUseCase(this.repository);

  Future<void> call({
    required String bookingId,
    required String cashierId,
    required PaymentMethod paymentMethod,
    double? totalCost,
  }) async {
    await repository.processPayment(
      bookingId: bookingId,
      cashierId: cashierId,
      paymentMethod: paymentMethod,
      totalCost: totalCost,
    );
  }
}

