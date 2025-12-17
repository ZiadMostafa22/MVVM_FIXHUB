import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:car_maintenance_system_new/features/car/presentation/viewmodels/car_viewmodel.dart';

/// ViewModel for Customer Cars Page
/// Wraps CarViewModel for customer-specific operations
class CustomerCarsViewModel {
  final CarViewModel carViewModel;

  CustomerCarsViewModel({required this.carViewModel});

  /// Load customer's cars
  Future<void> loadCars(String userId) async {
    await carViewModel.loadCars(userId);
  }

  /// Add a new car
  Future<bool> addCar(car) async {
    return await carViewModel.addCar(car);
  }

  /// Update a car
  Future<bool> updateCar(String carId, Map<String, dynamic> updates) async {
    return await carViewModel.updateCar(carId, updates);
  }

  /// Delete a car
  Future<bool> deleteCar(String carId) async {
    return await carViewModel.deleteCar(carId);
  }
}

/// Provider for CustomerCarsViewModel
final customerCarsViewModelProvider = Provider<CustomerCarsViewModel>((ref) {
  return CustomerCarsViewModel(
    carViewModel: ref.read(carViewModelProvider.notifier),
  );
});

