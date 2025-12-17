import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:car_maintenance_system_new/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:car_maintenance_system_new/features/booking/presentation/viewmodels/booking_viewmodel.dart';
import 'package:car_maintenance_system_new/features/car/presentation/viewmodels/car_viewmodel.dart';
import 'package:car_maintenance_system_new/features/shared/presentation/pages/settings_page.dart';
import 'package:car_maintenance_system_new/features/customer/presentation/widgets/quick_actions.dart';
import 'package:car_maintenance_system_new/features/customer/presentation/widgets/upcoming_appointments.dart';
import 'package:car_maintenance_system_new/features/customer/presentation/widgets/active_services.dart';
import 'package:car_maintenance_system_new/features/customer/presentation/widgets/missed_appointments.dart';
import 'package:car_maintenance_system_new/features/booking/domain/entities/booking_entity.dart';
import 'package:car_maintenance_system_new/features/customer/presentation/widgets/customer_bottom_nav_bar.dart';
import 'package:car_maintenance_system_new/features/shared/presentation/pages/notifications_page.dart';

class CustomerDashboard extends ConsumerStatefulWidget {
  const CustomerDashboard({super.key});

  @override
  ConsumerState<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends ConsumerState<CustomerDashboard> {
  @override
  void initState() {
    super.initState();
    // Start real-time listeners for bookings and load cars when dashboard opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authViewModelProvider).user;
      if (user != null) {
        // Start real-time listener for bookings
        ref.read(bookingViewModelProvider.notifier).startListening(user.id);
        // Load cars (one-time)
        ref.read(carViewModelProvider.notifier).loadCars(user.id);
      }
    });
  }

  @override
  void dispose() {
    // Stop listening when dashboard is disposed
    // Wrap in try-catch to handle cases where widget is already disposed during logout
    try {
      ref.read(bookingViewModelProvider.notifier).stopListening();
    } catch (e) {
      // Widget was already disposed, safe to ignore
      debugPrint('Dashboard disposed, listener cleanup skipped: $e');
    }
    super.dispose();
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
    final authState = ref.watch(authViewModelProvider);
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Welcome, ${user?.name ?? 'Customer'}',
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
                      context.push('/customer/notifications');
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
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Good ${_getGreeting()}!',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 20.sp,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'How can we help you with your car today?',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                        fontSize: 14.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 24.h),
            
            // Quick Actions
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 18.sp,
              ),
            ),
            SizedBox(height: 16.h),
            const QuickActions(),
            
            SizedBox(height: 24.h),
            
            // Upcoming Appointments (only show section if there are appointments)
            Consumer(
              builder: (context, ref, child) {
                final bookingState = ref.watch(bookingViewModelProvider);
                final upcomingBookings = bookingState.bookings.where((booking) {
                  return (booking.status == BookingStatus.pending ||
                          booking.status == BookingStatus.confirmed) &&
                         booking.scheduledDate.isAfter(DateTime.now());
                }).toList();
                
                if (upcomingBookings.isEmpty) {
                  return const SizedBox.shrink();
                }
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upcoming Appointments',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 18.sp,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    const UpcomingAppointments(),
                    SizedBox(height: 24.h),
                  ],
                );
              },
            ),
            
            // Missed Appointments (show if any exist)
            const MissedAppointments(),
            
            // Active Services (In Progress & Pending Payment)
            const ActiveServices(),
            
            SizedBox(height: 24.h),
            
          ],
        ),
        ),
      ),
      bottomNavigationBar: CustomerBottomNavBar(context: context),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Morning';
    } else if (hour < 17) {
      return 'Afternoon';
    } else {
      return 'Evening';
    }
  }
}