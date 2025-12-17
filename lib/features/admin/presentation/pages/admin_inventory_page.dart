import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:car_maintenance_system_new/features/inventory/domain/entities/inventory_entity.dart';
import 'package:car_maintenance_system_new/features/inventory/data/repositories/inventory_repository.dart';
import 'package:car_maintenance_system_new/features/auth/presentation/viewmodels/auth_viewmodel.dart';

final inventoryRepositoryProvider = Provider((ref) => InventoryRepository());

final inventoryStreamProvider = StreamProvider<List<InventoryItemEntity>>((ref) {
  final repo = ref.watch(inventoryRepositoryProvider);
  return repo.getInventoryStream();
});

final lowStockAlertsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final repo = ref.watch(inventoryRepositoryProvider);
  return repo.getPendingAlerts();
});

class AdminInventoryPage extends ConsumerStatefulWidget {
  const AdminInventoryPage({super.key});

  @override
  ConsumerState<AdminInventoryPage> createState() => _AdminInventoryPageState();
}

class _AdminInventoryPageState extends ConsumerState<AdminInventoryPage> {
  @override
  Widget build(BuildContext context) {
    final inventoryAsync = ref.watch(inventoryStreamProvider);
    final alertsAsync = ref.watch(lowStockAlertsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Management'),
        actions: [
          alertsAsync.when(
            data: (alerts) => alerts.isEmpty
                ? const SizedBox()
                : Badge(
                    label: Text('${alerts.length}'),
                    child: IconButton(
                      icon: const Icon(Icons.warning),
                      onPressed: () => _showAlertsDialog(context, alerts),
                    ),
                  ),
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
        ],
      ),
      body: inventoryAsync.when(
        data: (items) {
          final lowStockCount = items.where((item) => item.isLowStock).length;
          
          return Column(
            children: [
              // Summary cards
              Padding(
                padding: EdgeInsets.all(16.w),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        'Total Items',
                        items.length.toString(),
                        Colors.blue,
                        Icons.inventory,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: _buildSummaryCard(
                        'Low Stock',
                        lowStockCount.toString(),
                        lowStockCount > 0 ? Colors.red : Colors.green,
                        Icons.warning,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Inventory list
              Expanded(
                child: items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 64.sp, color: Colors.grey),
                            SizedBox(height: 16.h),
                            const Text('No inventory items'),
                            SizedBox(height: 8.h),
                            ElevatedButton.icon(
                              onPressed: () => _showAddItemDialog(context),
                              icon: const Icon(Icons.add),
                              label: const Text('Add Item'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(16.w),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return _buildInventoryCard(item);
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddItemDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, Color color, IconData icon) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28.sp),
            SizedBox(height: 8.h),
            Text(value, style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryCard(InventoryItemEntity item) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: item.isLowStock ? Colors.red.shade100 : Colors.green.shade100,
          child: Text(
            item.currentStock.toString(),
            style: TextStyle(
              color: item.isLowStock ? Colors.red : Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SKU: ${item.sku}'),
            Text(
              'Cost: \$${item.unitCost.toStringAsFixed(2)} • Price: \$${item.unitPrice.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 12.sp),
            ),
            if (item.location != null)
              Text('📍 ${item.location}', style: TextStyle(fontSize: 12.sp)),
            if (item.isLowStock)
              Container(
                margin: EdgeInsets.only(top: 4.h),
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '⚠️ Low Stock',
                  style: TextStyle(color: Colors.red, fontSize: 11.sp),
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            switch (value) {
              case 'restock':
                _showRestockDialog(context, item);
                break;
              case 'adjust':
                _showAdjustDialog(context, item);
                break;
              case 'edit':
                _showEditDialog(context, item);
                break;
              case 'delete':
                await _deleteItem(item);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'restock', child: Text('Restock')),
            const PopupMenuItem(value: 'adjust', child: Text('Adjust Stock')),
            const PopupMenuItem(value: 'edit', child: Text('Edit Details')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  void _showRestockDialog(BuildContext context, InventoryItemEntity item) {
    final quantityController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Restock ${item.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current Stock: ${item.currentStock}'),
            SizedBox(height: 16.h),
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Quantity to Add',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final quantity = int.tryParse(quantityController.text);
              if (quantity != null && quantity > 0) {
                final authState = ref.read(authViewModelProvider);
                try {
                  await ref.read(inventoryRepositoryProvider).restockItem(
                    itemId: item.id,
                    quantity: quantity,
                    userId: authState.userId ?? 'admin',
                    notes: notesController.text,
                  );
                  if (mounted) {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Stock updated successfully')),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Restock'),
          ),
        ],
      ),
    );
  }

  void _showAdjustDialog(BuildContext context, InventoryItemEntity item) {
    final quantityController = TextEditingController();
    String adjustType = 'out';

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Adjust ${item.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Current Stock: ${item.currentStock}'),
              SizedBox(height: 16.h),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'in', label: Text('Add')),
                  ButtonSegment(value: 'out', label: Text('Remove')),
                ],
                selected: {adjustType},
                onSelectionChanged: (value) {
                  setDialogState(() {
                    adjustType = value.first;
                  });
                },
              ),
              SizedBox(height: 12.h),
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final quantity = int.tryParse(quantityController.text);
                if (quantity != null && quantity > 0) {
                  final authState = ref.read(authViewModelProvider);
                  try {
                    await ref.read(inventoryRepositoryProvider).updateStock(
                      itemId: item.id,
                      quantity: quantity,
                      type: adjustType,
                      reason: 'Manual adjustment',
                      userId: authState.userId ?? 'admin',
                    );
                    if (mounted) {
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Stock adjusted successfully')),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: const Text('Adjust'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddItemDialog(BuildContext context) {
    final nameController = TextEditingController();
    final skuController = TextEditingController();
    final stockController = TextEditingController(text: '0');
    final costController = TextEditingController();
    final priceController = TextEditingController();
    final locationController = TextEditingController();
    InventoryCategory selectedCategory = InventoryCategory.parts;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Inventory Item'),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(labelText: 'Name', border: const OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.all(12.w)),
                  ),
                  SizedBox(height: 10.h),
                  TextField(
                    controller: skuController,
                    decoration: InputDecoration(labelText: 'SKU', border: const OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.all(12.w)),
                  ),
                  SizedBox(height: 10.h),
                  TextField(
                    controller: stockController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: 'Initial Stock', border: const OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.all(12.w)),
                  ),
                  SizedBox(height: 10.h),
                  DropdownButtonFormField<InventoryCategory>(
                    initialValue: selectedCategory,
                    decoration: InputDecoration(labelText: 'Category', border: const OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.all(12.w)),
                    items: InventoryCategory.values.map((cat) => DropdownMenuItem(
                      value: cat,
                      child: Text(cat.toString().split('.').last, style: TextStyle(fontSize: 14.sp)),
                    )).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedCategory = value!;
                      });
                    },
                  ),
                  SizedBox(height: 10.h),
                  TextField(
                    controller: costController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: 'Unit Cost (\$)', border: const OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.all(12.w)),
                  ),
                  SizedBox(height: 10.h),
                  TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: 'Unit Price (\$)', border: const OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.all(12.w)),
                  ),
                  SizedBox(height: 10.h),
                  TextField(
                    controller: locationController,
                    decoration: InputDecoration(labelText: 'Location (optional)', border: const OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.all(12.w)),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final cost = double.tryParse(costController.text);
                final price = double.tryParse(priceController.text);
                final stock = int.tryParse(stockController.text) ?? 0;
                
                if (nameController.text.isEmpty || skuController.text.isEmpty || cost == null || price == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill in required fields')),
                  );
                  return;
                }

                final item = InventoryItemEntity(
                  id: '',
                  name: nameController.text,
                  sku: skuController.text,
                  category: selectedCategory,
                  currentStock: stock,
                  unitCost: cost,
                  unitPrice: price,
                  location: locationController.text.isEmpty ? null : locationController.text,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );

                try {
                  await ref.read(inventoryRepositoryProvider).createInventoryItem(item);
                  if (mounted) {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Item added successfully')),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, InventoryItemEntity item) {
    final nameController = TextEditingController(text: item.name);
    final costController = TextEditingController(text: item.unitCost.toString());
    final priceController = TextEditingController(text: item.unitPrice.toString());
    final locationController = TextEditingController(text: item.location ?? '');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: costController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Unit Cost', prefixText: '\$', border: OutlineInputBorder()),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Unit Price', prefixText: '\$', border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(labelText: 'Location', border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref.read(inventoryRepositoryProvider).updateInventoryItem(item.id, {
                  'name': nameController.text,
                  'unitCost': double.tryParse(costController.text) ?? item.unitCost,
                  'unitPrice': double.tryParse(priceController.text) ?? item.unitPrice,
                  'location': locationController.text.isEmpty ? null : locationController.text,
                });
                if (mounted) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Item updated successfully')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteItem(InventoryItemEntity item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "${item.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(inventoryRepositoryProvider).deleteInventoryItem(item.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  void _showAlertsDialog(BuildContext context, List<Map<String, dynamic>> alerts) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Low Stock Alerts'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: alerts.length,
            itemBuilder: (context, index) {
              final alert = alerts[index];
              return ListTile(
                leading: const Icon(Icons.warning, color: Colors.orange),
                title: Text(alert['itemName'] ?? 'Unknown'),
                subtitle: Text('Stock: ${alert['currentStock']} (threshold: ${alert['threshold']})'),
                trailing: TextButton(
                  onPressed: () async {
                    await ref.read(inventoryRepositoryProvider).resolveLowStockAlert(alert['id']);
                    if (mounted) Navigator.pop(context);
                  },
                  child: const Text('Resolve'),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
