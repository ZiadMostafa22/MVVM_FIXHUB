import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class UnifiedFilterWidget extends StatelessWidget {
  final String selectedFilter;
  final DateTimeRange? dateRange;
  final List<FilterOption> filterOptions;
  final Function(String) onFilterChanged;
  final Function(DateTimeRange?) onDateRangeChanged;
  final bool showDateFilter;
  final bool showStatusFilter;

  const UnifiedFilterWidget({
    super.key,
    required this.selectedFilter,
    this.dateRange,
    required this.filterOptions,
    required this.onFilterChanged,
    required this.onDateRangeChanged,
    this.showDateFilter = true,
    this.showStatusFilter = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Column(
        children: [
          // Filter Tabs Row
          Row(
            children: [
              // Date Filter Button
              if (showDateFilter) ...[
                Expanded(
                  child: _buildFilterTab(
                    context,
                    'date',
                    'Date',
                    isSelected: dateRange != null,
                    icon: Icons.date_range,
                    onTap: () => _selectDateRange(context),
                  ),
                ),
                SizedBox(width: 8.w),
              ],
              // Status Filter Tabs
              if (showStatusFilter) ...[
                ...filterOptions.map((option) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: 8.w),
                    child: _buildFilterTab(
                      context,
                      option.value,
                      option.label,
                      isSelected: selectedFilter == option.value,
                      onTap: () => onFilterChanged(option.value),
                    ),
                  ),
                )),
              ],
            ],
          ),
          SizedBox(height: 8.h),
          // Active Filters Chips
          if (dateRange != null || selectedFilter != 'all')
            Wrap(
              spacing: 8.w,
              runSpacing: 4.h,
              children: [
                if (dateRange != null)
                  Chip(
                    label: Text(
                      '${DateFormat('MMM dd').format(dateRange!.start)} - ${DateFormat('MMM dd, yyyy').format(dateRange!.end)}',
                      style: TextStyle(fontSize: 12.sp),
                    ),
                    deleteIcon: Icon(Icons.close, size: 16.sp),
                    onDeleted: () => onDateRangeChanged(null),
                    backgroundColor: Colors.blue.shade50,
                  ),
                if (selectedFilter != 'all')
                  Chip(
                    label: Text(
                      filterOptions.firstWhere(
                        (option) => option.value == selectedFilter,
                        orElse: () => const FilterOption('all', 'All'),
                      ).label,
                      style: TextStyle(fontSize: 12.sp),
                    ),
                    deleteIcon: Icon(Icons.close, size: 16.sp),
                    onDeleted: () => onFilterChanged('all'),
                    backgroundColor: Colors.orange.shade50,
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(
    BuildContext context,
    String value,
    String label, {
    required bool isSelected,
    IconData? icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 8.w),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey[200],
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16.sp,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
              SizedBox(width: 4.w),
            ],
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 11.sp,
                ),
                maxLines: 1,
                overflow: TextOverflow.visible,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: dateRange,
    );
    if (picked != null) {
      onDateRangeChanged(picked);
    }
  }
}

class FilterOption {
  final String value;
  final String label;

  const FilterOption(this.value, this.label);
}

// Predefined filter options for different contexts
class FilterOptions {
  static const List<FilterOption> bookingStatus = [
    FilterOption('all', 'All'),
    FilterOption('pending', 'Pending'),
    FilterOption('confirmed', 'Confirmed'),
    FilterOption('in_progress', 'In Progress'),
    FilterOption('completed', 'Completed'),
    FilterOption('cancelled', 'Cancelled'),
  ];

  static const List<FilterOption> technicianJobs = [
    FilterOption('all', 'All Jobs'),
    FilterOption('pending', 'Pending'),
    FilterOption('in_progress', 'In Progress'),
    FilterOption('completed', 'Completed'),
  ];

  static const List<FilterOption> offers = [
    FilterOption('all', 'All'),
    FilterOption('announcement', 'Announcements'),
    FilterOption('discount', 'Discounts'),
    FilterOption('promotion', 'Promotions'),
    FilterOption('news', 'News'),
  ];
}