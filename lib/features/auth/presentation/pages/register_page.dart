import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:car_maintenance_system_new/features/auth/presentation/viewmodels/auth_viewmodel.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _inviteCodeController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _showInviteCode = false;
  String _selectedRole = 'customer';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _inviteCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      final success = await ref.read(authViewModelProvider.notifier).signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        role: _selectedRole,
        inviteCode: _showInviteCode ? _inviteCodeController.text.trim() : null,
      );
      
      if (success && mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully! Redirecting...'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        // Navigation is handled automatically by the router
      } else if (mounted) {
        final errorMessage = ref.read(authViewModelProvider).error ?? 'Registration failed. Please try again.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    
    // Responsive sizing
    final logoSize = screenHeight * 0.08 < 60 ? 60.0 : (screenHeight * 0.08 > 80 ? 80.0 : screenHeight * 0.08);
    final horizontalPadding = screenWidth * 0.06 < 16 ? 16.0 : (screenWidth * 0.06 > 24 ? 24.0 : screenWidth * 0.06);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, keyboardHeight + 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Column(
                  children: [
                    Container(
                      width: logoSize,
                      height: logoSize,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(logoSize / 2),
                      ),
                      child: Icon(
                        Icons.person_add,
                        size: logoSize * 0.5,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.015),
                    Text(
                      'Join Car Maintenance',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: screenWidth * 0.055 < 18 ? 18.0 : (screenWidth * 0.055 > 24 ? 24.0 : screenWidth * 0.055),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: screenHeight * 0.008),
                    Text(
                      'Create your account to get started',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                        fontSize: screenWidth * 0.038 < 13 ? 13.0 : (screenWidth * 0.038 > 15 ? 15.0 : screenWidth * 0.038),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                
                SizedBox(height: screenHeight * 0.025),
                
                // Name Field
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person),
                    isDense: true,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    if (value.length < 2) {
                      return 'Name must be at least 2 characters';
                    }
                    return null;
                  },
                ),
                SizedBox(height: screenHeight * 0.015),
                
                // Email Field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                    isDense: true,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                SizedBox(height: screenHeight * 0.015),
                
                // Phone Field
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone),
                    isDense: true,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    if (value.length < 10) {
                      return 'Please enter a valid phone number';
                    }
                    return null;
                  },
                ),
                SizedBox(height: screenHeight * 0.015),
                
                // Account Type Selection (Secure)
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).dividerColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      RadioListTile<String>(
                        title: const Text('Customer Account'),
                        subtitle: const Text('Book services and manage your vehicles'),
                        value: 'customer',
                        groupValue: _selectedRole,
                        onChanged: (value) {
                          setState(() {
                            _selectedRole = 'customer';
                            _showInviteCode = false;
                          });
                        },
                      ),
                      const Divider(height: 1),
                      RadioListTile<String>(
                        title: const Text('Technician Account'),
                        subtitle: const Text('Requires an invite code from admin'),
                        value: 'technician',
                        groupValue: _selectedRole,
                        onChanged: (value) {
                          setState(() {
                            _selectedRole = 'technician';
                            _showInviteCode = true;
                          });
                        },
                      ),
                      const Divider(height: 1),
                      RadioListTile<String>(
                        title: const Text('Cashier Account'),
                        subtitle: const Text('Requires an invite code from admin'),
                        value: 'cashier',
                        groupValue: _selectedRole,
                        onChanged: (value) {
                          setState(() {
                            _selectedRole = 'cashier';
                            _showInviteCode = true;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(height: screenHeight * 0.015),
                
                // Invite Code Field (Only for Technicians/Cashiers)
                if (_showInviteCode)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _inviteCodeController,
                        decoration: const InputDecoration(
                          labelText: 'Invite Code *',
                          prefixIcon: Icon(Icons.vpn_key),
                          isDense: true,
                          helperText: 'Enter the invite code provided by the administrator',
                          helperMaxLines: 2,
                        ),
                        validator: (value) {
                          if (_showInviteCode && (value == null || value.isEmpty)) {
                            return 'Invite code is required for this account type';
                          }
                          if (_showInviteCode && value!.length < 6) {
                            return 'Invalid invite code format';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: screenHeight * 0.015),
                    ],
                  ),
                
                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock),
                    isDense: true,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                SizedBox(height: screenHeight * 0.015),
                
                // Confirm Password Field
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    isDense: true,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                SizedBox(height: screenHeight * 0.025),
                
                // Register Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: authState.isLoading ? null : _handleRegister,
                    child: authState.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Create Account'),
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),
                
                // Login Link
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: screenWidth * 0.035 < 13 ? 13.0 : (screenWidth * 0.035 > 15 ? 15.0 : screenWidth * 0.035),
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: Text(
                        'Sign In',
                        style: TextStyle(
                          fontSize: screenWidth * 0.035 < 13 ? 13.0 : (screenWidth * 0.035 > 15 ? 15.0 : screenWidth * 0.035),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
