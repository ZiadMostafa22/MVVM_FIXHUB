import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:car_maintenance_system_new/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:car_maintenance_system_new/features/booking/presentation/viewmodels/booking_viewmodel.dart';
import 'package:car_maintenance_system_new/features/booking/domain/entities/booking_entity.dart';

// Provider to get all technicians from Firestore
final techniciansProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return FirebaseFirestore.instance
      .collection('users')
      .where('role', isEqualTo: 'technician')
      .snapshots()
      .map((snapshot) {
        final technicians = snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList();
        // Sort by name in the app to avoid composite index requirement
        technicians.sort((a, b) {
          final nameA = (a['name'] ?? '').toString().toLowerCase();
          final nameB = (b['name'] ?? '').toString().toLowerCase();
          return nameA.compareTo(nameB);
        });
        return technicians;
      });
});

class AdminTechniciansPage extends ConsumerStatefulWidget {
  const AdminTechniciansPage({super.key});

  @override
  ConsumerState<AdminTechniciansPage> createState() => _AdminTechniciansPageState();
}

class _AdminTechniciansPageState extends ConsumerState<AdminTechniciansPage> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authViewModelProvider).user;
      if (user != null) {
        ref.read(bookingViewModelProvider.notifier).loadBookings(user.id, role: 'admin');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final techniciansAsync = ref.watch(techniciansProvider);
    final bookingState = ref.watch(bookingViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Technicians'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(techniciansProvider);
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
                labelText: 'Search technicians',
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
            child: techniciansAsync.when(
              data: (technicians) {
                final filteredTechnicians = technicians.where((tech) {
                  final name = (tech['name'] ?? '').toLowerCase();
                  final email = (tech['email'] ?? '').toLowerCase();
                  return name.contains(_searchQuery) || email.contains(_searchQuery);
                }).toList();

                if (filteredTechnicians.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.engineering, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No technicians found',
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
                  itemCount: filteredTechnicians.length,
                  itemBuilder: (context, index) {
                    final tech = filteredTechnicians[index];
                    
                    // Calculate stats for this technician
                    final techBookings = bookingState.bookings.where((b) =>
                      b.assignedTechnicians != null &&
                      b.assignedTechnicians!.contains(tech['id'])
                    ).toList();
                    
                    final completedJobs = techBookings.where((b) =>
                      b.status == BookingStatus.completed
                    ).length;
                    
                    final activeJobs = techBookings.where((b) =>
                      b.status == BookingStatus.inProgress ||
                      b.status == BookingStatus.confirmed
                    ).length;
                    
                    final totalHours = techBookings
                        .where((b) => b.status == BookingStatus.completed)
                        .fold<double>(0, (sum, b) => sum + b.hoursWorked);
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue,
                          child: Text(
                            (tech['name'] ?? 'T')[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          tech['name'] ?? 'Unknown',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(tech['email'] ?? 'No email'),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildStatCard(
                                        context,
                                        'Completed',
                                        completedJobs.toString(),
                                        Icons.check_circle,
                                        Colors.green,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildStatCard(
                                        context,
                                        'Active',
                                        activeJobs.toString(),
                                        Icons.work,
                                        Colors.blue,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                _buildStatCard(
                                  context,
                                  'Total Hours',
                                  '${totalHours.toStringAsFixed(1)}h',
                                  Icons.schedule,
                                  Colors.purple,
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      _showTechnicianDetails(context, tech, techBookings);
                                    },
                                    icon: const Icon(Icons.info_outline),
                                    label: const Text('View Details'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('Error loading technicians: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Card(
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showTechnicianDetails(BuildContext context, Map<String, dynamic> tech, List<BookingEntity> bookings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue,
              child: Text(
                (tech['name'] ?? 'T')[0].toUpperCase(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                tech['name'] ?? 'Technician',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Contact Information
                const Text(
                  'Contact Information',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                
                // Email
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.email, color: Colors.blue, size: 20),
                  title: Text(
                    tech['email'] ?? 'N/A',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                
                // Phone
                if (tech['phone'] != null && tech['phone'].toString().isNotEmpty)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.phone, color: Colors.green, size: 20),
                    title: Text(
                      tech['phone'].toString(),
                      style: const TextStyle(fontSize: 14),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.call, color: Colors.green),
                      tooltip: 'Call',
                      onPressed: () => _makePhoneCall(tech['phone'].toString()),
                    ),
                  ),
                
                const Divider(height: 24),
                
                // Recent Jobs
                Text(
                  'Recent Jobs (${bookings.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                if (bookings.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: Text(
                        'No jobs assigned yet',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  ...bookings.take(5).map((booking) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          _getStatusIcon(booking.status),
                          color: _getStatusColor(booking.status),
                          size: 20,
                        ),
                        title: Text(
                          _getMaintenanceTypeName(booking.maintenanceType),
                          style: const TextStyle(fontSize: 14),
                        ),
                        subtitle: Text(
                          _getStatusName(booking.status),
                          style: const TextStyle(fontSize: 12),
                        ),
                      )),
              ],
            ),
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

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not launch phone dialer'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error making call: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
}

