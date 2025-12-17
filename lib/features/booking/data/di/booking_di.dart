import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:car_maintenance_system_new/features/booking/data/datasources/booking_remote_datasource.dart';
import 'package:car_maintenance_system_new/features/booking/data/repositories/booking_repository_impl.dart';
import 'package:car_maintenance_system_new/features/booking/domain/repositories/booking_repository.dart';

/// Booking Remote Data Source Provider
final bookingRemoteDataSourceProvider = Provider<BookingRemoteDataSource>((ref) {
  return BookingRemoteDataSource();
});

/// Booking Repository Provider (binds interface to implementation)
final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  final remoteDataSource = ref.watch(bookingRemoteDataSourceProvider);
  return BookingRepositoryImpl(remoteDataSource);
});

