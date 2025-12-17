import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:car_maintenance_system_new/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:car_maintenance_system_new/core/services/firebase_service.dart';
import 'package:car_maintenance_system_new/core/models/user_model.dart' as app_models;
import 'package:car_maintenance_system_new/features/customer/presentation/widgets/customer_bottom_nav_bar.dart';

class CustomerProfilePage extends ConsumerStatefulWidget {
  const CustomerProfilePage({super.key});

  @override
  ConsumerState<CustomerProfilePage> createState() => _CustomerProfilePageState();
}

class _CustomerProfilePageState extends ConsumerState<CustomerProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isEditing = false;
  bool _isLoading = false;
  DateTime? _accountCreatedDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
      _loadUserFullData();
    });
  }

  void _loadUserData() {
    final user = ref.read(authViewModelProvider).user;
    if (user != null) {
      _nameController.text = user.name;
      _phoneController.text = user.phone;
    }
  }

  Future<void> _loadUserFullData() async {
    try {
      final user = ref.read(authViewModelProvider).user;
      if (user == null) return;

      final doc = await FirebaseService.usersCollection.doc(user.id).get();
      if (doc.exists) {
        final userData = app_models.UserModel.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
        if (mounted) {
          setState(() {
            _accountCreatedDate = userData.createdAt;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = ref.read(authViewModelProvider).user;
      if (user == null) throw 'User not found';

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.id)
          .update({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
      });

      // Reload user data - force a sign out and sign in wouldn't be ideal
      // Instead, just update the display (user will see changes on next login or reload)

      if (mounted) {
        setState(() {
          _isEditing = false;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() => _isEditing = true);
              },
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  _loadUserData(); // Reset to original values
                });
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Profile Avatar
              CircleAvatar(
                radius: 60,
                backgroundColor: Theme.of(context).primaryColor,
                child: Text(
                  user?.name.substring(0, 1).toUpperCase() ?? 'C',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Profile Information Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Personal Information',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          if (!_isEditing)
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () {
                                setState(() => _isEditing = true);
                              },
                              tooltip: 'Edit Information',
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Name Field
                      TextFormField(
                        controller: _nameController,
                        enabled: _isEditing,
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: const Icon(Icons.person),
                          border: const OutlineInputBorder(),
                          filled: !_isEditing,
                          fillColor: _isEditing ? null : Colors.grey.shade100,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Name is required';
                          }
                          if (value.trim().length < 2) {
                            return 'Name must be at least 2 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Email Field (Read-only)
                      TextFormField(
                        initialValue: user?.email ?? '',
                        enabled: false,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: const Icon(Icons.email),
                          border: const OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          helperText: 'Email cannot be changed',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Phone Field
                      TextFormField(
                        controller: _phoneController,
                        enabled: _isEditing,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          prefixIcon: const Icon(Icons.phone),
                          border: const OutlineInputBorder(),
                          filled: !_isEditing,
                          fillColor: _isEditing ? null : Colors.grey.shade100,
                          hintText: '+1 (555) 123-4567',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Phone number is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Role Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.badge, color: Colors.green.shade700, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'CUSTOMER',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Save Button (shown when editing)
                      if (_isEditing) ...[
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _saveProfile,
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.save),
                            label: Text(_isLoading ? 'Saving...' : 'Save Changes'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(16),
                              backgroundColor: Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Account Information Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Account Information',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: const Icon(Icons.calendar_today, color: Colors.blue),
                        title: const Text('Member Since'),
                        subtitle: Text(
                          _accountCreatedDate != null
                              ? DateFormat('MMMM dd, yyyy').format(_accountCreatedDate!)
                              : 'Loading...',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Sign Out Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Sign Out'),
                        content: const Text('Are you sure you want to sign out?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              ref.read(authViewModelProvider.notifier).signOut();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: const Text('Sign Out'),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign Out'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    foregroundColor: Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomerBottomNavBar(context: context),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
