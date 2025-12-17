import 'package:flutter/foundation.dart';
import 'package:car_maintenance_system_new/core/services/firebase_service.dart';

/// Remote data source for car operations
class CarRemoteDataSource {
  /// Load cars from Firestore
  Future<List<Map<String, dynamic>>> loadCars(String userId) async {
    try {
      final query = userId.isEmpty
          ? FirebaseService.carsCollection.orderBy('createdAt', descending: true)
          : FirebaseService.carsCollection.where('userId', isEqualTo: userId);

      final snapshot = await query.get();

      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading cars: $e');
      }
      rethrow;
    }
  }

  /// Get a single car by ID
  Future<Map<String, dynamic>?> getCarById(String carId) async {
    try {
      final doc = await FirebaseService.carsCollection.doc(carId).get();
      if (doc.exists) {
        return {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting car: $e');
      }
      rethrow;
    }
  }

  /// Create a new car
  Future<String> createCar(Map<String, dynamic> data) async {
    try {
      final docRef = await FirebaseService.carsCollection.add(data);
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error creating car: $e');
      }
      rethrow;
    }
  }

  /// Update a car
  Future<void> updateCar(
    String carId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await FirebaseService.carsCollection.doc(carId).update(updates);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error updating car: $e');
      }
      rethrow;
    }
  }

  /// Delete a car
  Future<void> deleteCar(String carId) async {
    try {
      await FirebaseService.carsCollection.doc(carId).delete();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error deleting car: $e');
      }
      rethrow;
    }
  }
}

