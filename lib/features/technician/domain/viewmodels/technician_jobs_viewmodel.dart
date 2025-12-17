import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:car_maintenance_system_new/features/booking/presentation/viewmodels/booking_viewmodel.dart';
import 'package:car_maintenance_system_new/features/car/presentation/viewmodels/car_viewmodel.dart';

/// ViewModel for Technician Jobs Page
class TechnicianJobsViewModel {
  final BookingViewModel bookingViewModel;
  final CarViewModel carViewModel;

  TechnicianJobsViewModel({
    required this.bookingViewModel,
    required this.carViewModel,
  });

  /// Initialize jobs page data
  Future<void> initialize(String userId) async {
    // Start real-time listener for all bookings
    bookingViewModel.startListening(userId, role: 'technician');
    // Load all cars
    await carViewModel.loadCars('');
  }

  /// Update booking status
  Future<bool> updateBookingStatus(
    String bookingId,
    status, {
    DateTime? completedAt,
  }) async {
    return await bookingViewModel.updateBookingStatus(
      bookingId,
      status,
      completedAt: completedAt,
    );
  }

  /// Update booking
  Future<bool> updateBooking(String bookingId, Map<String, dynamic> updates) async {
    return await bookingViewModel.updateBooking(bookingId, updates);
  }

  /// Cleanup when page is disposed
  void dispose() {
    bookingViewModel.stopListening();
  }
}

/// Provider for TechnicianJobsViewModel
final technicianJobsViewModelProvider = Provider<TechnicianJobsViewModel>((ref) {
  return TechnicianJobsViewModel(
    bookingViewModel: ref.read(bookingViewModelProvider.notifier),
    carViewModel: ref.read(carViewModelProvider.notifier),
  );
});

