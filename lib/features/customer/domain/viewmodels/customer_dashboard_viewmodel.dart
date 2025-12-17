import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:car_maintenance_system_new/features/booking/presentation/viewmodels/booking_viewmodel.dart';
import 'package:car_maintenance_system_new/features/car/presentation/viewmodels/car_viewmodel.dart';
import 'package:car_maintenance_system_new/features/auth/presentation/viewmodels/auth_viewmodel.dart';

/// ViewModel for Customer Dashboard
/// Coordinates between booking and car ViewModels
class CustomerDashboardViewModel {
  final BookingViewModel bookingViewModel;
  final CarViewModel carViewModel;
  final AuthViewModel authViewModel;

  CustomerDashboardViewModel({
    required this.bookingViewModel,
    required this.carViewModel,
    required this.authViewModel,
  });

  /// Initialize dashboard data
  Future<void> initialize(String userId) async {
    // Start real-time listener for bookings
    bookingViewModel.startListening(userId);
    // Load cars (one-time)
    await carViewModel.loadCars(userId);
  }

  /// Refresh all data
  Future<void> refresh(String userId) async {
    await bookingViewModel.loadBookings(userId);
    await carViewModel.loadCars(userId);
  }

  /// Cleanup when dashboard is disposed
  void dispose() {
    bookingViewModel.stopListening();
  }
}

/// Provider for CustomerDashboardViewModel
final customerDashboardViewModelProvider = Provider<CustomerDashboardViewModel>((ref) {
  return CustomerDashboardViewModel(
    bookingViewModel: ref.read(bookingViewModelProvider.notifier),
    carViewModel: ref.read(carViewModelProvider.notifier),
    authViewModel: ref.read(authViewModelProvider.notifier),
  );
});

