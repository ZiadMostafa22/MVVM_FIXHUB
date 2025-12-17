import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:car_maintenance_system_new/features/inventory/domain/entities/inventory_entity.dart';

class InventoryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all inventory items
  Stream<List<InventoryItemEntity>> getInventoryStream({bool activeOnly = true}) {
    Query query = _firestore.collection('inventory');
    
    if (activeOnly) {
      query = query.where('isActive', isEqualTo: true);
    }
    
    return query.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) =>
            InventoryItemEntity.fromFirestore(
                doc.data() as Map<String, dynamic>, doc.id)
        ).toList());
  }

  // Get low stock items
  Stream<List<InventoryItemEntity>> getLowStockItems() {
    return getInventoryStream().map((items) =>
        items.where((item) => item.isLowStock).toList());
  }

  // Create inventory item
  Future<String> createInventoryItem(InventoryItemEntity item) async {
    try {
      final doc = await _firestore.collection('inventory').add(item.toFirestore());
      debugPrint('✅ Inventory item created: ${doc.id}');
      return doc.id;
    } catch (e) {
      debugPrint('❌ Error creating inventory item: $e');
      rethrow;
    }
  }

  // Update stock quantity with transaction logging
  Future<void> updateStock({
    required String itemId,
    required int quantity,
    required String type,  // 'in' or 'out'
    String? bookingId,
    String? technicianId,
    String? reason,
    String? notes,
    required String userId,
  }) async {
    try {
      final itemDoc = _firestore.collection('inventory').doc(itemId);
      final itemSnapshot = await itemDoc.get();
      
      if (!itemSnapshot.exists) {
        throw Exception('Inventory item not found');
      }
      
      final item = InventoryItemEntity.fromFirestore(
          itemSnapshot.data()!, itemSnapshot.id);

      final quantityChange = type == 'in' ? quantity : -quantity;
      final newStock = item.currentStock + quantityChange;

      if (newStock < 0) {
        throw Exception('Insufficient stock');
      }

      // Update inventory
      await itemDoc.update({
        'currentStock': newStock,
        'updatedAt': FieldValue.serverTimestamp(),
        if (type == 'in') 'lastRestocked': FieldValue.serverTimestamp(),
      });

      // Create transaction record
      await _firestore.collection('inventory_transactions').add({
        'inventoryItemId': itemId,
        'type': type,
        'quantity': quantity,
        'quantityBefore': item.currentStock,
        'quantityAfter': newStock,
        'bookingId': bookingId,
        'technicianId': technicianId,
        'reason': reason ?? (type == 'in' ? 'Restocked' : 'Used'),
        'notes': notes,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': userId,
      });

      // Check for low stock alert
      if (newStock <= item.lowStockThreshold) {
        await _createLowStockAlert(itemId, item.name, newStock, item.lowStockThreshold);
      }
      
      debugPrint('✅ Stock updated: $itemId, new stock: $newStock');
    } catch (e) {
      debugPrint('❌ Error updating stock: $e');
      rethrow;
    }
  }

  // Record part usage from booking
  Future<void> recordPartUsage({
    required String itemId,
    required int quantity,
    required String bookingId,
    required String technicianId,
  }) async {
    await updateStock(
      itemId: itemId,
      quantity: quantity,
      type: 'out',
      bookingId: bookingId,
      technicianId: technicianId,
      reason: 'Used in booking',
      notes: 'Auto-recorded from booking',
      userId: technicianId,
    );
  }

  // Restock item
  Future<void> restockItem({
    required String itemId,
    required int quantity,
    required String userId,
    String? notes,
  }) async {
    await updateStock(
      itemId: itemId,
      quantity: quantity,
      type: 'in',
      reason: 'Restocked',
      notes: notes,
      userId: userId,
    );
  }

  // Update inventory item details
  Future<void> updateInventoryItem(String id, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('inventory').doc(id).update({
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ Inventory item updated: $id');
    } catch (e) {
      debugPrint('❌ Error updating inventory item: $e');
      rethrow;
    }
  }

  // Delete (soft delete)
  Future<void> deleteInventoryItem(String id) async {
    try {
      await _firestore.collection('inventory').doc(id).update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ Inventory item deactivated: $id');
    } catch (e) {
      debugPrint('❌ Error deleting inventory item: $e');
      rethrow;
    }
  }

  // Get transaction history for an item
  Stream<List<InventoryTransactionEntity>> getTransactionHistory(String itemId) {
    return _firestore
        .collection('inventory_transactions')
        .where('inventoryItemId', isEqualTo: itemId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InventoryTransactionEntity.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  // Private helper: Create low stock alert
  Future<void> _createLowStockAlert(
      String itemId, String itemName, int currentStock, int threshold) async {
    try {
      // Check if alert already exists
      final existingAlert = await _firestore
          .collection('low_stock_alerts')
          .where('inventoryItemId', isEqualTo: itemId)
          .where('status', isEqualTo: 'pending')
          .get();

      if (existingAlert.docs.isEmpty) {
        await _firestore.collection('low_stock_alerts').add({
          'inventoryItemId': itemId,
          'itemName': itemName,
          'currentStock': currentStock,
          'threshold': threshold,
          'status': 'pending',
          'notifiedAdmins': [],
          'createdAt': FieldValue.serverTimestamp(),
          'resolvedAt': null,
        });
        debugPrint('⚠️ Low stock alert created for $itemName');
      }
    } catch (e) {
      debugPrint('❌ Error creating low stock alert: $e');
    }
  }

  // Resolve low stock alert
  Future<void> resolveLowStockAlert(String alertId) async {
    await _firestore.collection('low_stock_alerts').doc(alertId).update({
      'status': 'resolved',
      'resolvedAt': FieldValue.serverTimestamp(),
    });
  }

  // Get pending alerts
  Stream<List<Map<String, dynamic>>> getPendingAlerts() {
    return _firestore
        .collection('low_stock_alerts')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {...doc.data(), 'id': doc.id})
            .toList());
  }
}
