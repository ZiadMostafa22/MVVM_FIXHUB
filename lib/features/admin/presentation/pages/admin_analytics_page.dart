import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:car_maintenance_system_new/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:car_maintenance_system_new/features/booking/presentation/viewmodels/booking_viewmodel.dart';
import 'package:car_maintenance_system_new/features/booking/domain/entities/booking_entity.dart';

// Provider to fetch all users (technicians)
final allUsersProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return FirebaseFirestore.instance
      .collection('users')
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList());
});

class AdminAnalyticsPage extends ConsumerStatefulWidget {
  const AdminAnalyticsPage({super.key});

  @override
  ConsumerState<AdminAnalyticsPage> createState() => _AdminAnalyticsPageState();
}

class _AdminAnalyticsPageState extends ConsumerState<AdminAnalyticsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authViewModelProvider).user;
      if (user != null) {
        // Start real-time listener for all bookings
        ref.read(bookingViewModelProvider.notifier).startListening(user.id, role: 'admin');
      }
    });
  }

  @override
  void dispose() {
    // Stop listening when page is disposed
    // Wrap in try-catch to handle cases where widget is already disposed during logout
    try {
      ref.read(bookingViewModelProvider.notifier).stopListening();
    } catch (e) {
      // Widget was already disposed, safe to ignore
      debugPrint('Analytics page disposed, listener cleanup skipped: $e');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(bookingViewModelProvider);
    final usersAsync = ref.watch(allUsersProvider);

    final completedBookings = bookingState.bookings
        .where((b) => b.status == BookingStatus.completed)
        .toList();

    // Calculate total revenue
    final totalRevenue = completedBookings.fold<double>(
      0,
      (sum, booking) => sum + booking.totalCost,
    );

    // Revenue by day (last 7 days)
    final Map<String, double> revenueByDay = {};
    final now = DateTime.now();
    for (var i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = DateFormat('MMM dd').format(date);
      revenueByDay[dateStr] = 0;
    }

    for (var booking in completedBookings) {
      final completedDate = booking.completedAt ?? booking.updatedAt;
      final dateStr = DateFormat('MMM dd').format(completedDate);
      if (revenueByDay.containsKey(dateStr)) {
        revenueByDay[dateStr] = (revenueByDay[dateStr] ?? 0) + booking.totalCost;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final user = ref.read(authViewModelProvider).user;
              if (user != null) {
                ref.read(bookingViewModelProvider.notifier).loadBookings(user.id, role: 'admin');
              }
              ref.invalidate(allUsersProvider);
            },
          ),
        ],
      ),
      body: bookingState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Revenue Summary Cards
                  Text(
                    'Revenue Overview',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18.sp,
                        ),
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          context,
                          'Total Revenue',
                          '\$${totalRevenue.toStringAsFixed(2)}',
                          Icons.attach_money,
                          Colors.green,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: _buildSummaryCard(
                          context,
                          'Completed Jobs',
                          completedBookings.length.toString(),
                          Icons.check_circle,
                          Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  _buildSummaryCard(
                    context,
                    'Average Revenue per Job',
                    completedBookings.isEmpty
                        ? '\$0.00'
                        : '\$${(totalRevenue / completedBookings.length).toStringAsFixed(2)}',
                    Icons.trending_up,
                    Colors.orange,
                  ),

                  SizedBox(height: 20.h),

                  // Revenue Chart
                  Text(
                    'Revenue Trends (Last 7 Days)',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18.sp,
                        ),
                  ),
                  SizedBox(height: 12.h),
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(12.w),
                      child: SizedBox(
                        height: 200.h,
                        child: _buildRevenueChart(revenueByDay),
                      ),
                    ),
                  ),

                  SizedBox(height: 20.h),

                  // Top Technicians
                  Text(
                    'Top Performing Technicians',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18.sp,
                        ),
                  ),
                  SizedBox(height: 12.h),
                  usersAsync.when(
                    data: (users) => _buildTopTechnicians(context, completedBookings, users),
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (error, stack) => Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text('Error loading technicians: $error'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(icon, color: color, size: 24.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 11.sp,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color,
                          fontSize: 18.sp,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueChart(Map<String, double> data) {
    final entries = data.entries.toList();
    final maxY = entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    if (maxY == 0) {
      return const Center(
        child: Text(
          'No revenue data for the last 7 days',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return BarChart(
      BarChartData(
        maxY: maxY * 1.2,
        minY: 0,
        barGroups: entries.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value.value,
                color: Colors.blue,
                width: 20,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }).toList(),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 45,
              getTitlesWidget: (value, meta) {
                return Text(
                  '\$${value.toInt()}',
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < entries.length) {
                  final parts = entries[value.toInt()].key.split(' ');
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      parts.length > 1 ? parts[1] : parts[0],
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 5,
        ),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  Widget _buildTopTechnicians(
    BuildContext context,
    List<BookingEntity> completedBookings,
    List<Map<String, dynamic>> allUsers,
  ) {
    // Calculate stats for each technician
    final Map<String, Map<String, dynamic>> techStats = {};

    for (var booking in completedBookings) {
      if (booking.assignedTechnicians != null) {
        for (var techId in booking.assignedTechnicians!) {
          if (!techStats.containsKey(techId)) {
            techStats[techId] = {
              'completedJobs': 0,
              'totalHours': 0.0,
              'totalRevenue': 0.0,
              'ratings': <double>[],
            };
          }
          techStats[techId]!['completedJobs'] = (techStats[techId]!['completedJobs'] as int) + 1;
          techStats[techId]!['totalHours'] = (techStats[techId]!['totalHours'] as double) + booking.hoursWorked;
          techStats[techId]!['totalRevenue'] = (techStats[techId]!['totalRevenue'] as double) + booking.totalCost;
          if (booking.rating != null) {
            (techStats[techId]!['ratings'] as List<double>).add(booking.rating!);
          }
        }
      }
    }

    // Calculate average ratings and get tech names
    for (var entry in techStats.entries) {
      final ratings = entry.value['ratings'] as List<double>;
      entry.value['avgRating'] = ratings.isEmpty
          ? 0.0
          : ratings.reduce((a, b) => a + b) / ratings.length;

      // Get technician name
      final techUser = allUsers.where((u) => u['id'] == entry.key).firstOrNull;
      entry.value['name'] = techUser?['name'] ?? 'Unknown';
      entry.value['email'] = techUser?['email'] ?? '';
    }

    // Sort by completed jobs
    final sortedTechs = techStats.entries.toList();
    sortedTechs.sort((a, b) =>
        (b.value['completedJobs'] as int).compareTo(a.value['completedJobs'] as int));

    if (sortedTechs.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Center(
            child: Text(
              'No technician data available',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    return Column(
      children: sortedTechs.take(10).map((entry) {
        final stats = entry.value;
        final rank = sortedTechs.indexOf(entry) + 1;
        final isTopThree = rank <= 3;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Card(
          margin: EdgeInsets.only(bottom: 10.h),
          color: isTopThree ? (isDark ? Colors.amber.shade900.withValues(alpha: 0.2) : Colors.amber.shade50) : null,
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
            leading: Stack(
              children: [
                CircleAvatar(
                  radius: 20.r,
                  backgroundColor: isTopThree ? Colors.amber : Colors.blue,
                  child: Text(
                    rank.toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
                if (rank == 1)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Icon(Icons.emoji_events, color: Colors.amber, size: 14.sp),
                  ),
              ],
            ),
            title: Text(
              stats['name'] as String,
              style: TextStyle(
                fontWeight: isTopThree ? FontWeight.bold : FontWeight.normal,
                fontSize: 14.sp,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Icon(Icons.check_circle, size: 12.sp, color: Colors.green),
                    SizedBox(width: 4.w),
                    Text('${stats['completedJobs']} jobs', style: TextStyle(fontSize: 11.sp)),
                    SizedBox(width: 10.w),
                    Icon(Icons.schedule, size: 12.sp, color: Colors.blue),
                    SizedBox(width: 4.w),
                    Text('${(stats['totalHours'] as double).toStringAsFixed(1)}h', style: TextStyle(fontSize: 11.sp)),
                  ],
                ),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    Icon(Icons.attach_money, size: 12.sp, color: Colors.green),
                    SizedBox(width: 4.w),
                    Text(
                      '\$${(stats['totalRevenue'] as double).toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                        fontSize: 11.sp,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Text(
              '#$rank',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16.sp,
                color: isTopThree ? Colors.amber : Colors.grey,
              ),
            ),
            isThreeLine: true,
          ),
        );
      }).toList(),
    );
  }
}
