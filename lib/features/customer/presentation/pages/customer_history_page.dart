import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:car_maintenance_system_new/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:car_maintenance_system_new/features/booking/presentation/viewmodels/booking_viewmodel.dart';
import 'package:car_maintenance_system_new/features/car/presentation/viewmodels/car_viewmodel.dart';
import 'package:car_maintenance_system_new/features/booking/domain/entities/booking_entity.dart';
import 'package:car_maintenance_system_new/core/utils/pdf_generator.dart';
import 'package:car_maintenance_system_new/core/widgets/rating_dialog.dart';
import 'package:car_maintenance_system_new/core/widgets/unified_filter_widget.dart';
import 'package:car_maintenance_system_new/core/widgets/detailed_invoice_dialog.dart';

class CustomerHistoryPage extends ConsumerStatefulWidget {
  const CustomerHistoryPage({super.key});

  @override
  ConsumerState<CustomerHistoryPage> createState() => _CustomerHistoryPageState();
}

class _CustomerHistoryPageState extends ConsumerState<CustomerHistoryPage> {
  String _selectedFilter = 'all';
  DateTimeRange? _dateRange;
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
    final user = ref.watch(authViewModelProvider).user;

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

    // Filter bookings by status - Create a mutable copy first
    List<BookingEntity> filteredBookings = List.from(bookingState.bookings);
    
    if (_selectedFilter != 'all') {
      filteredBookings = filteredBookings.where((booking) {
        switch (_selectedFilter) {
          case 'pending':
            return booking.status == BookingStatus.pending ||
                   booking.status == BookingStatus.confirmed;
          case 'in_progress':
            return booking.status == BookingStatus.inProgress;
          case 'completed':
            return booking.status == BookingStatus.completed;
          case 'cancelled':
            return booking.status == BookingStatus.cancelled;
          default:
            return true;
        }
      }).toList();
    }

    // Filter by date range
    if (_dateRange != null) {
      filteredBookings = filteredBookings.where((booking) {
        final bookingDate = DateTime(
          booking.scheduledDate.year,
          booking.scheduledDate.month,
          booking.scheduledDate.day,
        );
        final startDate = DateTime(
          _dateRange!.start.year,
          _dateRange!.start.month,
          _dateRange!.start.day,
        );
        final endDate = DateTime(
          _dateRange!.end.year,
          _dateRange!.end.month,
          _dateRange!.end.day,
        );
        return bookingDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
               bookingDate.isBefore(endDate.add(const Duration(days: 1)));
      }).toList();
    }

