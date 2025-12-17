import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:car_maintenance_system_new/features/booking/presentation/viewmodels/booking_viewmodel.dart';
import 'package:car_maintenance_system_new/features/car/presentation/viewmodels/car_viewmodel.dart';

/// ViewModel for Technician Dashboard
class TechnicianDashboardViewModel {
  final BookingViewModel bookingViewModel;
  final CarViewModel carViewModel;

  TechnicianDashboardViewModel({
    required this.bookingViewModel,
    required this.carViewModel,
  });

  /// Initialize dashboard data
  Future<void> initialize(String userId) async {
    // Start real-time listener for all bookings
    bookingViewModel.startListening(userId, role: 'technician');
    // Load all cars
    await carViewModel.loadCars('');
  }

  /// Refresh all data
  Future<void> refresh(String userId) async {
    await bookingViewModel.loadBookings(userId, role: 'technician');
    await carViewModel.loadCars('');
  }

  /// Cleanup when dashboard is disposed
  void dispose() {
    bookingViewModel.stopListening();
  }
}

/// Provider for TechnicianDashboardViewModel
final technicianDashboardViewModelProvider = Provider<TechnicianDashboardViewModel>((ref) {
  return TechnicianDashboardViewModel(
    bookingViewModel: ref.read(bookingViewModelProvider.notifier),
    carViewModel: ref.read(carViewModelProvider.notifier),
  );
});

