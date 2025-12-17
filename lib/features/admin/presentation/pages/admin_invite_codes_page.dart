import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:car_maintenance_system_new/core/services/firebase_service.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:math';

class AdminInviteCodesPage extends StatefulWidget {
  const AdminInviteCodesPage({super.key});

  @override
  State<AdminInviteCodesPage> createState() => _AdminInviteCodesPageState();
}

class _AdminInviteCodesPageState extends State<AdminInviteCodesPage> {
  final _roleController = TextEditingController(text: 'technician');
  final _maxUsesController = TextEditingController(text: '1');
  bool _isGenerating = false;

  @override
  void dispose() {
    _roleController.dispose();
    _maxUsesController.dispose();
    super.dispose();
  }

  String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(8, (index) => chars[random.nextInt(chars.length)]).join();
  }

  Future<void> _createInviteCode() async {
    if (_maxUsesController.text.isEmpty || int.tryParse(_maxUsesController.text) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid number for max uses'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final code = _generateInviteCode();
      final maxUses = int.parse(_maxUsesController.text);
      
      await FirebaseService.firestore.collection('invite_codes').add({
        'code': code,
        'role': _roleController.text,
        'maxUses': maxUses,
        'usedCount': 0,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': FirebaseService.auth.currentUser?.uid,
        'usedBy': [],
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invite code created: $code'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Copy',
              textColor: Colors.white,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: code));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Code copied to clipboard!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating invite code: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  Future<void> _toggleCodeStatus(String docId, bool currentStatus, List<dynamic> usedBy) async {
    try {
      // If deactivating the code, handle deactivation flow
      if (currentStatus && usedBy.isNotEmpty) {
        if (mounted) {
          final confirmDeactivateUsers = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(
                'Deactivate User Accounts?',
                style: TextStyle(fontSize: 18.sp),
              ),
              content: Text(
                'This code has been used by ${usedBy.length} user(s). Do you want to deactivate their accounts as well?',
                style: TextStyle(fontSize: 14.sp),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('No', style: TextStyle(fontSize: 14.sp)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: Text('Yes, Deactivate Users', style: TextStyle(fontSize: 14.sp)),
                ),
              ],
            ),
          );

          // Update the invite code status
          await FirebaseService.firestore
              .collection('invite_codes')
              .doc(docId)
              .update({'isActive': false});

          if (confirmDeactivateUsers == true) {
            // Deactivate all users who used this invite code
            final batch = FirebaseService.firestore.batch();
            for (final userId in usedBy) {
              final userRef = FirebaseService.firestore.collection('users').doc(userId as String);
              batch.update(userRef, {'isActive': false});
            }
            await batch.commit();
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Code deactivated and ${usedBy.length} user account(s) disabled'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Code deactivated (users remain active)'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          }
        }
      } 
      // If activating the code, handle reactivation flow
      else if (!currentStatus && usedBy.isNotEmpty) {
        if (mounted) {
          final confirmReactivateUsers = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(
                'Reactivate User Accounts?',
                style: TextStyle(fontSize: 18.sp),
              ),
              content: Text(
                'This code was used by ${usedBy.length} user(s). Do you want to reactivate their accounts as well?',
                style: TextStyle(fontSize: 14.sp),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('No', style: TextStyle(fontSize: 14.sp)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: TextButton.styleFrom(foregroundColor: Colors.green),
                  child: Text('Yes, Reactivate Users', style: TextStyle(fontSize: 14.sp)),
                ),
              ],
            ),
          );

          // Update the invite code status
          await FirebaseService.firestore
              .collection('invite_codes')
              .doc(docId)
              .update({'isActive': true});

          if (confirmReactivateUsers == true) {
            // Reactivate all users who used this invite code
            final batch = FirebaseService.firestore.batch();
            for (final userId in usedBy) {
              final userRef = FirebaseService.firestore.collection('users').doc(userId as String);
              batch.update(userRef, {'isActive': true});
            }
            await batch.commit();
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Code activated and ${usedBy.length} user account(s) enabled'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Code activated (users remain disabled)'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          }
        }
      }
      // Simple activation/deactivation with no users
      else {
        await FirebaseService.firestore
            .collection('invite_codes')
            .doc(docId)
            .update({'isActive': !currentStatus});
            
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Code ${!currentStatus ? "activated" : "deactivated"}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating code: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String> _getTechnicianNames(List<dynamic> userIds) async {
    if (userIds.isEmpty) {
      return 'Not used yet';
    }

    try {
      final names = <String>[];
      for (final userId in userIds) {
        final userDoc = await FirebaseService.firestore
            .collection('users')
            .doc(userId as String)
            .get();
        
        if (userDoc.exists) {
          final userData = userDoc.data();
          names.add(userData?['name'] ?? 'Unknown');
        }
      }
      return names.isEmpty ? 'Not used yet' : names.join(', ');
    } catch (e) {
      debugPrint('Error fetching technician names: $e');
      return 'Error loading names';
    }
  }

  Future<void> _deleteCode(String docId, String code) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Invite Code',
          style: TextStyle(fontSize: 18.sp),
        ),
        content: Text(
          'Are you sure you want to delete code: $code?',
          style: TextStyle(fontSize: 14.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(fontSize: 14.sp)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete', style: TextStyle(fontSize: 14.sp)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseService.firestore
            .collection('invite_codes')
            .doc(docId)
            .delete();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Code deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting code: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Invite Codes',
          style: TextStyle(fontSize: 18.sp),
        ),
      ),
      body: Column(
        children: [
          // Create Invite Code Section
          Card(
            margin: EdgeInsets.all(16.w),
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Generate New Invite Code',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 18.sp,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _roleController.text,
                          decoration: InputDecoration(
                            labelText: 'Role',
                            labelStyle: TextStyle(fontSize: 14.sp),
                            border: const OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 12.h,
                            ),
                          ),
                          style: TextStyle(fontSize: 14.sp),
                          items: [
                            DropdownMenuItem(
                              value: 'technician',
                              child: Text('Technician', style: TextStyle(fontSize: 14.sp)),
                            ),
                            DropdownMenuItem(
                              value: 'cashier',
                              child: Text('Cashier', style: TextStyle(fontSize: 14.sp)),
                            ),
                            DropdownMenuItem(
                              value: 'admin',
                              child: Text('Admin', style: TextStyle(fontSize: 14.sp)),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              _roleController.text = value;
                            }
                          },
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: TextFormField(
                          controller: _maxUsesController,
                          decoration: InputDecoration(
                            labelText: 'Max Uses',
                            labelStyle: TextStyle(fontSize: 14.sp),
                            border: const OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 12.h,
                            ),
                          ),
                          style: TextStyle(fontSize: 14.sp),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  SizedBox(
                    width: double.infinity,
                    height: 48.h,
                    child: ElevatedButton.icon(
                      onPressed: _isGenerating ? null : _createInviteCode,
                      icon: _isGenerating
                          ? SizedBox(
                              width: 16.w,
                              height: 16.w,
                              child: CircularProgressIndicator(strokeWidth: 2.w),
                            )
                          : Icon(Icons.add, size: 20.sp),
                      label: Text(
                        _isGenerating ? 'Generating...' : 'Generate Code',
                        style: TextStyle(fontSize: 14.sp),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // List of Invite Codes
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseService.firestore
                  .collection('invite_codes')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final codes = snapshot.data!.docs;

                if (codes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.code_off, size: 64.sp, color: Colors.grey),
                        SizedBox(height: 16.h),
                        Text(
                          'No invite codes yet',
                          style: TextStyle(fontSize: 16.sp),
                        ),
                        Text(
                          'Generate one using the form above',
                          style: TextStyle(color: Colors.grey, fontSize: 14.sp),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.all(16.w),
                  itemCount: codes.length,
                  itemBuilder: (context, index) {
                    final doc = codes[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final code = data['code'] as String;
                    final role = data['role'] as String;
                    final maxUses = data['maxUses'] as int;
                    final usedCount = data['usedCount'] as int;
                    final isActive = data['isActive'] as bool;
                    final usedBy = (data['usedBy'] as List<dynamic>?) ?? [];

                    return Card(
                      margin: EdgeInsets.only(bottom: 12.h),
                      child: Padding(
                        padding: EdgeInsets.all(12.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: isActive ? Colors.green : Colors.grey,
                                  radius: 20.r,
                                  child: Icon(
                                    isActive ? Icons.check : Icons.block,
                                    color: Colors.white,
                                    size: 20.sp,
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              code,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'monospace',
                                                fontSize: 16.sp,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          SizedBox(width: 8.w),
                                          InkWell(
                                            onTap: () {
                                              Clipboard.setData(ClipboardData(text: code));
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Code copied to clipboard!',
                                                    style: TextStyle(fontSize: 14.sp),
                                                  ),
                                                  duration: const Duration(seconds: 2),
                                                ),
                                              );
                                            },
                                            child: Padding(
                                              padding: EdgeInsets.all(4.w),
                                              child: Icon(Icons.copy, size: 18.sp),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 8.h),
                                      Wrap(
                                        spacing: 8.w,
                                        runSpacing: 4.h,
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        children: [
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 8.w,
                                              vertical: 4.h,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).colorScheme.primaryContainer,
                                              borderRadius: BorderRadius.circular(12.r),
                                            ),
                                            child: Text(
                                              role.toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 10.sp,
                                                fontWeight: FontWeight.w500,
                                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            'Uses: $usedCount/$maxUses',
                                            style: TextStyle(
                                              fontSize: 13.sp,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (usedBy.isNotEmpty) ...[
                                        SizedBox(height: 8.h),
                                        FutureBuilder<String>(
                                          future: _getTechnicianNames(usedBy),
                                          builder: (context, snapshot) {
                                            return Row(
                                              children: [
                                                Icon(
                                                  Icons.person,
                                                  size: 14.sp,
                                                  color: Colors.blue[700],
                                                ),
                                                SizedBox(width: 4.w),
                                                Expanded(
                                                  child: Text(
                                                    'Used by: ${snapshot.data ?? "Loading..."}',
                                                    style: TextStyle(
                                                      fontSize: 12.sp,
                                                      color: Colors.blue[700],
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                PopupMenuButton(
                                  padding: EdgeInsets.zero,
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      child: Row(
                                        children: [
                                          Icon(
                                            isActive ? Icons.block : Icons.check_circle,
                                            size: 18.sp,
                                          ),
                                          SizedBox(width: 8.w),
                                          Text(
                                            isActive ? 'Deactivate' : 'Activate',
                                            style: TextStyle(fontSize: 14.sp),
                                          ),
                                        ],
                                      ),
                                      onTap: () => _toggleCodeStatus(doc.id, isActive, usedBy),
                                    ),
                                    PopupMenuItem(
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.delete,
                                            size: 18.sp,
                                            color: Colors.red,
                                          ),
                                          SizedBox(width: 8.w),
                                          Text(
                                            'Delete',
                                            style: TextStyle(
                                              color: Colors.red,
                                              fontSize: 14.sp,
                                            ),
                                          ),
                                        ],
                                      ),
                                      onTap: () => _deleteCode(doc.id, code),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}


