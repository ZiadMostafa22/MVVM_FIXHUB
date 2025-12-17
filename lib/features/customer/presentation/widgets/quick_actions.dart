import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.15,
      crossAxisSpacing: 8.w,
      mainAxisSpacing: 8.h,
      children: [
        _buildActionCard(
          context,
          icon: Icons.add_circle_outline,
          title: 'Add Car',
          subtitle: 'Register your vehicle',
          color: Colors.blue,
          onTap: () {
            context.go('/customer/add-car');
          },
        ),
        _buildActionCard(
          context,
          icon: Icons.book_online,
          title: 'Book Service',
          subtitle: 'Schedule maintenance',
          color: Colors.green,
          onTap: () {
            context.go('/customer/new-booking');
          },
        ),
        _buildActionCard(
          context,
          icon: Icons.smart_toy,
          title: 'AI Assistant',
          subtitle: 'Ask questions',
          color: Colors.purple,
          onTap: () {
            context.go('/customer/chatbot');
          },
        ),
        _buildActionCard(
          context,
          icon: Icons.local_offer,
          title: 'Special Offers',
          subtitle: 'View deals & discounts',
          color: Colors.red,
          onTap: () {
            context.go('/customer/offers');
          },
        ),
        _buildActionCard(
          context,
          icon: Icons.history,
          title: 'Service History',
          subtitle: 'View past services',
          color: Colors.orange,
          onTap: () {
            context.go('/customer/history');
          },
        ),
        _buildActionCard(
          context,
          icon: Icons.directions_car,
          title: 'My Cars',
          subtitle: 'Manage vehicles',
          color: Colors.teal,
          onTap: () {
            context.go('/customer/cars');
          },
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(8.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42.w,
                height: 42.w,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(21.r),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20.sp,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.sp,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 2.h),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontSize: 10.sp,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
