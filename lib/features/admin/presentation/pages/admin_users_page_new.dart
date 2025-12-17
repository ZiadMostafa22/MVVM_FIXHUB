import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:car_maintenance_system_new/features/booking/presentation/viewmodels/booking_viewmodel.dart';
import 'package:car_maintenance_system_new/features/car/presentation/viewmodels/car_viewmodel.dart';
import 'package:car_maintenance_system_new/features/booking/domain/entities/booking_entity.dart';

// Provider to get all users from Firestore
final usersProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return FirebaseFirestore.instance
      .collection('users')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList());
});

class AdminUsersPage extends ConsumerStatefulWidget {
  const AdminUsersPage({super.key});

  @override
  ConsumerState<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends ConsumerState<AdminUsersPage> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(usersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Users Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(usersProvider);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Search users',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: usersAsync.when(
              data: (users) {
                final filteredUsers = users.where((user) {
                  final name = (user['name'] ?? '').toLowerCase();
                  final email = (user['email'] ?? '').toLowerCase();
                  final role = (user['role'] ?? '').toLowerCase();
                  return name.contains(_searchQuery) ||
                      email.contains(_searchQuery) ||
                      role.contains(_searchQuery);
                }).toList();

                if (filteredUsers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No users found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getRoleColor(user['role']),
                          child: Text(
                            (user['name'] ?? 'U')[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          user['name'] ?? 'Unknown',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user['email'] ?? 'No email'),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getRoleColor(user['role']).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                (user['role'] ?? 'customer').toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: _getRoleColor(user['role']),
                                ),
                              ),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.info_outline),
                          onPressed: () {
                            _showUserDetails(context, user);
                          },
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('Error loading users: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String? role) {
    switch (role?.toLowerCase()) {
      case 'admin':
        return Colors.red;
      case 'technician':
        return Colors.blue;
      case 'customer':
      default:
        return Colors.green;
    }
  }

  void _showUserDetails(BuildContext context, Map<String, dynamic> user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return UserDetailsSheet(
            user: user,
            scrollController: scrollController,
          );
        },
      ),
    );
  }
}

class UserDetailsSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic> user;
  final ScrollController scrollController;

  const UserDetailsSheet({
    super.key,
    required this.user,
    required this.scrollController,
  });

  @override
  ConsumerState<UserDetailsSheet> createState() => _UserDetailsSheetState();
}

class _UserDetailsSheetState extends ConsumerState<UserDetailsSheet> {
  @override
  void initState() {
    super.initState();
    // Load user's cars and bookings
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(carViewModelProvider.notifier).loadCars(widget.user['id']);
      ref.read(bookingViewModelProvider.notifier).loadBookings(widget.user['id']);
    });
  }

  @override
  Widget build(BuildContext context) {
    final carState = ref.watch(carViewModelProvider);
    final bookingState = ref.watch(bookingViewModelProvider);
    
    final userCars = carState.cars.where((car) => car.userId == widget.user['id']).toList();
    final userBookings = bookingState.bookings.where((b) => b.userId == widget.user['id']).toList();
    
    return Container(
      padding: const EdgeInsets.all(20),
      child: ListView(
        controller: widget.scrollController,
        children: [
          // Header
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // User Avatar and Name
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: _getRoleColor(widget.user['role']),
                  child: Text(
                    (widget.user['name'] ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(fontSize: 32, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.user['name'] ?? 'Unknown User',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.user['email'] ?? 'No email',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                if (widget.user['phone'] != null && widget.user['phone'].toString().isNotEmpty)
                  const SizedBox(height: 4),
                if (widget.user['phone'] != null && widget.user['phone'].toString().isNotEmpty)
                  InkWell(
                    onTap: () => _makePhoneCall(widget.user['phone'].toString()),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.phone, size: 16, color: Colors.green.shade700),
                          const SizedBox(width: 4),
                          Text(
                            widget.user['phone'].toString(),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getRoleColor(widget.user['role']).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    (widget.user['role'] ?? 'customer').toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getRoleColor(widget.user['role']),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Stats Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  'Total Cars',
                  userCars.length.toString(),
                  Icons.directions_car,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  context,
                  'Total Visits',
                  userBookings.length.toString(),
                  Icons.history,
                  Colors.orange,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // User's Cars Section
          Text(
            'Registered Cars (${userCars.length})',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (userCars.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.directions_car, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text(
                        'No cars registered',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            ...userCars.map((car) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.directions_car),
                ),
                title: Text('${car.make} ${car.model}'),
                subtitle: Text('${car.year} • ${car.licensePlate}'),
                trailing: Text(
                  car.color,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            )),
          
          const SizedBox(height: 24),
          
          // Visit History Section
          Text(
            'Visit History (${userBookings.length})',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (userBookings.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.history, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text(
                        'No visit history',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            ...userBookings.map((booking) {
              final car = userCars.where((c) => c.id == booking.carId).firstOrNull;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getStatusColor(booking.status).withValues(alpha: 0.2),
                    child: Icon(
                      _getStatusIcon(booking.status),
                      color: _getStatusColor(booking.status),
                      size: 20,
                    ),
                  ),
                  title: Text(_getMaintenanceTypeName(booking.maintenanceType)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (car != null) Text('${car.make} ${car.model}'),
                      Text(DateFormat('MMM dd, yyyy').format(booking.scheduledDate)),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _getStatusName(booking.status),
                        style: TextStyle(
                          color: _getStatusColor(booking.status),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      if (booking.status == BookingStatus.completed)
                        Text(
                          '\$${booking.totalCost.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                    ],
                  ),
                  isThreeLine: car != null,
                ),
              );
            }),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(String? role) {
    switch (role?.toLowerCase()) {
      case 'admin':
        return Colors.red;
      case 'technician':
        return Colors.blue;
      case 'customer':
      default:
        return Colors.green;
    }
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

  IconData _getStatusIcon(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return Icons.schedule;
      case BookingStatus.confirmed:
        return Icons.check_circle_outline;
      case BookingStatus.inProgress:
        return Icons.build;
      case BookingStatus.completedPendingPayment:
        return Icons.payment;
      case BookingStatus.completed:
        return Icons.check_circle;
      case BookingStatus.cancelled:
        return Icons.cancel;
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not launch phone dialer'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error making call: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

