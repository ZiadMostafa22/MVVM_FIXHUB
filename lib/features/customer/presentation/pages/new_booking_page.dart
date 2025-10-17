import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:car_maintenance_system_new/core/providers/auth_provider.dart';
import 'package:car_maintenance_system_new/core/providers/booking_provider.dart';
import 'package:car_maintenance_system_new/core/providers/car_provider.dart';
import 'package:car_maintenance_system_new/core/models/booking_model.dart';
import 'package:car_maintenance_system_new/core/models/offer_model.dart';
import 'package:car_maintenance_system_new/core/utils/discount_validator.dart';

class NewBookingPage extends ConsumerStatefulWidget {
  const NewBookingPage({super.key});

  @override
  ConsumerState<NewBookingPage> createState() => _NewBookingPageState();
}

class _NewBookingPageState extends ConsumerState<NewBookingPage> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedCarId;
  String? _selectedService;
  MaintenanceType _selectedMaintenanceType = MaintenanceType.regular;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final _descriptionController = TextEditingController();
  final _discountCodeController = TextEditingController();
  OfferModel? _appliedOffer;
  bool _isValidatingCode = false;

  final List<String> _services = [
    'Oil Change',
    'Tire Rotation',
    'Brake Inspection',
    'Engine Tune-up',
    'Battery Replacement',
    'AC Service',
    'Transmission Service',
    'General Inspection',
    'Wheel Alignment',
    'Suspension Repair',
    'Other',
  ];

  final Map<MaintenanceType, String> _maintenanceTypeNames = {
    MaintenanceType.regular: 'Regular Maintenance',
    MaintenanceType.inspection: 'Inspection',
    MaintenanceType.repair: 'Repair',
    MaintenanceType.emergency: 'Emergency',
  };

  @override
  void initState() {
    super.initState();
    // Load user's cars
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider).user;
      if (user != null) {
        ref.read(carProvider.notifier).loadCars(user.id);
      }
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _discountCodeController.dispose();
    super.dispose();
  }

  Future<void> _validateDiscountCode() async {
    final code = _discountCodeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a discount code'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isValidatingCode = true);

    try {
      final result = await DiscountValidator.validateDiscountCode(code);

      if (!mounted) return;

      setState(() => _isValidatingCode = false);

      if (result['valid'] == true) {
        setState(() {
          _appliedOffer = result['offer'] as OfferModel;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] as String),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        setState(() {
          _appliedOffer = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] as String),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      setState(() => _isValidatingCode = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _removeDiscountCode() {
    setState(() {
      _appliedOffer = null;
      _discountCodeController.clear();
    });
  }

  Future<void> _selectDate() async {
    // Allow booking from today onwards
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastDate = DateTime.now().add(const Duration(days: 90));
    final predicate = (DateTime date) => date.weekday != DateTime.friday;
    
    // Ensure initialDate satisfies selectableDayPredicate to avoid assertion error
    DateTime initialDate = today;
    while (!predicate(initialDate) && initialDate.isBefore(lastDate)) {
      initialDate = initialDate.add(const Duration(days: 1));
    }
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: today, // Can book from today
      lastDate: lastDate,
      selectableDayPredicate: predicate,
      helpText: 'Select Appointment Date (Closed on Fridays)',
    );
    
    if (picked != null) {
      // Double check that it's not Friday
      if (picked.weekday == DateTime.friday) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('We are closed on Fridays. Please select another day.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }
      
      setState(() {
        _selectedDate = picked;
        // Reset time selection when date changes
        _selectedTime = null;
      });
    }
  }

  Future<void> _selectTime() async {
    // Validate that date is selected first
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a date first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // Check if selected date is Friday (day 5 in Dart - Monday is 1)
    if (_selectedDate!.weekday == DateTime.friday) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('We are closed on Fridays. Please select another day.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
      helpText: 'Working Hours: 8:00 AM - 6:00 PM',
    );
    
    if (picked != null) {
      // Validate working hours (8 AM to 6 PM)
      // Allow times from 8:00 to 18:00 (6:00 PM)
      final pickedHour = picked.hour;
      
      if (pickedHour < 8 || pickedHour > 18) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a time between 8:00 AM and 6:00 PM'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }
      
      // Allow 6:00 PM exactly, but not after
      if (pickedHour == 18 && picked.minute > 0) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Last appointment time is 6:00 PM'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }
      
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _submitBooking() async {
    print('📝 Submit booking called');
    
    if (_formKey.currentState!.validate()) {
      print('✅ Form validated');
      
      if (_selectedCarId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a car')),
        );
        return;
      }
      if (_selectedService == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a service')),
        );
        return;
      }
      if (_selectedDate == null || _selectedTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select date and time')),
        );
        return;
      }
      
      // Final validation for working hours
      if (_selectedDate!.weekday == DateTime.friday) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('We are closed on Fridays. Please select another day.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Validate working hours (8 AM to 6 PM)
      if (_selectedTime!.hour < 8 || _selectedTime!.hour > 18) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a time between 8:00 AM and 6:00 PM'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Allow 6:00 PM exactly, but not after
      if (_selectedTime!.hour == 18 && _selectedTime!.minute > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Last appointment time is 6:00 PM'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final user = ref.read(authProvider).user;
      if (user == null) {
        print('❌ User is null');
        return;
      }

      print('👤 User: ${user.id}');
      print('🚗 Car: $_selectedCarId');
      print('🛠️ Service: $_selectedService');
      print('💰 Discount: ${_appliedOffer?.code} (${_appliedOffer?.discountPercentage}%)');
      print('💰 Offer Title: ${_appliedOffer?.title}');
      print('💰 Offer ID: ${_appliedOffer?.id}');

      final scheduledDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      final booking = BookingModel(
        id: '',
        userId: user.id,
        carId: _selectedCarId!,
        serviceId: 'service_${DateTime.now().millisecondsSinceEpoch}', // Generate temporary service ID
        maintenanceType: _selectedMaintenanceType,
        scheduledDate: scheduledDateTime,
        timeSlot: _selectedTime!.format(context),
        status: BookingStatus.pending,
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        offerCode: _appliedOffer?.code,
        offerTitle: _appliedOffer?.title,
        discountPercentage: _appliedOffer?.discountPercentage,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      print('📤 Creating booking...');
      final success = await ref.read(bookingProvider.notifier).createBooking(booking);
      print('📥 Booking result: $success');

      if (mounted) {
        print('🏠 Widget still mounted');
        if (success) {
          print('✅ Booking created successfully, closing page');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Booking created successfully!')),
          );
          context.pop();
        } else {
          final error = ref.read(bookingProvider).error ?? 'Failed to create booking';
          print('❌ Booking failed: $error');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } else {
        print('❌ Widget not mounted anymore');
      }
    } else {
      print('❌ Form validation failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final carState = ref.watch(carProvider);
    final bookingState = ref.watch(bookingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Booking'),
      ),
      body: carState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : carState.cars.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.directions_car, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('No cars registered'),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => context.go('/customer/cars'),
                        child: const Text('Add a Car'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Car Selection
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Select Car',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  decoration: const InputDecoration(
                                    labelText: 'Car',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    isDense: true,
                                  ),
                                  items: carState.cars.map((car) {
                                    return DropdownMenuItem(
                                      value: car.id,
                                      child: Text(
                                        '${car.make} ${car.model} (${car.year})',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedCarId = value;
                                    });
                                  },
                                  validator: (value) {
                                    if (value == null) {
                                      return 'Please select a car';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Service Selection
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Select Service',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  decoration: const InputDecoration(
                                    labelText: 'Service Type',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    isDense: true,
                                  ),
                                  items: _services.map((service) {
                                    return DropdownMenuItem(
                                      value: service,
                                      child: Text(service),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedService = value;
                                    });
                                  },
                                  validator: (value) {
                                    if (value == null) {
                                      return 'Please select a service';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Maintenance Type Selection
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Maintenance Type',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<MaintenanceType>(
                                  value: _selectedMaintenanceType,
                                  decoration: const InputDecoration(
                                    labelText: 'Type',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    isDense: true,
                                  ),
                                  items: _maintenanceTypeNames.entries.map((entry) {
                                    return DropdownMenuItem(
                                      value: entry.key,
                                      child: Text(entry.value),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedMaintenanceType = value!;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Date & Time Selection
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Schedule',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: _selectDate,
                                        icon: const Icon(Icons.calendar_today, size: 18),
                                        label: Text(
                                          _selectedDate == null
                                              ? 'Date'
                                              : DateFormat('MMM dd').format(_selectedDate!),
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: _selectTime,
                                        icon: const Icon(Icons.access_time, size: 18),
                                        label: Text(
                                          _selectedTime == null
                                              ? 'Time'
                                              : _selectedTime!.format(context),
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Description
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Additional Details',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _descriptionController,
                                  decoration: const InputDecoration(
                                    labelText: 'Description (Optional)',
                                    hintText: 'Enter any additional details...',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.all(12),
                                    isDense: true,
                                  ),
                                  maxLines: 3,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Discount Code
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Discount Code',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    TextButton.icon(
                                      onPressed: () => context.go('/customer/offers'),
                                      icon: const Icon(Icons.local_offer, size: 16),
                                      label: const Text('View Offers'),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (_appliedOffer == null) ...[
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: _discountCodeController,
                                          decoration: const InputDecoration(
                                            labelText: 'Enter Code (Optional)',
                                            hintText: 'e.g., SAVE20',
                                            border: OutlineInputBorder(),
                                            contentPadding: EdgeInsets.all(12),
                                            isDense: true,
                                          ),
                                          textCapitalization: TextCapitalization.characters,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton(
                                        onPressed: _isValidatingCode ? null : _validateDiscountCode,
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        ),
                                        child: _isValidatingCode
                                            ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child: CircularProgressIndicator(strokeWidth: 2),
                                              )
                                            : const Text('Apply'),
                                      ),
                                    ],
                                  ),
                                ] else ...[
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withValues(alpha: 0.1),
                                      border: Border.all(color: Colors.green),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.check_circle, color: Colors.green),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _appliedOffer!.title,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              Text(
                                                '${_appliedOffer!.discountPercentage}% off applied',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.green[700],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: _removeDiscountCode,
                                          icon: const Icon(Icons.close),
                                          tooltip: 'Remove',
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Submit Button
                        ElevatedButton(
                          onPressed: bookingState.isLoading ? null : _submitBooking,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(14),
                          ),
                          child: bookingState.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text(
                                  'Create Booking',
                                  style: TextStyle(fontSize: 16),
                                ),
                        ),
                        const SizedBox(height: 16), // Bottom padding
                      ],
                    ),
                  ),
                ),
    );
  }
}
