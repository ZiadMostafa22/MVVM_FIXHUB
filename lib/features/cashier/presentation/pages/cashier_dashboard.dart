import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:car_maintenance_system_new/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:car_maintenance_system_new/features/booking/presentation/viewmodels/booking_viewmodel.dart';
import 'package:car_maintenance_system_new/features/car/presentation/viewmodels/car_viewmodel.dart';
import 'package:car_maintenance_system_new/features/shared/presentation/pages/settings_page.dart';
import 'package:car_maintenance_system_new/features/booking/domain/entities/booking_entity.dart';
import 'package:car_maintenance_system_new/features/shared/presentation/pages/notifications_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CashierDashboard extends ConsumerStatefulWidget {
  const CashierDashboard({super.key});

  @override
  ConsumerState<CashierDashboard> createState() => _CashierDashboardState();
}

class _CashierDashboardState extends ConsumerState<CashierDashboard> {
  // Cache for user names
  final Map<String, String> _userNames = {};
  Stream<int>? _pendingRefundsStream;

  Future<String> _getUserName(String userId) async {
    if (_userNames.containsKey(userId)) {
      return _userNames[userId]!;
    }
    
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      
      if (userDoc.exists) {
        final userName = userDoc.data()?['name'] ?? 'Unknown Customer';
        _userNames[userId] = userName;
        return userName;
      }
    } catch (e) {
      debugPrint('Error fetching user name: $e');
    }
    
