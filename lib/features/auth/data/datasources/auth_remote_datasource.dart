import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:car_maintenance_system_new/core/services/firebase_service.dart';

/// Remote data source for authentication operations
/// Handles all Firebase Auth and Firestore operations
class AuthRemoteDataSource {
  /// Get current authenticated user
  User? getCurrentUser() {
    return FirebaseService.auth.currentUser;
  }

  /// Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await FirebaseService.auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error signing in: $e');
      }
      rethrow;
    }
  }

  /// Create user with email and password
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await FirebaseService.auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error creating user: $e');
      }
      rethrow;
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      await FirebaseService.auth.signOut();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error signing out: $e');
      }
      rethrow;
    }
  }

  /// Delete current user account
  Future<void> deleteUser() async {
    try {
      await FirebaseService.auth.currentUser?.delete();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error deleting user: $e');
      }
      rethrow;
    }
  }

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

  /// Create user document in Firestore
  Future<void> createUserDocument({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await FirebaseService.usersCollection.doc(userId).set(data);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error creating user document: $e');
      }
      rethrow;
    }
  }

  /// Validate invite code
  Future<Map<String, dynamic>?> validateInviteCode(String inviteCode) async {
    try {
      final inviteSnapshot = await FirebaseService.firestore
          .collection('invite_codes')
          .where('code', isEqualTo: inviteCode)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (inviteSnapshot.docs.isEmpty) {
        return null;
      }

      final inviteData = inviteSnapshot.docs.first.data();
      return {
        'id': inviteSnapshot.docs.first.id,
        'data': inviteData,
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error validating invite code: $e');
      }
      rethrow;
    }
  }

  /// Mark invite code as used
  Future<void> markInviteCodeAsUsed({
    required String inviteCodeDocId,
    required String userId,
  }) async {
    try {
      final inviteDoc = FirebaseService.firestore
          .collection('invite_codes')
          .doc(inviteCodeDocId);

      final inviteData = (await inviteDoc.get()).data();
      if (inviteData == null) return;

      final currentUsedCount = (inviteData['usedCount'] ?? 0) as int;
      final maxUses = (inviteData['maxUses'] ?? 1) as int;

      await inviteDoc.update({
        'usedCount': currentUsedCount + 1,
        'isActive': (currentUsedCount + 1) < maxUses,
        'lastUsedAt': FieldValue.serverTimestamp(),
        'usedBy': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error marking invite code as used: $e');
      }
      rethrow;
    }
  }
}

