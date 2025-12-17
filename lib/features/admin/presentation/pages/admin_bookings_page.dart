import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:car_maintenance_system_new/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:car_maintenance_system_new/features/booking/presentation/viewmodels/booking_viewmodel.dart';
import 'package:car_maintenance_system_new/features/car/presentation/viewmodels/car_viewmodel.dart';
import 'package:car_maintenance_system_new/features/booking/domain/entities/booking_entity.dart';
import 'package:car_maintenance_system_new/features/car/domain/entities/car_entity.dart';
import 'package:car_maintenance_system_new/core/utils/pdf_generator.dart';

class AdminBookingsPage extends ConsumerStatefulWidget {
  const AdminBookingsPage({super.key});

  @override
  ConsumerState<AdminBookingsPage> createState() => _AdminBookingsPageState();
}

class _AdminBookingsPageState extends ConsumerState<AdminBookingsPage> {
  String _selectedFilter = 'all';
  DateTimeRange? _dateRange;
  final Map<String, Map<String, String>> _usersCache = {}; // userId -> {name, phone}
  final Set<String> _fetchingCars = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authViewModelProvider).user;
      if (user != null) {
        // Start real-time listener for all bookings
        ref.read(bookingViewModelProvider.notifier).startListening(user.id, role: 'admin');
        ref.read(carViewModelProvider.notifier).loadCars(''); // Load all cars
      }
    });
  }

  Future<Map<String, String>> _getUserInfo(String userId) async {
    // Check cache first
    if (_usersCache.containsKey(userId)) {
      return _usersCache[userId]!;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      
      if (userDoc.exists) {
        final data = userDoc.data()!;
        final userInfo = <String, String>{
          'name': data['name']?.toString() ?? 'Unknown',
          'phone': data['phone']?.toString() ?? 'N/A',
        };
        _usersCache[userId] = userInfo;
        return userInfo;
      }
    } catch (e) {
      debugPrint('Error fetching user info: $e');
    }

    return <String, String>{'name': 'Unknown', 'phone': 'N/A'};
  }

  Future<String> _getTechnicianNames(List<String>? technicianIds) async {
    if (technicianIds == null || technicianIds.isEmpty) {
      return 'Not assigned';
    }

    final names = <String>[];
    for (final id in technicianIds) {
      final userInfo = await _getUserInfo(id);
      names.add(userInfo['name']!);
    }

    return names.join(', ');
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    // Remove any non-numeric characters except + and spaces for better formatting
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+\s]'), '');
    final uri = Uri.parse('tel:$cleanNumber');
    
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cannot make phone calls on this device'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error launching phone call: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    // Stop listening when page is disposed
    // Wrap in try-catch to handle cases where widget is already disposed during logout
    try {
      ref.read(bookingViewModelProvider.notifier).stopListening();
    } catch (e) {
      // Widget was already disposed, safe to ignore
      debugPrint('Bookings page disposed, listener cleanup skipped: $e');
    }
    super.dispose();
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _dateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateRange = picked;
      });
    }
  }

  void _clearDateFilter() {
    setState(() {
      _dateRange = null;
    });
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

    // Filter bookings based on selection
    var filteredBookings = bookingState.bookings;
    
    // Apply status filter
    if (_selectedFilter != 'all') {
      filteredBookings = filteredBookings.where((booking) {
        switch (_selectedFilter) {
          case 'pending':
            return booking.status == BookingStatus.pending;
          case 'confirmed':
            return booking.status == BookingStatus.confirmed;
          case 'inProgress':
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

    // Apply date filter
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

    // Sort by scheduled date, most recent first
    filteredBookings.sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate));

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Bookings'),
        actions: [
          // Date filter button
          IconButton(
            icon: Icon(
              Icons.date_range,
              color: _dateRange != null ? Colors.blue : null,
            ),
            onPressed: () => _selectDateRange(context),
            tooltip: 'Filter by Date',
          ),
          // Status filter button
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _selectedFilter = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All Status')),
              const PopupMenuItem(value: 'pending', child: Text('Pending')),
              const PopupMenuItem(value: 'confirmed', child: Text('Confirmed')),
              const PopupMenuItem(value: 'inProgress', child: Text('In Progress')),
              const PopupMenuItem(value: 'completed', child: Text('Completed')),
              const PopupMenuItem(value: 'cancelled', child: Text('Cancelled')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips display
          if (_dateRange != null || _selectedFilter != 'all')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Wrap(
                spacing: 8,
                children: [
                  if (_dateRange != null)
                    Chip(
                      label: Text(
                        '${DateFormat('MMM dd').format(_dateRange!.start)} - ${DateFormat('MMM dd, yyyy').format(_dateRange!.end)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: _clearDateFilter,
                      backgroundColor: Colors.blue.shade50,
                    ),
                  if (_selectedFilter != 'all')
                    Chip(
                      label: Text(
                        _getStatusName(
                          BookingStatus.values.firstWhere(
                            (e) => e.toString().split('.').last == _selectedFilter,
                            orElse: () => BookingStatus.pending,
                          ),
                        ),
                        style: const TextStyle(fontSize: 12),
                      ),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () {
                        setState(() {
                          _selectedFilter = 'all';
                        });
                      },
                      backgroundColor: Colors.orange.shade50,
                    ),
                ],
              ),
            ),
          
          // Bookings list
          Expanded(
            child: bookingState.isLoading || carState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredBookings.isEmpty
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
                            Text(
                              _dateRange != null || _selectedFilter != 'all'
                                  ? 'No bookings found with current filters'
                                  : 'No bookings yet',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Bookings will appear here',
                              style: TextStyle(color: Colors.grey),
                            ),
                            if (_dateRange != null || _selectedFilter != 'all') ...[
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _dateRange = null;
                                    _selectedFilter = 'all';
                                  });
                                },
                                child: const Text('Clear Filters'),
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredBookings.length,
                        itemBuilder: (context, index) {
                          final booking = filteredBookings[index];

                          // Get car info
                          Car? car = carState.cars.where((c) => c.id == booking.carId).firstOrNull;
                          
                          // If car not found, fetch it
                          if (car == null && booking.carId.isNotEmpty && !_fetchingCars.contains(booking.carId)) {
                            _fetchingCars.add(booking.carId);
                            ref.read(carViewModelProvider.notifier).getCarById(booking.carId).then((fetchedCar) {
                              if (mounted && fetchedCar != null) {
                                setState(() {
                                  _fetchingCars.remove(booking.carId);
                                });
                              } else {
                                _fetchingCars.remove(booking.carId);
                              }
                            });
                          }
                          
                          final carName = car != null ? '${car.make} ${car.model}' : 'Loading...';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: InkWell(
                              onTap: () {
                                _showBookingDetails(context, booking, car);
                              },
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
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(booking.status).withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(12),
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
                                    const SizedBox(height: 8),
                                    FutureBuilder<Map<String, String>>(
                                      future: _getUserInfo(booking.userId),
                                      builder: (context, snapshot) {
                                        final customerName = snapshot.data?['name'] ?? 'Loading...';
                                        final customerPhone = snapshot.data?['phone'] ?? '';
                                        return Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.person,
                                                  size: 16,
                                                  color: Colors.grey[500],
                                                ),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    'Customer: $customerName',
                                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                      color: Colors.grey[700],
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (customerPhone.isNotEmpty && customerPhone != 'N/A') ...[
                                              const SizedBox(height: 4),
                                              InkWell(
                                                onTap: () => _makePhoneCall(customerPhone),
                                                borderRadius: BorderRadius.circular(8),
                                                child: Padding(
                                                  padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons.phone,
                                                        size: 16,
                                                        color: Colors.green[600],
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        customerPhone,
                                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                          color: Colors.green[700],
                                                          fontWeight: FontWeight.w500,
                                                          decoration: TextDecoration.underline,
                                                          decorationColor: Colors.green[700],
                                                        ),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Icon(
                                                        Icons.call,
                                                        size: 14,
                                                        color: Colors.green[600],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      carName,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          size: 16,
                                          color: Colors.grey[500],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${DateFormat('MMM dd, yyyy').format(booking.scheduledDate)} at ${booking.timeSlot}',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (booking.assignedTechnicians != null && booking.assignedTechnicians!.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      FutureBuilder<String>(
                                        future: _getTechnicianNames(booking.assignedTechnicians),
                                        builder: (context, snapshot) {
                                          return Row(
                                            children: [
                                              Icon(
                                                Icons.engineering,
                                                size: 16,
                                                color: Colors.blue[600],
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  'Technician: ${snapshot.data ?? 'Loading...'}',
                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                    color: Colors.blue[700],
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ],
                                    if (booking.status == BookingStatus.completed) ...[
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text('Total Cost:'),
                                          Text(
                                            '\$${booking.totalCost.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (booking.rating != null) ...[
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.star,
                                              size: 16,
                                              color: Colors.amber,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${booking.rating!.toStringAsFixed(1)} / 5.0',
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: Colors.amber[700],
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            if (booking.ratingComment != null && booking.ratingComment!.isNotEmpty)
                                              Expanded(
                                                child: Text(
                                                  '"${booking.ratingComment}"',
                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                    color: Colors.grey[600],
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                          ],
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
        return Colors.purple;
      case BookingStatus.completed:
        return Colors.green;
      case BookingStatus.cancelled:
        return Colors.red;
    }
  }

  void _showBookingDetails(BuildContext context, BookingEntity booking, CarEntity? car) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // Fetch customer data for PDF generation
    Map<String, dynamic>? customerData;
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(booking.userId)
          .get();
      if (userDoc.exists) {
        customerData = {'id': userDoc.id, ...userDoc.data()!};
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    }

    // Fetch technician names
    String technicianNames = 'Not assigned';
    if (booking.assignedTechnicians != null && booking.assignedTechnicians!.isNotEmpty) {
      technicianNames = await _getTechnicianNames(booking.assignedTechnicians);
    }

    // Close loading dialog
    if (context.mounted) {
      Navigator.of(context).pop();
    }

    if (!context.mounted) return;

    final customerPhone = customerData?['phone'] ?? 'N/A';

    // Show booking details dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_getMaintenanceTypeName(booking.maintenanceType)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Booking ID: ${booking.id}'),
              const SizedBox(height: 12),
              const Text('Customer Information:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Name: ${customerData?['name'] ?? 'Unknown'}'),
              if (customerPhone != 'N/A')
                InkWell(
                  onTap: () => _makePhoneCall(customerPhone),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.phone, size: 16, color: Colors.green),
                        const SizedBox(width: 4),
                        Text(
                          'Phone: $customerPhone',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.green[700],
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.call, size: 14, color: Colors.green[600]),
                      ],
                    ),
                  ),
                )
              else
                const Row(
                  children: [
                    Icon(Icons.phone, size: 16, color: Colors.grey),
                    SizedBox(width: 4),
                    Text('Phone: N/A'),
                  ],
                ),
              Text('Customer ID: ${booking.userId}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              const SizedBox(height: 12),
              const Text('Vehicle Information:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Car: ${car != null ? '${car.make} ${car.model}' : 'Unknown Car'}'),
              if (car != null) Text('Plate: ${car.licensePlate}'),
              const SizedBox(height: 12),
              const Text('Appointment Details:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Date: ${DateFormat('MMM dd, yyyy').format(booking.scheduledDate)}'),
              Text('Time: ${booking.timeSlot}'),
              Text('Status: ${_getStatusName(booking.status)}'),
              const SizedBox(height: 12),
              if (booking.assignedTechnicians != null && booking.assignedTechnicians!.isNotEmpty) ...[
                const Text('Assigned Technician:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.engineering, size: 16, color: Colors.blue),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        technicianNames,
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              if (booking.description != null && booking.description!.isNotEmpty)
                Text('Description: ${booking.description}'),
              if (booking.notes != null && booking.notes!.isNotEmpty)
                Text('Notes: ${booking.notes}'),
              if (booking.completedAt != null) ...[
                Text('Completed At: ${DateFormat('MMM dd, yyyy HH:mm').format(booking.completedAt!)}'),
                if (booking.rating != null) ...[
                  const SizedBox(height: 12),
                  const Text('Customer Rating:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ...List.generate(5, (index) {
                        return Icon(
                          index < booking.rating!.round() 
                              ? Icons.star 
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 20,
                        );
                      }),
                      const SizedBox(width: 8),
                      Text(
                        '${booking.rating!.toStringAsFixed(1)} / 5.0',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  if (booking.ratingComment != null && booking.ratingComment!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Customer Feedback:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '"${booking.ratingComment}"',
                            style: const TextStyle(
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (booking.ratedAt != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Rated on: ${DateFormat('MMM dd, yyyy HH:mm').format(booking.ratedAt!)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                ],
                const Divider(height: 20),
                const Text('Invoice Details:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (booking.serviceItems != null && booking.serviceItems!.isNotEmpty)
                  ...booking.serviceItems!.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text('${item.name} x${item.quantity}')),
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
                    const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    Text(
                      '\$${booking.totalCost.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Close'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          if (booking.status == BookingStatus.completed && customerData != null)
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await PdfGenerator.generateAndShareInvoice(
                    context,
                    booking,
                    car,
                    customerData,
                  );
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error generating PDF: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Export PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
            ),
        ],
      ),
    );
  }
}
