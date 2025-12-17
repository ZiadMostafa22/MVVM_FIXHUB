import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:car_maintenance_system_new/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:car_maintenance_system_new/core/providers/theme_provider.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  String _selectedLanguage = 'English';
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final user = authState.user;
    final themeMode = ref.watch(themeModeProvider);
    final themeNotifier = ref.read(themeModeProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(fontSize: 18.sp),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Profile Section
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30.r,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Text(
                        (user?.name ?? 'U').substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? 'User',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            user?.email ?? 'user@example.com',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              (user?.role ?? 'user').toUpperCase(),
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 24.h),
            
            // Appearance Section
            Text(
              'Appearance',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            
            Card(
              child: Column(
                children: [
                  // Theme Mode
                  ListTile(
                    leading: Icon(
                      themeMode == ThemeMode.light
                          ? Icons.light_mode
                          : themeMode == ThemeMode.dark
                              ? Icons.dark_mode
                              : Icons.brightness_auto,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: const Text('Theme Mode'),
                    subtitle: Text(_getThemeModeDescription(themeMode)),
                    trailing: DropdownButton<ThemeMode>(
                      value: themeMode,
                      onChanged: (ThemeMode? newValue) {
                        if (newValue != null) {
                          themeNotifier.setThemeMode(newValue);
                        }
                      },
                      items: ThemeMode.values.map<DropdownMenuItem<ThemeMode>>(
                        (ThemeMode value) {
                          return DropdownMenuItem<ThemeMode>(
                            value: value,
                            child: Text(_getThemeModeName(value)),
                          );
                        },
                      ).toList(),
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 24.h),
            
            // Language Section
            Text(
              'Language',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            
            Card(
              child: ListTile(
                leading: Icon(
                  Icons.language,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: const Text('App Language'),
                subtitle: const Text('Choose your preferred language'),
                trailing: DropdownButton<String>(
                  value: _selectedLanguage,
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedLanguage = newValue;
                      });
                      _showLanguageChangeDialog(newValue);
                    }
                  },
                  items: <String>['English', 'العربية', 'Français', 'Español']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ),
            ),
            
            SizedBox(height: 24.h),
            
            // Notifications Section
            Text(
              'Notifications',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            
            Card(
              child: SwitchListTile(
                secondary: Icon(
                  Icons.notifications,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: const Text('Push Notifications'),
                subtitle: const Text('Receive notifications about your bookings'),
                value: _notificationsEnabled,
                onChanged: (bool value) {
                  setState(() {
                    _notificationsEnabled = value;
                  });
                  _showNotificationChangeDialog(value);
                },
              ),
            ),
            
            SizedBox(height: 24.h),
            
            // App Info Section
            Text(
              'App Information',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.info,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: const Text('App Version'),
                    subtitle: const Text('1.0.0'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      _showAppInfoDialog();
                    },
                  ),
                  
                  const Divider(height: 1),
                  
                  ListTile(
                    leading: Icon(
                      Icons.help,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: const Text('Help & Support'),
                    subtitle: const Text('Get help and contact support'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      _showHelpDialog();
                    },
                  ),
                  
                  const Divider(height: 1),
                  
                  ListTile(
                    leading: Icon(
                      Icons.privacy_tip,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: const Text('Privacy Policy'),
                    subtitle: const Text('Read our privacy policy'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      _showPrivacyDialog();
                    },
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 32.h),
          ],
        ),
      ),
    );
  }

  String _getThemeModeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  String _getThemeModeDescription(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Always use light theme';
      case ThemeMode.dark:
        return 'Always use dark theme';
      case ThemeMode.system:
        return 'Follow system setting';
    }
  }

  void _showLanguageChangeDialog(String language) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Language Changed'),
        content: Text('App language changed to $language. Restart the app to apply changes.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showNotificationChangeDialog(bool enabled) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notifications'),
        content: Text(
          enabled
              ? 'Push notifications have been enabled.'
              : 'Push notifications have been disabled.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAppInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('App Information'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Car Maintenance System'),
            SizedBox(height: 8),
            Text('Version: 1.0.0'),
            SizedBox(height: 8),
            Text('Build: 1'),
            SizedBox(height: 8),
            Text('Flutter Version: 3.35.5'),
          ],
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

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Need help? Contact us:'),
            SizedBox(height: 8),
            Text('📧 Email: support@carmaintenance.com'),
            SizedBox(height: 8),
            Text('📞 Phone: +1 (555) 123-4567'),
            SizedBox(height: 8),
            Text('💬 Live Chat: Available 24/7'),
          ],
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

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'Your privacy is important to us. This app collects minimal data necessary for providing our services. We do not share your personal information with third parties without your consent.\n\n'
            'Data collected:\n'
            '• Account information (name, email)\n'
            '• Booking history\n'
            '• App preferences\n\n'
            'For more information, visit our website.',
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