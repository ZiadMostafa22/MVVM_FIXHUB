import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:car_maintenance_system_new/features/booking/domain/entities/booking_entity.dart';
import 'package:car_maintenance_system_new/features/car/domain/entities/car_entity.dart';

class DetailedInvoiceDialog extends StatelessWidget {
  final BookingEntity booking;
  final CarEntity? car;

  const DetailedInvoiceDialog({
    super.key,
    required this.booking,
    this.car,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Container(
        width: 0.9.sw,
        constraints: BoxConstraints(
          maxHeight: 0.8.sh,
          maxWidth: 0.9.sw,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12.r),
                  topRight: Radius.circular(12.r),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.receipt_long,
                    color: Colors.white,
                    size: 20.sp,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Service Invoice',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20.sp,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Booking Info
                    _buildSection(
                      context,
                      'Booking Information',
                      [
                        _buildInfoRow('Booking ID', booking.id),
                        _buildInfoRow('Date', DateFormat('MMM dd, yyyy').format(booking.scheduledDate)),
                        _buildInfoRow('Time', booking.timeSlot),
                        if (car != null)
                          _buildInfoRow('Vehicle', '${car!.make} ${car!.model} (${car!.year})'),
                        if (car != null)
                          _buildInfoRow('License Plate', car!.licensePlate),
                        _buildInfoRow('Service Type', _getMaintenanceTypeName(booking.maintenanceType)),
                        if (booking.description != null && booking.description!.isNotEmpty)
                          _buildInfoRow('Description', booking.description!),
                      ],
                    ),
                    
                    SizedBox(height: 20.h),
                    
                    // Service Items
                    _buildSection(
                      context,
                      'Service Items & Parts',
                      [
                        if (booking.serviceItems != null && booking.serviceItems!.isNotEmpty)
                          ...booking.serviceItems!.map((item) => _buildServiceItemRow(context, item))
                        else
                          _buildInfoRow('No service items', ''),
                      ],
                    ),
                    
                    SizedBox(height: 20.h),
                    
                    // Cost Breakdown
                    _buildSection(
                      context,
                      'Cost Breakdown',
                      [
                        if (booking.serviceItems != null && booking.serviceItems!.isNotEmpty)
                          _buildCostRow(context, 'Service Items Total', _calculateServiceItemsTotal()),
                        _buildCostRow(context, 'Labor Cost', booking.laborCost?.toDouble() ?? 0.0),
                        _buildCostRow(context, 'Subtotal', booking.subtotal),
                        if (booking.discountPercentage != null && booking.discountPercentage! > 0) ...[
                          _buildCostRow(
                            context,
                            'Discount (${booking.discountPercentage}%)',
                            -booking.discountAmount,
                            color: Colors.green,
                          ),
                          _buildCostRow(context, 'After Discount', booking.subtotalAfterDiscount),
                        ],
                        _buildCostRow(context, 'Tax (10%)', booking.tax ?? 0.0),
                        const Divider(height: 20),
                        _buildCostRow(
                          context,
                          'Total Cost',
                          booking.totalCost,
                          isTotal: true,
                        ),
                      ],
                    ),
                    
                    if (booking.offerCode != null || booking.offerTitle != null) ...[
                      SizedBox(height: 20.h),
                      _buildSection(
                        context,
                        'Discount Information',
                        [
                          if (booking.offerCode != null)
                            _buildInfoRow('Discount Code', booking.offerCode!),
                          if (booking.offerTitle != null)
                            _buildInfoRow('Offer Title', booking.offerTitle!),
                          if (booking.discountPercentage != null)
                            _buildInfoRow('Discount Percentage', '${booking.discountPercentage}%'),
                        ],
                      ),
                    ],
                    
                    if (booking.technicianNotes != null && booking.technicianNotes!.isNotEmpty) ...[
                      SizedBox(height: 20.h),
                      _buildSection(
                        context,
                        'Technician Notes',
                        [
                          _buildInfoRow('Notes', booking.technicianNotes!),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            // Footer
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12.r),
                  bottomRight: Radius.circular(12.r),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Generated: ${DateFormat('MMM dd, HH:mm').format(DateTime.now())}',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      minimumSize: Size(0, 32.h),
                    ),
                    child: Text(
                      'Close',
                      style: TextStyle(fontSize: 12.sp),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 8.h),
        ...children,
        SizedBox(height: 16.h),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80.w,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 11.sp),
              overflow: TextOverflow.ellipsis,
              maxLines: 3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceItemRow(BuildContext context, dynamic item) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                Text(
                  '${item.type.toString().split('.').last} • Qty: ${item.quantity}',
                  style: TextStyle(
                    fontSize: 9.sp,
                    color: Colors.grey[600],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '\$${item.totalPrice.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).primaryColor,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostRow(BuildContext context, String label, double amount, {Color? color, bool isTotal = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: isTotal ? 13.sp : 11.sp,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
                color: isTotal ? Theme.of(context).primaryColor : null,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isTotal ? 13.sp : 11.sp,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: color ?? (isTotal ? Theme.of(context).primaryColor : null),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  double _calculateServiceItemsTotal() {
    if (booking.serviceItems == null || booking.serviceItems!.isEmpty) {
      return 0.0;
    }
    return booking.serviceItems!.fold<double>(0, (sum, item) => sum + item.totalPrice);
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
}