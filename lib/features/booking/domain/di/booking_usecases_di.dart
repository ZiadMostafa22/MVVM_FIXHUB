import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:car_maintenance_system_new/features/booking/data/di/booking_di.dart';
import 'package:car_maintenance_system_new/features/booking/domain/usecases/get_bookings_usecase.dart';
import 'package:car_maintenance_system_new/features/booking/domain/usecases/watch_bookings_usecase.dart';
import 'package:car_maintenance_system_new/features/booking/domain/usecases/create_booking_usecase.dart';
import 'package:car_maintenance_system_new/features/booking/domain/usecases/update_booking_usecase.dart';
import 'package:car_maintenance_system_new/features/booking/domain/usecases/cancel_booking_usecase.dart';
import 'package:car_maintenance_system_new/features/booking/domain/usecases/rate_booking_usecase.dart';
import 'package:car_maintenance_system_new/features/booking/domain/usecases/process_payment_usecase.dart';

/// Get Bookings Use Case Provider
final getBookingsUseCaseProvider = Provider<GetBookingsUseCase>((ref) {
  final repository = ref.watch(bookingRepositoryProvider);
  return GetBookingsUseCase(repository);
});

/// Watch Bookings Use Case Provider
final watchBookingsUseCaseProvider = Provider<WatchBookingsUseCase>((ref) {
  final repository = ref.watch(bookingRepositoryProvider);
  return WatchBookingsUseCase(repository);
});

/// Create Booking Use Case Provider
final createBookingUseCaseProvider = Provider<CreateBookingUseCase>((ref) {
  final repository = ref.watch(bookingRepositoryProvider);
  return CreateBookingUseCase(repository);
});

/// Update Booking Use Case Provider
final updateBookingUseCaseProvider = Provider<UpdateBookingUseCase>((ref) {
  final repository = ref.watch(bookingRepositoryProvider);
  return UpdateBookingUseCase(repository);
});

/// Cancel Booking Use Case Provider
final cancelBookingUseCaseProvider = Provider<CancelBookingUseCase>((ref) {
  final repository = ref.watch(bookingRepositoryProvider);
  return CancelBookingUseCase(repository);
});

/// Rate Booking Use Case Provider
final rateBookingUseCaseProvider = Provider<RateBookingUseCase>((ref) {
  final repository = ref.watch(bookingRepositoryProvider);
  return RateBookingUseCase(repository);
});

/// Process Payment Use Case Provider
final processPaymentUseCaseProvider = Provider<ProcessPaymentUseCase>((ref) {
  final repository = ref.watch(bookingRepositoryProvider);
  return ProcessPaymentUseCase(repository);
});

