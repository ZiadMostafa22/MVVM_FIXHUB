import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:car_maintenance_system_new/features/booking/presentation/viewmodels/booking_viewmodel.dart';

/// ViewModel for Cashier Dashboard
class CashierDashboardViewModel {
  final BookingViewModel bookingViewModel;

  CashierDashboardViewModel({required this.bookingViewModel});

  /// Initialize dashboard data
  Future<void> initialize(String userId) async {
    // Start real-time listener for all bookings
    bookingViewModel.startListening(userId, role: 'cashier');
  }

  /// Refresh all data
  Future<void> refresh(String userId) async {
    await bookingViewModel.loadBookings(userId, role: 'cashier');
  }

  /// Cleanup when dashboard is disposed
  void dispose() {
    bookingViewModel.stopListening();
  }
}

/// Provider for CashierDashboardViewModel
final cashierDashboardViewModelProvider = Provider<CashierDashboardViewModel>((ref) {
  return CashierDashboardViewModel(
    bookingViewModel: ref.read(bookingViewModelProvider.notifier),
  );
});

