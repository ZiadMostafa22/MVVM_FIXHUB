import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:car_maintenance_system_new/features/booking/presentation/viewmodels/booking_viewmodel.dart';
import 'package:car_maintenance_system_new/features/car/presentation/viewmodels/car_viewmodel.dart';
import 'package:car_maintenance_system_new/features/booking/domain/entities/booking_entity.dart';
import 'package:car_maintenance_system_new/core/widgets/detailed_invoice_dialog.dart';

class ActiveServices extends ConsumerWidget {
  const ActiveServices({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingState = ref.watch(bookingViewModelProvider);
    final carState = ref.watch(carViewModelProvider);

    // Filter for active services: inProgress or completedPendingPayment
    final activeBookings = bookingState.bookings.where((booking) {
      return booking.status == BookingStatus.inProgress || 
             booking.status == BookingStatus.completedPendingPayment;
    }).toList();

    if (activeBookings.isEmpty) {
      return const SizedBox.shrink(); // Don't show anything if no active services
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          children: [
            Icon(
              Icons.engineering,
              color: Theme.of(context).primaryColor,
              size: 20.sp,
            ),
            SizedBox(width: 8.w),
            Text(
              'Active Services',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 18.sp,
              ),
            ),
            const Spacer(),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                '${activeBookings.length}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        ...activeBookings.map((booking) {
        // Find the car for this booking
        final car = carState.cars.where((c) => c.id == booking.carId).firstOrNull;
        
        // Skip this booking if car is not found
        if (car == null) {
          return const SizedBox.shrink();
        }

        return Card(
          margin: EdgeInsets.only(bottom: 12.h),
          elevation: 3,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: booking.status == BookingStatus.completedPendingPayment
                    ? [
                        Colors.deepPurple.shade50,
                        Colors.purple.shade50,
                      ]
                    : [
                        Colors.blue.shade50,
                        Colors.lightBlue.shade50,
                      ],
              ),
            ),
            child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Badge
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                          decoration: BoxDecoration(
                            color: _getStatusColor(booking.status),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getStatusIcon(booking.status),
                                size: 14.sp,
                                color: Colors.white,
                              ),
                              SizedBox(width: 6.w),
                              Text(
                                _getStatusText(booking.status),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        if (booking.status == BookingStatus.completedPendingPayment)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.payment, size: 12.sp, color: Colors.white),
                                SizedBox(width: 4.w),
                                Text(
                                  'Payment Due',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    
                    SizedBox(height: 12.h),
                    
                    // Car Info
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.white,
                          radius: 24.r,
                          child: Icon(
                            Icons.directions_car,
                            color: Theme.of(context).primaryColor,
                            size: 28.sp,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${car.make} ${car.model}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.sp,
                                ),
                              ),
                              Text(
                                car.licensePlate,
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 13.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 12.h),
                    Divider(height: 1.h, color: Colors.grey.shade300),
                    SizedBox(height: 12.h),
                    
                    // Service Type & Date
                    Row(
                      children: [
                        Icon(Icons.build, size: 16.sp, color: Colors.grey[600]),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            _getMaintenanceTypeName(booking.maintenanceType),
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 16.sp, color: Colors.grey[600]),
                        SizedBox(width: 8.w),
                        Text(
                          DateFormat('dd MMM yyyy, HH:mm').format(booking.scheduledDate),
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                    
                    // Show total cost if completed and pending payment
                    if (booking.status == BookingStatus.completedPendingPayment) ...[
                      SizedBox(height: 12.h),
                      GestureDetector(
                        onTap: () {
                          final car = carState.cars.where((c) => c.id == booking.carId).firstOrNull;
                          showDialog(
                            context: context,
                            builder: (context) => DetailedInvoiceDialog(
                              booking: booking,
                              car: car,
                            ),
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total Amount',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Row(
                                    children: [
                                      Text(
                                        '\$${booking.totalCost.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 20.sp,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                      SizedBox(width: 8.w),
                                      Icon(
                                        Icons.receipt_long,
                                        size: 16.sp,
                                        color: Colors.green,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 16.sp,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    
                    // Show progress message if in progress
                    if (booking.status == BookingStatus.inProgress) ...[
                      SizedBox(height: 12.h),
                      Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 20.w,
                              height: 20.h,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.blue.shade700,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Text(
                                'Our technician is working on your vehicle',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.blue.shade900,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
      }),
      ],
    );
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.inProgress:
        return Colors.blue;
      case BookingStatus.completedPendingPayment:
        return Colors.deepPurple;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(BookingStatus status) {
    switch (status) {
      case BookingStatus.inProgress:
        return Icons.build_circle;
      case BookingStatus.completedPendingPayment:
        return Icons.check_circle;
      default:
        return Icons.info;
    }
  }

  String _getStatusText(BookingStatus status) {
    switch (status) {
      case BookingStatus.inProgress:
        return 'Service in Progress';
      case BookingStatus.completedPendingPayment:
        return 'Service Completed';
      default:
        return 'Unknown';
    }
  }

  String _getMaintenanceTypeName(MaintenanceType type) {
    switch (type) {
      case MaintenanceType.regular:
        return 'Regular Maintenance';
      case MaintenanceType.repair:
        return 'Repair Service';
      case MaintenanceType.inspection:
        return 'Inspection';
      case MaintenanceType.emergency:
        return 'Emergency Service';
    }
  }
}