    _userNames[userId] = 'Unknown Customer';
    return 'Unknown Customer';
  }

  @override
  void initState() {
    super.initState();
    // Setup real-time stream for pending refunds
    _pendingRefundsStream = FirebaseFirestore.instance
        .collection('refunds')
        .where('status', isEqualTo: 'approved')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authViewModelProvider).user;
      if (user != null) {
        // Load all bookings for cashier
        ref.read(bookingViewModelProvider.notifier).startListening(user.id, role: 'cashier');
        // Load car details
        ref.read(carViewModelProvider.notifier).loadCars('');
      }
    });
  }

  @override
  void dispose() {
    try {
      ref.read(bookingViewModelProvider.notifier).stopListening();
    } catch (e) {
      debugPrint('Dashboard disposed, listener cleanup skipped: $e');
    }
    super.dispose();
  }

  Future<void> _refreshData() async {
    final user = ref.read(authViewModelProvider).user;
    if (user != null) {
      await ref.read(bookingViewModelProvider.notifier).loadBookings(user.id, role: 'cashier');
      // Stream will auto-update, no need to manually reload
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final user = authState.user;
    final bookingState = ref.watch(bookingViewModelProvider);
    
    // Filter bookings waiting for payment
    final pendingPayments = bookingState.bookings
        .where((b) => b.status == BookingStatus.completedPendingPayment)
        .toList();
    
    
    // Get today's completed payments
    final today = DateTime.now();
    final todayPayments = bookingState.bookings.where((b) {
      return b.isPaid && 
             b.paidAt != null && 
             b.paidAt!.year == today.year &&
             b.paidAt!.month == today.month &&
             b.paidAt!.day == today.day;
    }).toList();
    
    final todayTotal = todayPayments.fold<double>(
      0, 
      (sum, booking) => sum + booking.totalCost,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Welcome, ${user?.name ?? 'Cashier'}',
          style: TextStyle(fontSize: 18.sp),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings, size: 22.sp),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
          // Notification bell with unread count
          Consumer(
            builder: (context, ref, child) {
              final unreadAsync = ref.watch(unreadCountProvider);
              return Stack(
                alignment: Alignment.center,
                children: [
          IconButton(
            icon: Icon(Icons.notifications, size: 22.sp),
            onPressed: () {
                      context.push('/cashier/notifications');
                    },
                  ),
                  unreadAsync.when(
                    data: (count) => count > 0
                        ? Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: EdgeInsets.all(4.w),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: BoxConstraints(
                                minWidth: 16.w,
                                minHeight: 16.w,
                              ),
                              child: Text(
                                count > 9 ? '9+' : '$count',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.logout, size: 22.sp),
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
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats Cards
              Row(
                children: [
                  Expanded(
                    child: Card(
                      color: Colors.orange.shade50,
                      child: Padding(
                        padding: EdgeInsets.all(16.w),
                        child: Column(
                          children: [
                            Icon(
                              Icons.pending_actions,
                              color: Colors.orange,
                              size: 32.sp,
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              '${pendingPayments.length}',
                              style: TextStyle(
                                fontSize: 32.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                            Text(
                              'Pending Payments',
                              style: TextStyle(fontSize: 12.sp),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Card(
                      color: Colors.green.shade50,
                      child: Padding(
                        padding: EdgeInsets.all(16.w),
                        child: Column(
                          children: [
                            Icon(
                              Icons.attach_money,
                              color: Colors.green,
                              size: 32.sp,
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              '\$${todayTotal.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 28.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            Text(
                              'Today\'s Total',
                              style: TextStyle(fontSize: 12.sp),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              // Pending Refunds Alert Card (Real-time)
              StreamBuilder<int>(
                stream: _pendingRefundsStream,
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;
                  if (count == 0) return const SizedBox.shrink();
                  
                  return Column(
                    children: [
                      SizedBox(height: 16.h),
                      InkWell(
                        onTap: () => context.go('/cashier/refunds'),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.red.shade400, Colors.red.shade600],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(12.w),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.money_off,
                                  color: Colors.white,
                                  size: 28.sp,
                                ),
                              ),
                              SizedBox(width: 16.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$count Refund${count > 1 ? 's' : ''} Pending',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      'Tap to process approved refunds',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 12.sp,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.white,
                                size: 20.sp,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              
              SizedBox(height: 24.h),
              
              // Pending Payments Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Awaiting Payment',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18.sp,
                    ),
                  ),
                  if (pendingPayments.isNotEmpty)
                    TextButton(
                      onPressed: () => context.go('/cashier/payments'),
                      child: const Text('View All'),
                    ),
                ],
              ),
              SizedBox(height: 16.h),
              
              if (pendingPayments.isEmpty)
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.w),
                    child: Column(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 64.sp,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'No pending payments',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: pendingPayments.length > 5 ? 5 : pendingPayments.length,
                  itemBuilder: (context, index) {
                    final booking = pendingPayments[index];
                    return Card(
                      margin: EdgeInsets.only(bottom: 8.h),
                      child: Consumer(
                        builder: (context, ref, child) {
                          final carState = ref.watch(carViewModelProvider);
                          final car = carState.cars.isEmpty 
                              ? null 
                              : carState.cars.where((c) => c.id == booking.carId).firstOrNull;
                          
                          return InkWell(
                            onTap: () {
                              context.go('/cashier/payment/${booking.id}');
                            },
                            child: Padding(
                              padding: EdgeInsets.all(12.w),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.orange.shade100,
                                    child: const Icon(Icons.payment, color: Colors.orange),
                                  ),
                                  SizedBox(width: 12.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Invoice #${booking.id.substring(0, 8)}',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        SizedBox(height: 4.h),
                                        FutureBuilder<String>(
                                          future: _getUserName(booking.userId),
                                          builder: (context, snapshot) {
                                            final customerName = snapshot.data ?? 'Loading...';
                                            return Text(
                                              'Customer: $customerName',
                                              style: TextStyle(
                                                fontSize: 12.sp,
                                                color: Colors.grey[700],
                                                fontWeight: FontWeight.w500,
                                              ),
                                            );
                                          },
                                        ),
                                        SizedBox(height: 4.h),
                                        Text(
                                          'Amount: \$${booking.totalCost.toStringAsFixed(2)}',
                                          style: TextStyle(fontSize: 12.sp),
                                        ),
                                        if (car != null) ...[
                                          SizedBox(height: 4.h),
                                          Container(
                                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.shade50,
                                              borderRadius: BorderRadius.circular(4.r),
                                              border: Border.all(color: Colors.blue.shade200),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.directions_car,
                                                  size: 12.sp,
                                                  color: Colors.blue.shade700,
                                                ),
                                                SizedBox(width: 4.w),
                                                Text(
                                                  '${car.year} ${car.make} ${car.model}',
                                                  style: TextStyle(
                                                    fontSize: 10.sp,
                                                    color: Colors.blue.shade700,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                        if (booking.completedAt != null) ...[
                                          SizedBox(height: 4.h),
                                          Text(
                                            'Completed: ${DateFormat('dd/MM/yyyy HH:mm').format(booking.completedAt!)}',
                                            style: TextStyle(fontSize: 10.sp, color: Colors.grey),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      context.go('/cashier/payment/${booking.id}');
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                                    ),
                                    child: Text(
                                      'Receive',
                                      style: TextStyle(fontSize: 12.sp),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: StreamBuilder<int>(
        stream: _pendingRefundsStream,
        builder: (context, snapshot) {
          final refundsCount = snapshot.data ?? 0;
          
          return BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 0,
        selectedFontSize: 12.sp,
        unselectedFontSize: 10.sp,
        iconSize: 24.sp,
        onTap: (index) {
          switch (index) {
            case 0:
              // Already on dashboard
              break;
            case 1:
              context.go('/cashier/payments');
              break;
            case 2:
              context.go('/cashier/refunds');
              break;
            case 3:
              context.go('/cashier/reports');
              break;
            case 4:
              context.go('/cashier/profile');
              break;
          }
        },
            items: [
              const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
              const BottomNavigationBarItem(
            icon: Icon(Icons.payment),
            label: 'Payments',
          ),
          BottomNavigationBarItem(
                icon: refundsCount > 0
                    ? Badge(
                        label: Text('$refundsCount'),
                        child: const Icon(Icons.receipt_long),
                      )
                    : const Icon(Icons.receipt_long),
            label: 'Refunds',
          ),
              const BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Reports',
          ),
              const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
          );
        },
      ),
    );
  }
}
