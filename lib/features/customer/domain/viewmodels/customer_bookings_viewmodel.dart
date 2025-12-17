import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:car_maintenance_system_new/features/booking/presentation/viewmodels/booking_viewmodel.dart';

/// ViewModel for Customer Bookings Page
/// Wraps BookingViewModel for customer-specific operations
class CustomerBookingsViewModel {
  final BookingViewModel bookingViewModel;

  CustomerBookingsViewModel({required this.bookingViewModel});

  /// Load customer's bookings
  Future<void> loadBookings(String userId) async {
    await bookingViewModel.loadBookings(userId);
  }

  /// Start listening to real-time updates
  void startListening(String userId) {
    bookingViewModel.startListening(userId);
  }

  /// Stop listening to real-time updates
  void stopListening() {
    bookingViewModel.stopListening();
  }

  /// Cancel a booking
  Future<bool> cancelBooking(String bookingId) async {
    return await bookingViewModel.cancelBooking(bookingId);
  }

  /// Rate a booking
  Future<bool> rateBooking(String bookingId, double rating, String comment) async {
    return await bookingViewModel.rateBooking(bookingId, rating, comment);
  }
}

/// Provider for CustomerBookingsViewModel
final customerBookingsViewModelProvider = Provider<CustomerBookingsViewModel>((ref) {
  return CustomerBookingsViewModel(
    bookingViewModel: ref.read(bookingViewModelProvider.notifier),
  );
});

