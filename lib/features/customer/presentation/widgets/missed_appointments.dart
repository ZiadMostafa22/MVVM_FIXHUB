import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:car_maintenance_system_new/features/booking/presentation/viewmodels/booking_viewmodel.dart';
import 'package:car_maintenance_system_new/features/car/presentation/viewmodels/car_viewmodel.dart';
import 'package:car_maintenance_system_new/features/booking/domain/entities/booking_entity.dart';

class MissedAppointments extends ConsumerStatefulWidget {
  const MissedAppointments({super.key});

  @override
  ConsumerState<MissedAppointments> createState() => _MissedAppointmentsState();
}

class _MissedAppointmentsState extends ConsumerState<MissedAppointments> {
  final Set<String> _fetchingCars = {};

  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(bookingViewModelProvider);
    final carState = ref.watch(carViewModelProvider);
    
    // Fetch missing cars when bookings change
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final booking in bookingState.bookings) {
        if (booking.carId.isNotEmpty) {
          final carExists = carState.cars.any((c) => c.id == booking.carId);
          if (!carExists && !_fetchingCars.contains(booking.carId)) {
            _fetchingCars.add(booking.carId);
            ref.read(carViewModelProvider.notifier).getCarById(booking.carId).then((_) {
              if (mounted) {
                setState(() {
                  _fetchingCars.remove(booking.carId);
                });
              } else {
                _fetchingCars.remove(booking.carId);
              }
            });
          }
        }
      }
    });
    
    final now = DateTime.now();
    
    // Filter missed bookings (pending or confirmed but past scheduled date)
    final missedBookings = bookingState.bookings.where((booking) {
      return (booking.status == BookingStatus.pending ||
              booking.status == BookingStatus.confirmed) &&
             booking.scheduledDate.isBefore(now);
    }).toList();
    
    // Sort by scheduled date (most recent first)
    missedBookings.sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate));
    
    // Show only last 2 missed
    final displayBookings = missedBookings.take(2).toList();

    // Don't show the section if no missed appointments
    if (displayBookings.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.red,
              size: 20.sp,
            ),
            SizedBox(width: 8.w),
            Text(
              'Missed Appointments',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 18.sp,
                color: Colors.red.shade700,
              ),
            ),
            const Spacer(),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                '${missedBookings.length}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Text(
          'You missed these appointments. Please reschedule or cancel them.',
          style: TextStyle(
            color: Colors.red.shade600,
            fontSize: 12.sp,
          ),
        ),
        SizedBox(height: 16.h),
        
        ...displayBookings.map((booking) {
          final car = carState.cars.where((c) => c.id == booking.carId).firstOrNull;
          final carName = car != null ? '${car.make} ${car.model}' : 'Loading...';
          
          // Calculate how long ago it was missed
          final missedDuration = now.difference(booking.scheduledDate);
          final missedText = missedDuration.inDays > 0
              ? '${missedDuration.inDays} day${missedDuration.inDays > 1 ? 's' : ''} ago'
              : missedDuration.inHours > 0
                  ? '${missedDuration.inHours} hour${missedDuration.inHours > 1 ? 's' : ''} ago'
                  : 'Recently';
          
          return Card(
            margin: EdgeInsets.only(bottom: 12.h),
            color: Colors.red.shade50,
            elevation: 2,
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Icon(
                          Icons.event_busy,
                          color: Colors.red.shade700,
                          size: 24.sp,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getMaintenanceTypeName(booking.maintenanceType),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15.sp,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              carName,
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 13.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          'MISSED',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.schedule, size: 14.sp, color: Colors.red.shade700),
                        SizedBox(width: 6.w),
                        Text(
                          'Was scheduled: ${DateFormat('MMM dd, yyyy').format(booking.scheduledDate)} at ${booking.timeSlot}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14.sp, color: Colors.grey),
                      SizedBox(width: 6.w),
                      Text(
                        'Missed $missedText',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // Go to new booking page
                            context.push('/customer/new-booking');
                          },
                          icon: Icon(Icons.refresh, size: 16.sp),
                          label: const Text('Reschedule'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue,
                            padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
                            side: const BorderSide(color: Colors.blue),
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            // Show simple loading
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (ctx) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                            
                            try {
                              // Quick cancellation with immediate UI update
                              final success = await ref.read(bookingViewModelProvider.notifier).cancelBooking(
                                booking.id,
                              );
                              
                              // Close loading immediately
                              if (context.mounted) {
                                Navigator.of(context).pop();
                              }
                              
                              // Show result immediately
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      success 
                                        ? 'Appointment cancelled successfully'
                                        : 'Failed to cancel appointment. Please try again.',
                                    ),
                                    backgroundColor: success ? Colors.green : Colors.red,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            } catch (e) {
                              print('❌ Cancellation error: $e');
                              
                              // Close loading immediately
                              if (context.mounted) {
                                Navigator.of(context).pop();
                              }
                              
                              // Show error
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error cancelling appointment: ${e.toString()}'),
                                    backgroundColor: Colors.red,
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                              }
                            }
                          },
                          icon: Icon(Icons.cancel, size: 16.sp),
                          label: const Text('Cancel'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
                            side: const BorderSide(color: Colors.red),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
        SizedBox(height: 24.h),
      ],
    );
  }

  String _getMaintenanceTypeName(MaintenanceType type) {
    switch (type) {
      case MaintenanceType.regular:
        return 'Regular Maintenance';
      case MaintenanceType.inspection:
        return 'Inspection';
      case MaintenanceType.repair:
        return 'Repair Service';
      case MaintenanceType.emergency:
        return 'Emergency Service';
    }
  }
}
