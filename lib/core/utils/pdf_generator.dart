import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:car_maintenance_system_new/features/booking/domain/entities/booking_entity.dart';
import 'package:car_maintenance_system_new/features/car/domain/entities/car_entity.dart';

class PdfGenerator {
  static Future<void> generateAndShareInvoice(
    BuildContext context,
    BookingEntity booking,
    CarEntity? car,
    dynamic customer, // Accept any customer object (User from auth or UserModel or Map)
  ) async {
    try {
      // Extract customer info from various formats
      String customerName = 'Customer';
      String? customerEmail;
      
      if (customer is Map) {
        customerName = customer['name']?.toString() ?? 'Customer';
        customerEmail = customer['email']?.toString();
      } else if (customer != null) {
        // Try to access as object
        try {
          customerName = customer.name?.toString() ?? 'Customer';
          customerEmail = customer.email?.toString();
        } catch (e) {
          debugPrint('Error accessing customer properties: $e');
        }
      }
      
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(),
                pw.SizedBox(height: 20),
                pw.Divider(thickness: 2),
                pw.SizedBox(height: 20),

                // Invoice Info
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'INVOICE',
                          style: pw.TextStyle(
                            fontSize: 32,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text('Invoice #: ${booking.id}'),
                        pw.Text(
                          'Date: ${DateFormat('MMM dd, yyyy').format(booking.scheduledDate)}',
                        ),
                        if (booking.completedAt != null)
                          pw.Text(
                            'Completed: ${DateFormat('MMM dd, yyyy HH:mm').format(booking.completedAt!)}',
                          ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'Car Maintenance System',
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text('123 Auto Service Lane'),
                        pw.Text('City, State 12345'),
                        pw.Text('Phone: (555) 123-4567'),
                        pw.Text('Email: service@carmaintenance.com'),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 30),

                // Customer Info
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'BILL TO',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        customerName,
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      if (customerEmail != null && customerEmail.isNotEmpty)
                        pw.Text(customerEmail),
                      pw.SizedBox(height: 8),
                      if (car != null) ...[
                        pw.Text(
                          'Vehicle: ${car.make} ${car.model} (${car.year})',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text('License Plate: ${car.licensePlate}'),
                        pw.Text('Color: ${car.color}'),
                      ],
                    ],
                  ),
                ),
                pw.SizedBox(height: 30),

                // Service Type
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.blue50,
                    borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Service Type:',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        _getMaintenanceTypeName(booking.maintenanceType),
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue800,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),

                // Service Items Table
                _buildServiceItemsTable(booking),
                pw.SizedBox(height: 20),

                // Labor Cost
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Container(
                      width: 200,
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Labor Cost:'),
                          pw.Text(
                            '\$${(booking.laborCost ?? 0).toStringAsFixed(2)}',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 10),

                // Subtotal
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Container(
                      width: 200,
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Subtotal:'),
                          pw.Text('\$${booking.subtotal.toStringAsFixed(2)}'),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 5),

                // Discount (if applied)
                if (booking.discountPercentage != null && booking.discountPercentage! > 0) ...[
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      pw.Container(
                        width: 200,
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              'Discount (${booking.discountPercentage}%):',
                              style: const pw.TextStyle(color: PdfColors.green800),
                            ),
                            pw.Text(
                              '-\$${booking.discountAmount.toStringAsFixed(2)}',
                              style: const pw.TextStyle(color: PdfColors.green800),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 5),
                  if (booking.offerCode != null) ...[
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
                        pw.Container(
                          width: 200,
                          child: pw.Text(
                            'Code: ${booking.offerCode}',
                            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 5),
                  ],
                ],

                // Tax (applied to discounted amount)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Container(
                      width: 200,
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Tax (10%):'),
                          pw.Text(
                            '\$${(booking.tax ?? (booking.subtotalAfterDiscount * 0.10)).toStringAsFixed(2)}',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 10),

                // Total
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Container(
                      width: 200,
                      padding: const pw.EdgeInsets.all(10),
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.green50,
                        borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
                      ),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'TOTAL:',
                            style: pw.TextStyle(
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            '\$${booking.totalCost.toStringAsFixed(2)}',
                            style: pw.TextStyle(
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.green800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Technician Notes
                if (booking.technicianNotes != null &&
                    booking.technicianNotes!.isNotEmpty) ...[
                  pw.SizedBox(height: 30),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey400),
                      borderRadius:
                          const pw.BorderRadius.all(pw.Radius.circular(8)),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Technician Notes:',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        pw.SizedBox(height: 6),
                        pw.Text(booking.technicianNotes!),
                      ],
                    ),
                  ),
                ],

                pw.Spacer(),

                // Footer
                pw.Divider(),
                pw.SizedBox(height: 10),
                pw.Center(
                  child: pw.Text(
                    'Thank you for choosing our service!',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue800,
                    ),
                  ),
                ),
                pw.Center(
                  child: pw.Text(
                    'For any questions, please contact us at service@carmaintenance.com',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );

      // Show PDF preview and sharing options
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Invoice_${booking.id}.pdf',
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
  }

  static pw.Widget _buildHeader() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: const pw.BoxDecoration(
        color: PdfColors.blue800,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'CAR MAINTENANCE INVOICE',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: const pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Text(
              'PAID',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.green800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildServiceItemsTable(BookingEntity booking) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _buildTableCell('Item', isHeader: true),
            _buildTableCell('Type', isHeader: true),
            _buildTableCell('Qty', isHeader: true),
            _buildTableCell('Price', isHeader: true),
            _buildTableCell('Total', isHeader: true),
          ],
        ),
        // Items
        if (booking.serviceItems != null && booking.serviceItems!.isNotEmpty)
          ...booking.serviceItems!.map((item) => pw.TableRow(
                children: [
                  _buildTableCell(item.name),
                  _buildTableCell(item.type.toString().split('.').last),
                  _buildTableCell(item.quantity.toString()),
                  _buildTableCell('\$${item.price.toStringAsFixed(2)}'),
                  _buildTableCell('\$${item.totalPrice.toStringAsFixed(2)}'),
                ],
              ))
        else
          pw.TableRow(
            children: [
              _buildTableCell('No items', colspan: 5),
            ],
          ),
      ],
    );
  }

  static pw.Widget _buildTableCell(String text,
      {bool isHeader = false, int colspan = 1}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          fontSize: isHeader ? 12 : 10,
        ),
      ),
    );
  }

  static String _getMaintenanceTypeName(MaintenanceType type) {
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

