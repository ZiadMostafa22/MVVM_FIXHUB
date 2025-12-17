import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:car_maintenance_system_new/features/booking/presentation/viewmodels/booking_viewmodel.dart';
import 'package:car_maintenance_system_new/features/booking/domain/entities/booking_entity.dart';

/// ViewModel for Cashier Payments Page
class CashierPaymentsViewModel {
  final BookingViewModel bookingViewModel;

  CashierPaymentsViewModel({required this.bookingViewModel});

  /// Initialize payments page data
  Future<void> initialize(String userId) async {
    // Start real-time listener for all bookings
    bookingViewModel.startListening(userId, role: 'cashier');
  }

  /// Process payment for a booking
  Future<bool> processPayment({
    required String bookingId,
    required String cashierId,
    required PaymentMethod paymentMethod,
  }) async {
    return await bookingViewModel.processPayment(
      bookingId: bookingId,
      cashierId: cashierId,
      paymentMethod: paymentMethod,
    );
  }

  /// Cleanup when page is disposed
  void dispose() {
    bookingViewModel.stopListening();
  }
}

/// Provider for CashierPaymentsViewModel
final cashierPaymentsViewModelProvider = Provider<CashierPaymentsViewModel>((ref) {
  return CashierPaymentsViewModel(
    bookingViewModel: ref.read(bookingViewModelProvider.notifier),
  );
});

