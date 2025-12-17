import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:car_maintenance_system_new/core/services/firebase_service.dart';

/// Remote data source for user operations
class UserRemoteDataSource {
  /// Get user document from Firestore
  Future<Map<String, dynamic>?> getUserDocument(String userId) async {
    try {
      final doc = await FirebaseService.usersCollection.doc(userId).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting user document: $e');
      }
      rethrow;
    }
  }

  /// Get all users
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final snapshot = await FirebaseService.usersCollection
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting all users: $e');
      }
      rethrow;
    }
  }

  /// Get users by role
  Future<List<Map<String, dynamic>>> getUsersByRole(String role) async {
    try {
      final snapshot = await FirebaseService.usersCollection
          .where('role', isEqualTo: role)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting users by role: $e');
      }
      rethrow;
    }
  }

  /// Stream all users
  Stream<List<Map<String, dynamic>>> watchAllUsers() {
    return FirebaseService.usersCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            }).toList());
  }

  /// Stream users by role
  Stream<List<Map<String, dynamic>>> watchUsersByRole(String role) {
    return FirebaseService.usersCollection
        .where('role', isEqualTo: role)
        .snapshots()
        .map((snapshot) {
      final users = snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      }).toList();
      // Sort by name in the app to avoid composite index requirement
      users.sort((a, b) {
        final nameA = (a['name'] ?? '').toString().toLowerCase();
        final nameB = (b['name'] ?? '').toString().toLowerCase();
        return nameA.compareTo(nameB);
      });
      return users;
    });
  }

  /// Update user document
  Future<void> updateUser(String userId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = Timestamp.now();
      await FirebaseService.usersCollection.doc(userId).update(updates);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error updating user: $e');
      }
      rethrow;
    }
  }

  /// Delete user document
  Future<void> deleteUser(String userId) async {
    try {
      await FirebaseService.usersCollection.doc(userId).delete();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error deleting user: $e');
      }
      rethrow;
    }
  }
}

