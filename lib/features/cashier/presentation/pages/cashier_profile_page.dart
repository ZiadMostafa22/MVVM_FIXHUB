import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:car_maintenance_system_new/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:car_maintenance_system_new/features/booking/presentation/viewmodels/booking_viewmodel.dart';
import 'package:car_maintenance_system_new/core/services/firebase_service.dart';
import 'package:car_maintenance_system_new/core/models/user_model.dart' as app_models;

class CashierProfilePage extends ConsumerStatefulWidget {
  const CashierProfilePage({super.key});

  @override
  ConsumerState<CashierProfilePage> createState() => _CashierProfilePageState();
}

class _CashierProfilePageState extends ConsumerState<CashierProfilePage> {
  DateTime? _accountCreatedDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserFullData();
    });
  }

  Future<void> _loadUserFullData() async {
    try {
      final user = ref.read(authViewModelProvider).user;
      if (user == null) return;

      final doc = await FirebaseService.usersCollection.doc(user.id).get();
      if (doc.exists) {
        final userData = app_models.UserModel.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
        if (mounted) {
          setState(() {
            _accountCreatedDate = userData.createdAt;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final user = authState.user;
    final bookingState = ref.watch(bookingViewModelProvider);

    // Calculate cashier stats
    final processedPayments = bookingState.bookings
        .where((b) => b.isPaid && b.cashierId == user?.id)
        .toList();
    
    final totalAmount = processedPayments.fold<double>(
      0,
      (sum, booking) => sum + booking.totalCost,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            // Profile Header
            CircleAvatar(
              radius: 50.r,
              backgroundColor: Theme.of(context).primaryColor,
              child: Text(
                user?.name.substring(0, 1).toUpperCase() ?? 'C',
                style: TextStyle(
                  fontSize: 40.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              user?.name ?? 'Cashier',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Text(
                'Cashier',
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.w500,
                  fontSize: 12.sp,
                ),
              ),
            ),

            SizedBox(height: 24.h),

            // Stats Cards
            Row(
              children: [
                Expanded(
                  child: Card(
                    color: Colors.green.shade50,
                    child: Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Column(
                        children: [
                          Icon(
                            Icons.payment,
                            color: Colors.green,
                            size: 32.sp,
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            '${processedPayments.length}',
                            style: TextStyle(
                              fontSize: 24.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          Text(
                            'Payments',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Card(
                    color: Colors.orange.shade50,
                    child: Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Column(
                        children: [
                          Icon(
                            Icons.attach_money,
                            color: Colors.orange,
                            size: 32.sp,
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            '\$${totalAmount.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 24.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                          Text(
                            'Total Amount',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 16.h),

            // Profile Info Card
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account Information',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    SizedBox(height: 16.h),
                    _buildInfoRow(Icons.person, 'Name', user?.name ?? ''),
                    _buildInfoRow(Icons.email, 'Email', user?.email ?? ''),
                    _buildInfoRow(Icons.phone, 'Phone', user?.phone ?? ''),
                    if (_accountCreatedDate != null)
                      _buildInfoRow(
                        Icons.calendar_today,
                        'Member Since',
                        DateFormat('dd MMMM yyyy').format(_accountCreatedDate!),
                      ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 24.h),

            // Sign Out Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Sign Out'),
                      content: const Text('Are you sure you want to sign out?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(dialogContext);
                            await Future.delayed(const Duration(milliseconds: 100));
                            if (mounted) {
                              await ref.read(authViewModelProvider.notifier).signOut();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text('Sign Out'),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.all(16.h),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          Icon(icon, size: 20.sp, color: Colors.grey),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
