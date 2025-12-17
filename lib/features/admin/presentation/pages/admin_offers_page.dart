import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:car_maintenance_system_new/core/models/offer_model.dart';
import 'package:car_maintenance_system_new/core/services/firebase_service.dart';
import 'package:car_maintenance_system_new/features/auth/presentation/viewmodels/auth_viewmodel.dart';

class AdminOffersPage extends ConsumerStatefulWidget {
  const AdminOffersPage({super.key});

  @override
  ConsumerState<AdminOffersPage> createState() => _AdminOffersPageState();
}

class _AdminOffersPageState extends ConsumerState<AdminOffersPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Offers', style: TextStyle(fontSize: 18.sp)),
        actions: [
          IconButton(
            icon: Icon(Icons.add, size: 24.sp),
            onPressed: () => _showOfferDialog(),
            tooltip: 'Add New Offer',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseService.firestore
            .collection('offers')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}', style: TextStyle(fontSize: 14.sp)),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_offer_outlined, size: 80.sp, color: Colors.grey),
                  SizedBox(height: 16.h),
                  Text('No offers created yet', style: TextStyle(fontSize: 16.sp)),
                  SizedBox(height: 8.h),
                  ElevatedButton.icon(
                    onPressed: () => _showOfferDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Create First Offer'),
                  ),
                ],
              ),
            );
          }

          final offers = snapshot.data!.docs
              .map((doc) => OfferModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
              .toList();

          return ListView.builder(
            padding: EdgeInsets.all(16.w),
            itemCount: offers.length,
            itemBuilder: (context, index) {
              final offer = offers[index];
              return _buildOfferCard(offer);
            },
          );
        },
      ),
    );
  }

  Widget _buildOfferCard(OfferModel offer) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: _getTypeColor(offer.type).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    _getTypeName(offer.type),
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                      color: _getTypeColor(offer.type),
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: offer.isActive ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    offer.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                      color: offer.isActive ? Colors.green : Colors.red,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, size: 20.sp),
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _showOfferDialog(offer: offer);
                        break;
                      case 'toggle':
                        _toggleOfferStatus(offer);
                        break;
                      case 'delete':
                        _deleteOffer(offer.id);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 16.sp),
                          SizedBox(width: 8.w),
                          Text('Edit', style: TextStyle(fontSize: 14.sp)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'toggle',
                      child: Row(
                        children: [
                          Icon(offer.isActive ? Icons.visibility_off : Icons.visibility, size: 16.sp),
                          SizedBox(width: 8.w),
                          Text(offer.isActive ? 'Deactivate' : 'Activate', style: TextStyle(fontSize: 14.sp)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 16.sp, color: Colors.red),
                          SizedBox(width: 8.w),
                          Text('Delete', style: TextStyle(fontSize: 14.sp, color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              offer.title,
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4.h),
            Text(
              offer.description,
              style: TextStyle(fontSize: 13.sp, color: Colors.grey[700]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 12.sp, color: Colors.grey),
                SizedBox(width: 4.w),
                Text(
                  DateFormat('MMM dd, yyyy').format(offer.startDate),
                  style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
                ),
                if (offer.endDate != null) ...[
                  SizedBox(width: 8.w),
                  Icon(Icons.arrow_forward, size: 12.sp, color: Colors.grey),
                  SizedBox(width: 4.w),
                  Text(
                    DateFormat('MMM dd, yyyy').format(offer.endDate!),
                    style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
                  ),
                ],
                if (offer.discountPercentage != null) ...[
                  const Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      '${offer.discountPercentage}% OFF',
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showOfferDialog({OfferModel? offer}) async {
    final isEdit = offer != null;
    final titleController = TextEditingController(text: offer?.title);
    final descriptionController = TextEditingController(text: offer?.description);
    final discountController = TextEditingController(
      text: offer?.discountPercentage?.toString() ?? '',
    );
    final codeController = TextEditingController(text: offer?.code);
    final termsController = TextEditingController(text: offer?.terms);
    
    OfferType selectedType = offer?.type ?? OfferType.announcement;
    DateTime startDate = offer?.startDate ?? DateTime.now();
    DateTime? endDate = offer?.endDate;
    bool isActive = offer?.isActive ?? true;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEdit ? 'Edit Offer' : 'Create New Offer', style: TextStyle(fontSize: 18.sp)),
          content: SingleChildScrollView(
            child: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Title',
                      labelStyle: TextStyle(fontSize: 14.sp),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  TextField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      labelStyle: TextStyle(fontSize: 14.sp),
                      border: const OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  SizedBox(height: 12.h),
                  DropdownButtonFormField<OfferType>(
                    initialValue: selectedType,
                    decoration: InputDecoration(
                      labelText: 'Type',
                      labelStyle: TextStyle(fontSize: 14.sp),
                      border: const OutlineInputBorder(),
                    ),
                    items: OfferType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(_getTypeName(type), style: TextStyle(fontSize: 14.sp)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => selectedType = value!);
                    },
                  ),
                  SizedBox(height: 12.h),
                  TextField(
                    controller: discountController,
                    decoration: InputDecoration(
                      labelText: 'Discount % (Optional)',
                      labelStyle: TextStyle(fontSize: 14.sp),
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 12.h),
                  ListTile(
                    title: Text('Start Date', style: TextStyle(fontSize: 14.sp)),
                    subtitle: Text(DateFormat('MMM dd, yyyy').format(startDate), style: TextStyle(fontSize: 12.sp)),
                    trailing: Icon(Icons.calendar_today, size: 20.sp),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: startDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) setState(() => startDate = date);
                    },
                  ),
                  ListTile(
                    title: Text('End Date (Optional)', style: TextStyle(fontSize: 14.sp)),
                    subtitle: Text(
                      endDate != null ? DateFormat('MMM dd, yyyy').format(endDate!) : 'No end date',
                      style: TextStyle(fontSize: 12.sp),
                    ),
                    trailing: Icon(Icons.event, size: 20.sp),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: endDate ?? startDate.add(const Duration(days: 30)),
                        firstDate: startDate,
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) setState(() => endDate = date);
                    },
                  ),
                  if (endDate != null)
                    TextButton(
                      onPressed: () => setState(() => endDate = null),
                      child: Text('Clear End Date', style: TextStyle(fontSize: 12.sp)),
                    ),
                  SizedBox(height: 12.h),
                  TextField(
                    controller: codeController,
                    decoration: InputDecoration(
                      labelText: 'Discount Code (Optional)',
                      labelStyle: TextStyle(fontSize: 14.sp),
                      hintText: 'e.g., SAVE20',
                      border: const OutlineInputBorder(),
                      helperText: 'Customers can enter this code to apply the discount',
                      helperMaxLines: 2,
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                  SizedBox(height: 12.h),
                  TextField(
                    controller: termsController,
                    decoration: InputDecoration(
                      labelText: 'Terms & Conditions (Optional)',
                      labelStyle: TextStyle(fontSize: 14.sp),
                      border: const OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  SizedBox(height: 12.h),
                  SwitchListTile(
                    title: Text('Active', style: TextStyle(fontSize: 14.sp)),
                    value: isActive,
                    onChanged: (value) => setState(() => isActive = value),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(fontSize: 14.sp)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty || descriptionController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all required fields'), backgroundColor: Colors.red),
                  );
                  return;
                }

                final user = ref.read(authViewModelProvider).user;
                if (user == null) return;

                final offerData = OfferModel(
                  id: offer?.id ?? '',
                  title: titleController.text.trim(),
                  description: descriptionController.text.trim(),
                  type: selectedType,
                  startDate: startDate,
                  endDate: endDate,
                  isActive: isActive,
                  createdBy: user.id,
                  createdAt: offer?.createdAt ?? DateTime.now(),
                  updatedAt: DateTime.now(),
                  discountPercentage: discountController.text.isNotEmpty ? int.tryParse(discountController.text) : null,
                  code: codeController.text.trim().isNotEmpty ? codeController.text.trim().toUpperCase() : null,
                  terms: termsController.text.trim().isNotEmpty ? termsController.text.trim() : null,
                );

                try {
                  if (isEdit) {
                    await FirebaseService.firestore
                        .collection('offers')
                        .doc(offer.id)
                        .update(offerData.toFirestore());
                  } else {
                    await FirebaseService.firestore
                        .collection('offers')
                        .add(offerData.toFirestore());
                  }

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isEdit ? 'Offer updated!' : 'Offer created!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: Text(isEdit ? 'Update' : 'Create', style: TextStyle(fontSize: 14.sp)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleOfferStatus(OfferModel offer) async {
    try {
      await FirebaseService.firestore
          .collection('offers')
          .doc(offer.id)
          .update({'isActive': !offer.isActive});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(offer.isActive ? 'Offer deactivated' : 'Offer activated'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteOffer(String offerId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Offer?', style: TextStyle(fontSize: 18.sp)),
        content: Text('This action cannot be undone.', style: TextStyle(fontSize: 14.sp)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(fontSize: 14.sp)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete', style: TextStyle(fontSize: 14.sp)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseService.firestore.collection('offers').doc(offerId).delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Offer deleted'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Color _getTypeColor(OfferType type) {
    switch (type) {
      case OfferType.announcement:
        return Colors.blue;
      case OfferType.discount:
        return Colors.red;
      case OfferType.promotion:
        return Colors.green;
      case OfferType.news:
        return Colors.orange;
    }
  }

  String _getTypeName(OfferType type) {
    switch (type) {
      case OfferType.announcement:
        return 'Announcement';
      case OfferType.discount:
        return 'Discount';
      case OfferType.promotion:
        return 'Promotion';
      case OfferType.news:
        return 'News';
    }
  }
}

