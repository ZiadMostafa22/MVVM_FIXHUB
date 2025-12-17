import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:car_maintenance_system_new/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:car_maintenance_system_new/features/booking/presentation/viewmodels/booking_viewmodel.dart';
import 'package:car_maintenance_system_new/features/car/presentation/viewmodels/car_viewmodel.dart';
import 'package:car_maintenance_system_new/features/booking/domain/entities/booking_entity.dart';

class CustomerBookingsPage extends ConsumerStatefulWidget {
  const CustomerBookingsPage({super.key});

  @override
  ConsumerState<CustomerBookingsPage> createState() => _CustomerBookingsPageState();
}

class _CustomerBookingsPageState extends ConsumerState<CustomerBookingsPage> {
  final Set<String> _fetchingCars = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  Future<void> _refreshData() async {
    final user = ref.read(authViewModelProvider).user;
    if (user != null) {
      await ref.read(bookingViewModelProvider.notifier).loadBookings(user.id);
      await ref.read(carViewModelProvider.notifier).loadCars(user.id);
    }
  }

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
    
    // Sort bookings by scheduled date (newest first)
    final sortedBookings = List.from(bookingState.bookings);
    sortedBookings.sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate));

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              context.go('/customer/new-booking');
            },
          ),
        ],
      ),
      body: bookingState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : sortedBookings.isEmpty
              ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
                      const Icon(
              Icons.book_online,
              size: 64,
              color: Colors.grey,
            ),
                      const SizedBox(height: 16),
                      const Text(
              'No bookings yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
                      const SizedBox(height: 8),
                      const Text(
              'Book your first service',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => context.go('/customer/new-booking'),
                        icon: const Icon(Icons.add),
                        label: const Text('New Booking'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: sortedBookings.length,
                  itemBuilder: (context, index) {
                    final booking = sortedBookings[index];
                    
                    // Get car info
                    final car = carState.cars.where((c) => c.id == booking.carId).firstOrNull;
                    final carName = car != null ? '${car.make} ${car.model}' : 'Loading...';
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: InkWell(
                        onTap: () {
                          _showBookingDetails(context, booking, carName);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      _getMaintenanceTypeName(booking.maintenanceType),
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(booking.status).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      _getStatusName(booking.status),
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: _getStatusColor(booking.status),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(Icons.directions_car, size: 16, color: Colors.grey[600]),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      carName,
                                      style: Theme.of(context).textTheme.bodyMedium,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                                  const SizedBox(width: 8),
                                  Text(
                                    DateFormat('MMM dd, yyyy').format(booking.scheduledDate),
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  const SizedBox(width: 16),
                                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                                  const SizedBox(width: 8),
                                  Text(
                                    booking.timeSlot,
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                              if (booking.description != null && booking.description!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        booking.description!,
                                        style: Theme.of(context).textTheme.bodySmall,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if (booking.status == BookingStatus.pending) ...[
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      onPressed: () => _cancelBooking(booking.id),
                                      icon: const Icon(Icons.cancel, size: 16),
                                      label: const Text('Cancel'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  void _showBookingDetails(BuildContext context, BookingEntity booking, String carName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_getMaintenanceTypeName(booking.maintenanceType)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Car', carName),
              _buildDetailRow('Date', DateFormat('MMM dd, yyyy').format(booking.scheduledDate)),
              _buildDetailRow('Time', booking.timeSlot),
              _buildDetailRow('Status', _getStatusName(booking.status)),
              if (booking.description != null && booking.description!.isNotEmpty)
                _buildDetailRow('Description', booking.description!),
              if (booking.notes != null && booking.notes!.isNotEmpty)
                _buildDetailRow('Notes', booking.notes!),
              if (booking.completedAt != null)
                _buildDetailRow('Completed', DateFormat('MMM dd, yyyy').format(booking.completedAt!)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelBooking(String bookingId) async {
    // Capture the ScaffoldMessenger before showing dialog
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text('Are you sure you want to cancel this booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref.read(bookingViewModelProvider.notifier).cancelBooking(bookingId);
      
      // Use the captured ScaffoldMessenger instead of context
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(success ? 'Booking cancelled' : 'Failed to cancel booking'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
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

  String _getStatusName(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.inProgress:
        return 'In Progress';
      case BookingStatus.completedPendingPayment:
        return 'Awaiting Payment';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.confirmed:
        return Colors.green;
      case BookingStatus.pending:
        return Colors.orange;
      case BookingStatus.inProgress:
        return Colors.blue;
      case BookingStatus.completedPendingPayment:
        return Colors.deepPurple;
      case BookingStatus.completed:
        return Colors.green;
      case BookingStatus.cancelled:
        return Colors.red;
    }
  }
}

