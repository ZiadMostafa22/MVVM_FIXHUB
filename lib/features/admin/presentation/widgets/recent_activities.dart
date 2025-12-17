import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:car_maintenance_system_new/features/booking/presentation/viewmodels/booking_viewmodel.dart';
import 'package:car_maintenance_system_new/features/booking/domain/entities/booking_entity.dart';

class RecentActivities extends ConsumerWidget {
  const RecentActivities({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingState = ref.watch(bookingViewModelProvider);
    
    // Get recent bookings (last 10)
    final recentBookings = [...bookingState.bookings];
    recentBookings.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final displayBookings = recentBookings.take(10).toList();
    
    if (displayBookings.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Icon(
                Icons.timeline,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No recent activities',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Activities will appear here as they happen',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: displayBookings.map((booking) {
        final activity = _createActivityFromBooking(booking);
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: activity['color'].withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    activity['icon'],
                    color: activity['color'],
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity['title'],
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        activity['description'],
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        activity['time'],
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
  
  Map<String, dynamic> _createActivityFromBooking(BookingEntity booking) {
    String title;
    String description;
    IconData icon;
    Color color;
    
    switch (booking.status) {
      case BookingStatus.pending:
        title = 'New Booking';
        description = 'Booking created for ${_getMaintenanceTypeName(booking.maintenanceType)}';
        icon = Icons.book_online;
        color = Colors.orange;
        break;
      case BookingStatus.confirmed:
        title = 'Booking Confirmed';
        description = '${_getMaintenanceTypeName(booking.maintenanceType)} confirmed';
        icon = Icons.check_circle_outline;
        color = Colors.blue;
        break;
      case BookingStatus.inProgress:
        title = 'Service In Progress';
        description = '${_getMaintenanceTypeName(booking.maintenanceType)} is being serviced';
        icon = Icons.build;
        color = Colors.purple;
        break;
      case BookingStatus.completedPendingPayment:
        title = 'Awaiting Payment';
        description = '${_getMaintenanceTypeName(booking.maintenanceType)} completed, waiting for payment - \$${booking.totalCost.toStringAsFixed(2)}';
        icon = Icons.payment;
        color = Colors.deepPurple;
        break;
      case BookingStatus.completed:
        title = 'Service Completed';
        description = '${_getMaintenanceTypeName(booking.maintenanceType)} completed - \$${booking.totalCost.toStringAsFixed(2)}';
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case BookingStatus.cancelled:
        title = 'Booking Cancelled';
        description = '${_getMaintenanceTypeName(booking.maintenanceType)} was cancelled';
        icon = Icons.cancel;
        color = Colors.red;
        break;
    }
    
    return {
      'title': title,
      'description': description,
      'icon': icon,
      'color': color,
      'time': _getTimeAgo(booking.updatedAt),
    };
  }
  
  String _getMaintenanceTypeName(MaintenanceType type) {
    switch (type) {
      case MaintenanceType.regular:
        return 'Regular Maintenance';
      case MaintenanceType.inspection:
        return 'Inspection';
      case MaintenanceType.repair:
        return 'Repair';
      case MaintenanceType.emergency:
        return 'Emergency Service';
    }
  }
  
  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 7) {
      return DateFormat('MMM dd').format(dateTime);
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}