    // Sort by date, most recent first
    filteredBookings.sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate));

    // Calculate stats
    final totalSpent = bookingState.bookings
        .where((b) => b.status == BookingStatus.completed)
        .fold<double>(0, (sum, b) => sum + b.totalCost);

    final pendingCount = bookingState.bookings
        .where((b) => b.status == BookingStatus.pending || b.status == BookingStatus.confirmed)
        .length;

    final inProgressCount = bookingState.bookings
        .where((b) => b.status == BookingStatus.inProgress)
        .length;

    final completedCount = bookingState.bookings
        .where((b) => b.status == BookingStatus.completed)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Service History'),
        actions: [
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Unified Filter Widget
          UnifiedFilterWidget(
            selectedFilter: _selectedFilter,
            dateRange: _dateRange,
            filterOptions: FilterOptions.bookingStatus,
            onFilterChanged: (value) {
              setState(() {
                _selectedFilter = value;
              });
            },
            onDateRangeChanged: (range) {
              setState(() {
                _dateRange = range;
              });
            },
            showDateFilter: true,
            showStatusFilter: true,
          ),
          // Stats Card
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        const Icon(Icons.pending_actions, color: Colors.orange, size: 28),
                        const SizedBox(height: 4),
                        Text(
                          pendingCount.toString(),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        Text(
                          'Pending',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 50, color: Colors.grey[300]),
                  Expanded(
                    child: Column(
                      children: [
                        const Icon(Icons.build, color: Colors.blue, size: 28),
                        const SizedBox(height: 4),
                        Text(
                          inProgressCount.toString(),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        Text(
                          'In Progress',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 50, color: Colors.grey[300]),
                  Expanded(
                    child: Column(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 28),
                        const SizedBox(height: 4),
                        Text(
                          completedCount.toString(),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        Text(
                          'Completed',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 50, color: Colors.grey[300]),
                  Expanded(
                    child: Column(
                      children: [
                        const Icon(Icons.attach_money, color: Colors.purple, size: 28),
                        const SizedBox(height: 4),
                        Text(
                          '\$${totalSpent.toStringAsFixed(0)}',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.purple,
                          ),
                        ),
                        Text(
                          'Total Spent',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // History List
          Expanded(
            child: bookingState.isLoading || carState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredBookings.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
            Text(
                              'No service history',
              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Your service history will appear here',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredBookings.length,
                        itemBuilder: (context, index) {
                          final booking = filteredBookings[index];
                          final car = carState.cars
                              .where((c) => c.id == booking.carId)
                              .firstOrNull;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              onTap: () => _showInvoiceDetails(context, booking, car, user),
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
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(booking.status)
                                                .withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            _getStatusName(booking.status),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: _getStatusColor(booking.status),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      car != null 
                                          ? '${car.make} ${car.model} (${car.year})'
                                          : 'Loading...',
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.calendar_today,
                                            size: 14, color: Colors.grey[600]),
                                        const SizedBox(width: 4),
                                        Text(
                                          DateFormat('MMM dd, yyyy')
                                              .format(booking.scheduledDate),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(color: Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                                    if (booking.status == BookingStatus.completed) ...[
                                      const Divider(height: 20),
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
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: Colors.green.withOpacity(0.3)),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text(
                                                'Total Cost:',
                                                style: TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    '\$${booking.totalCost.toStringAsFixed(2)}',
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.green,
                                                      fontSize: 18,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  const Icon(
                                                    Icons.receipt_long,
                                                    color: Colors.green,
                                                    size: 20,
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      // Rating section
                                      if (booking.rating != null) ...[
                                        Row(
                                          children: [
                                            const Text('Your Rating: '),
                                            RatingBarIndicator(
                                              rating: booking.rating!,
                                              itemBuilder: (context, index) => const Icon(
                                                Icons.star,
                                                color: Colors.amber,
                                              ),
                                              itemCount: 5,
                                              itemSize: 20.0,
                                              direction: Axis.horizontal,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              booking.rating!.toStringAsFixed(1),
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                        if (booking.ratingComment != null && booking.ratingComment!.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 4),
                                            child: Text(
                                              '"${booking.ratingComment}"',
                                              style: const TextStyle(fontStyle: FontStyle.italic),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        const SizedBox(height: 8),
                                      ],
                                      // Rate Service Button (if not rated yet)
                                      if (booking.rating == null) ...[
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton.icon(
                                            onPressed: () {
                                              // Capture the ScaffoldMessenger before showing dialog
                                              final scaffoldMessenger = ScaffoldMessenger.of(context);
                                              
                                              showDialog(
                                                context: context,
                                                builder: (dialogContext) => RatingDialog(
                                                  onSubmit: (rating, comment) async {
                                                    final success = await ref
                                                        .read(bookingViewModelProvider.notifier)
                                                        .rateBooking(booking.id, rating, comment);
                                                    
                                                    // Use the captured ScaffoldMessenger instead of context
                                                    scaffoldMessenger.showSnackBar(
                                                      SnackBar(
                                                        content: Text(success
                                                            ? 'Rating submitted successfully!'
                                                            : 'Failed to submit rating'),
                                                        backgroundColor: success ? Colors.green : Colors.red,
                                                      ),
                                                    );
                                                  },
                                                ),
                                              );
                                            },
                                            icon: const Icon(Icons.star, size: 18),
                                            label: const Text('Rate This Service'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.amber,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
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
      case BookingStatus.pending:
        return Colors.orange;
      case BookingStatus.confirmed:
        return Colors.blue;
      case BookingStatus.inProgress:
        return Colors.purple;
      case BookingStatus.completedPendingPayment:
        return Colors.deepPurple;
      case BookingStatus.completed:
        return Colors.green;
      case BookingStatus.cancelled:
        return Colors.red;
    }
  }

  void _showInvoiceDetails(BuildContext context, BookingEntity booking, var car, var user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invoice Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Booking ID: ${booking.id}'),
              Text('Vehicle: ${car != null ? "${car.make} ${car.model}" : "Loading..."}'),
              Text('Date: ${DateFormat('MMM dd, yyyy').format(booking.scheduledDate)}'),
              const Divider(height: 20),
              const Text('Service Items:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (booking.serviceItems != null && booking.serviceItems!.isNotEmpty)
                ...booking.serviceItems!.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text('${item.name} x${item.quantity}'),
                          ),
                          Text('\$${item.totalPrice.toStringAsFixed(2)}'),
                        ],
                      ),
                    ))
              else
                const Text('No items'),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Labor Cost:'),
                  Text('\$${(booking.laborCost ?? 0).toStringAsFixed(2)}'),
                ],
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Subtotal:'),
                  Text('\$${booking.subtotal.toStringAsFixed(2)}'),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tax (10%):'),
                  Text('\$${((booking.tax ?? (booking.subtotal * 0.10))).toStringAsFixed(2)}'),
                ],
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Text(
                    '\$${booking.totalCost.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.green),
                  ),
                ],
              ),
              if (booking.technicianNotes != null &&
                  booking.technicianNotes!.isNotEmpty) ...[
                const Divider(height: 20),
                const Text('Technician Notes:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(booking.technicianNotes!),
              ],
            ],
          ),
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await PdfGenerator.generateAndShareInvoice(
                context,
                booking,
                car,
                user,
              );
            },
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Download PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
