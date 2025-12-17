import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:car_maintenance_system_new/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:car_maintenance_system_new/features/car/presentation/viewmodels/car_viewmodel.dart';
import 'package:car_maintenance_system_new/features/car/domain/entities/car_entity.dart';

class AddCarPage extends ConsumerStatefulWidget {
  const AddCarPage({super.key});

  @override
  ConsumerState<AddCarPage> createState() => _AddCarPageState();
}

class _AddCarPageState extends ConsumerState<AddCarPage> {
  final _formKey = GlobalKey<FormState>();
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _colorController = TextEditingController();
  final _plateNumberController = TextEditingController();
  final _vinController = TextEditingController();

  @override
  void dispose() {
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _colorController.dispose();
    _plateNumberController.dispose();
    _vinController.dispose();
    super.dispose();
  }

  Future<void> _submitCar() async {
    if (_formKey.currentState!.validate()) {
      final user = ref.read(authViewModelProvider).user;
      if (user == null) return;

      final car = CarEntity(
        id: '',
        userId: user.id,
        make: _makeController.text.trim(),
        model: _modelController.text.trim(),
        year: int.parse(_yearController.text.trim()),
        color: _colorController.text.trim(),
        licensePlate: _plateNumberController.text.trim(),
        type: CarType.sedan, // Default type, can be enhanced with a dropdown
        vin: _vinController.text.trim().isEmpty ? null : _vinController.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final success = await ref.read(carViewModelProvider.notifier).addCar(car);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Car added successfully!')),
          );
          context.pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(ref.read(carViewModelProvider).error ?? 'Failed to add car'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final carState = ref.watch(carViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Car'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Vehicle Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _makeController,
                        decoration: const InputDecoration(
                          labelText: 'Make *',
                          hintText: 'e.g., Toyota, Honda, Ford',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          isDense: true,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the car make';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _modelController,
                        decoration: const InputDecoration(
                          labelText: 'Model *',
                          hintText: 'e.g., Camry, Accord, F-150',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          isDense: true,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the car model';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _yearController,
                        decoration: const InputDecoration(
                          labelText: 'Year *',
                          hintText: 'e.g., 2020',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the car year';
                          }
                          final year = int.tryParse(value);
                          if (year == null || year < 1900 || year > DateTime.now().year + 1) {
                            return 'Please enter a valid year';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _colorController,
                        decoration: const InputDecoration(
                          labelText: 'Color *',
                          hintText: 'e.g., Red, Blue, Black',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          isDense: true,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the car color';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _plateNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Plate Number *',
                          hintText: 'e.g., ABC-1234',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          isDense: true,
                        ),
                        textCapitalization: TextCapitalization.characters,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the plate number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _vinController,
                        decoration: const InputDecoration(
                          labelText: 'VIN (Optional)',
                          hintText: 'Vehicle Identification Number',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          isDense: true,
                        ),
                        textCapitalization: TextCapitalization.characters,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: carState.isLoading ? null : _submitCar,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(14),
                ),
                child: carState.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Add Car',
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

