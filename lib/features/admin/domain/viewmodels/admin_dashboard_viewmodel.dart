import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:car_maintenance_system_new/features/booking/presentation/viewmodels/booking_viewmodel.dart';
import 'package:car_maintenance_system_new/features/car/presentation/viewmodels/car_viewmodel.dart';

/// ViewModel for Admin Dashboard
/// Coordinates between booking and car ViewModels for admin view
class AdminDashboardViewModel {
  final BookingViewModel bookingViewModel;
  final CarViewModel carViewModel;

  AdminDashboardViewModel({
    required this.bookingViewModel,
    required this.carViewModel,
  });

  /// Initialize dashboard data
  Future<void> initialize(String userId) async {
    // Start real-time listener for all bookings
    bookingViewModel.startListening(userId, role: 'admin');
    // Load all cars
    await carViewModel.loadCars('');
  }

  /// Refresh all data
  Future<void> refresh() async {
    await bookingViewModel.loadBookings('', role: 'admin');
    await carViewModel.loadCars('');
  }

  /// Cleanup when dashboard is disposed
  void dispose() {
    bookingViewModel.stopListening();
  }
}

/// Provider for AdminDashboardViewModel
final adminDashboardViewModelProvider = Provider<AdminDashboardViewModel>((ref) {
  return AdminDashboardViewModel(
    bookingViewModel: ref.read(bookingViewModelProvider.notifier),
    carViewModel: ref.read(carViewModelProvider.notifier),
  );
});

