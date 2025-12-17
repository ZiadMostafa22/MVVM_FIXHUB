import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:car_maintenance_system_new/features/booking/domain/repositories/booking_repository.dart';
import 'package:car_maintenance_system_new/features/booking/domain/entities/booking_entity.dart';
import 'package:car_maintenance_system_new/features/booking/data/datasources/booking_remote_datasource.dart';
import 'package:car_maintenance_system_new/features/booking/data/models/booking_dto.dart';

/// Implementation of BookingRepository
class BookingRepositoryImpl implements BookingRepository {
  final BookingRemoteDataSource remoteDataSource;

  BookingRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<BookingEntity>> loadBookings({
    required String userId,
    String? role,
  }) async {
    final dataList = await remoteDataSource.loadBookings(
      userId: userId,
      role: role,
    );

    var entities = dataList
        .map((data) => BookingDto.fromFirestore(
              data,
              data['id'] as String,
            ).toEntity())
        .toList();

    // Sort in memory if we didn't use orderBy in the query
    if (role != 'admin' && role != 'technician' && role != 'cashier') {
      entities.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return entities;
  }

  @override
  Stream<List<BookingEntity>> watchBookings({
    required String userId,
    String? role,
  }) {
    return remoteDataSource.watchBookings(userId: userId, role: role).map(
      (dataList) {
        var entities = dataList
            .map((data) => BookingDto.fromFirestore(
                  data,
                  data['id'] as String,
                ).toEntity())
            .toList();

        // Sort in memory if we didn't use orderBy in the query
        if (role != 'admin' && role != 'technician' && role != 'cashier') {
          entities.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        }

        return entities;
      },
    );
  }

  @override
  Future<String> createBooking(BookingEntity booking) async {
    final dto = BookingDto.fromEntity(booking);
    return await remoteDataSource.createBooking(dto.toFirestore());
  }

  @override
  Future<void> updateBooking(
    String bookingId,
    Map<String, dynamic> updates,
  ) async {
    await remoteDataSource.updateBooking(bookingId, updates);
  }

  @override
  Future<BookingEntity?> getBookingById(String bookingId) async {
    final data = await remoteDataSource.getBookingById(bookingId);
    if (data == null) return null;
    return BookingDto.fromFirestore(data, bookingId).toEntity();
  }

  @override
  Future<void> updateBookingStatus(
    String bookingId,
    BookingStatus status, {
    DateTime? completedAt,
  }) async {
    final updates = <String, dynamic>{
      'status': status.toString().split('.').last,
      'updatedAt': Timestamp.now(),
    };

    if (completedAt != null) {
      updates['completedAt'] = Timestamp.fromDate(completedAt);
    }

    await updateBooking(bookingId, updates);
  }

  @override
  Future<void> rateBooking({
    required String bookingId,
    required double rating,
    required String comment,
  }) async {
    await remoteDataSource.rateBooking(
      bookingId: bookingId,
      rating: rating,
      comment: comment,
    );
  }

  @override
  Future<void> processPayment({
    required String bookingId,
    required String cashierId,
    required PaymentMethod paymentMethod,
    double? totalCost,
  }) async {
    await remoteDataSource.processPayment(
      bookingId: bookingId,
      cashierId: cashierId,
      paymentMethod: paymentMethod.toString().split('.').last,
      totalCost: totalCost,
    );
  }
}

