import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:car_maintenance_system_new/features/car/domain/entities/car_entity.dart';
import 'package:car_maintenance_system_new/features/car/domain/di/car_usecases_di.dart';
import 'package:car_maintenance_system_new/features/car/domain/usecases/get_cars_usecase.dart';
import 'package:car_maintenance_system_new/features/car/domain/usecases/get_car_by_id_usecase.dart';
import 'package:car_maintenance_system_new/features/car/domain/usecases/add_car_usecase.dart';
import 'package:car_maintenance_system_new/features/car/domain/usecases/update_car_usecase.dart';
import 'package:car_maintenance_system_new/features/car/domain/usecases/delete_car_usecase.dart';

final carViewModelProvider = StateNotifierProvider<CarViewModel, CarState>((ref) {
  final getCarsUseCase = ref.watch(getCarsUseCaseProvider);
  final getCarByIdUseCase = ref.watch(getCarByIdUseCaseProvider);
  final addCarUseCase = ref.watch(addCarUseCaseProvider);
  final updateCarUseCase = ref.watch(updateCarUseCaseProvider);
  final deleteCarUseCase = ref.watch(deleteCarUseCaseProvider);
  return CarViewModel(
    getCarsUseCase,
    getCarByIdUseCase,
    addCarUseCase,
    updateCarUseCase,
    deleteCarUseCase,
  );
});

// Type alias for convenience
typedef Car = CarEntity;

class CarState {
  final List<Car> cars;
  final bool isLoading;
  final String? error;

  CarState({
    this.cars = const [],
    this.isLoading = false,
    this.error,
  });

  CarState copyWith({
    List<Car>? cars,
    bool? isLoading,
    String? error,
  }) {
    return CarState(
      cars: cars ?? this.cars,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class CarViewModel extends StateNotifier<CarState> {
  final GetCarsUseCase getCarsUseCase;
  final GetCarByIdUseCase getCarByIdUseCase;
  final AddCarUseCase addCarUseCase;
  final UpdateCarUseCase updateCarUseCase;
  final DeleteCarUseCase deleteCarUseCase;

  CarViewModel(
    this.getCarsUseCase,
    this.getCarByIdUseCase,
    this.addCarUseCase,
    this.updateCarUseCase,
    this.deleteCarUseCase,
  ) : super(CarState());

  Future<void> loadCars(String userId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final cars = await getCarsUseCase(userId);

      state = state.copyWith(cars: cars, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> addCar(Car car) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final carId = await addCarUseCase(car);
      final newCar = car.copyWith(id: carId);

      state = state.copyWith(
        cars: [newCar, ...state.cars],
        isLoading: false,
      );

      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> updateCar(String carId, Map<String, dynamic> updates) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await updateCarUseCase(carId, updates);

      final updatedCars = state.cars.map((car) {
        if (car.id == carId) {
          // Create updated car entity
          return CarEntity(
            id: car.id,
            userId: car.userId,
            make: updates['make'] ?? car.make,
            model: updates['model'] ?? car.model,
            year: updates['year'] ?? car.year,
            color: updates['color'] ?? car.color,
            licensePlate: updates['licensePlate'] ?? car.licensePlate,
            type: updates['type'] != null
                ? CarType.values.firstWhere(
                    (e) => e.toString().split('.').last == updates['type'],
                    orElse: () => car.type,
                  )
                : car.type,
            vin: updates['vin'] ?? car.vin,
            engineType: updates['engineType'] ?? car.engineType,
            mileage: updates['mileage'] ?? car.mileage,
            images: updates['images'] ?? car.images,
            createdAt: car.createdAt,
            updatedAt: DateTime.now(),
          );
        }
        return car;
      }).toList();

      state = state.copyWith(cars: updatedCars, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deleteCar(String carId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await deleteCarUseCase(carId);

      final updatedCars = state.cars.where((car) => car.id != carId).toList();
      state = state.copyWith(cars: updatedCars, isLoading: false);

      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Get a car by ID, fetching it if not in the current list
  /// This ensures newly added cars are available immediately
  /// The state update will automatically notify all watchers (all technicians)
  Future<Car?> getCarById(String carId) async {
    // First check if car is already in the list
    final existingCar = state.cars.where((c) => c.id == carId).firstOrNull;
    if (existingCar != null) {
      return existingCar;
    }

    // If not found, fetch it from the repository
    try {
      final car = await getCarByIdUseCase(carId);
      if (car != null) {
        // Check again if car was added by another request (race condition protection)
        final alreadyExists = state.cars.any((c) => c.id == carId);
        if (!alreadyExists) {
          // Add the car to the state so it's available for all watchers (all technicians)
          // This state update will automatically trigger rebuilds for all widgets watching carViewModelProvider
          state = state.copyWith(
            cars: [car, ...state.cars],
          );
        } else {
          // Car was added by another request, return the existing one
          return state.cars.where((c) => c.id == carId).firstOrNull;
        }
      }
      return car;
    } catch (e) {
      return null;
    }
  }
}

