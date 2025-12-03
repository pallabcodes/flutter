import 'package:finwise/presentation/providers/auth_providers.dart';
import 'package:finwise/presentation/theme/app_theme.dart';
import 'package:finwise/presentation/widgets/auth_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _changePassword = false;
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    final currentUser = ref.read(currentUserProvider);
    _displayNameController.text = currentUser?.displayName ?? '';
    _photoUrl = currentUser?.photoUrl;
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: const Text('Save'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingMD),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: AppTheme.spacingLG),

                // Profile Picture
                _buildProfilePicture(),

                const SizedBox(height: AppTheme.spacingXXL),

                // Display Name
                AuthTextField(
                  controller: _displayNameController,
                  labelText: 'Display Name',
                  hintText: 'Enter your display name',
                  prefixIcon: Icons.person,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a display name';
                    }
                    if (value.length < 2) {
                      return 'Display name must be at least 2 characters';
                    }
                    if (value.length > 50) {
                      return 'Display name must be less than 50 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppTheme.spacingLG),

                // Email (Read-only)
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingMD),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.email, color: Colors.grey),
                      const SizedBox(width: AppTheme.spacingMD),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Email',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              currentUser?.email ?? 'No email',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                      if (currentUser?.emailVerified == false)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Not Verified',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: AppTheme.spacingMD),

                // Email Verification
                if (currentUser?.emailVerified == false)
                  Card(
                    color: Colors.orange.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.spacingMD),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.warning,
                            color: Colors.orange,
                            size: 32,
                          ),
                          const SizedBox(height: AppTheme.spacingSM),
                          const Text(
                            'Email Not Verified',
                            style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingSM),
                          const Text(
                            'Please verify your email to access all features.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.orange),
                          ),
                          const SizedBox(height: AppTheme.spacingMD),
                          ElevatedButton(
                            onPressed: _sendEmailVerification,
                            child: const Text('Send Verification Email'),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: AppTheme.spacingLG),

                // Password Change Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingMD),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Change Password',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Switch(
                              value: _changePassword,
                              onChanged: (value) {
                                setState(() {
                                  _changePassword = value;
                                  if (!value) {
                                    _currentPasswordController.clear();
                                    _newPasswordController.clear();
                                    _confirmPasswordController.clear();
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                        if (_changePassword) ...[
                          const SizedBox(height: AppTheme.spacingMD),
                          AuthTextField(
                            controller: _currentPasswordController,
                            labelText: 'Current Password',
                            hintText: 'Enter your current password',
                            prefixIcon: Icons.lock,
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your current password';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppTheme.spacingMD),
                          AuthTextField(
                            controller: _newPasswordController,
                            labelText: 'New Password',
                            hintText: 'Enter a new password',
                            prefixIcon: Icons.lock_outline,
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a new password';
                              }
                              if (value.length < 8) {
                                return 'Password must be at least 8 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppTheme.spacingMD),
                          AuthTextField(
                            controller: _confirmPasswordController,
                            labelText: 'Confirm New Password',
                            hintText: 'Re-enter your new password',
                            prefixIcon: Icons.lock_outline,
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please confirm your new password';
                              }
                              if (value != _newPasswordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppTheme.spacingXXL),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMD),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Save Changes'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePicture() {
    return Stack(
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: AppTheme.primaryColor,
          backgroundImage: _photoUrl != null ? NetworkImage(_photoUrl!) : null,
          child: _photoUrl == null
              ? Text(
                  _displayNameController.text.isNotEmpty
                      ? _displayNameController.text.substring(0, 1).toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 36,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: CircleAvatar(
            radius: 18,
            backgroundColor: AppTheme.primaryColor,
            child: IconButton(
              icon: const Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 16,
              ),
              onPressed: _changeProfilePicture,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Update display name
      if (_displayNameController.text != ref.read(currentUserProvider)?.displayName) {
        await ref.read(authNotifierProvider.notifier).updateProfile(
          displayName: _displayNameController.text.trim(),
        );
      }

      // Change password if requested
      if (_changePassword && _newPasswordController.text.isNotEmpty) {
        // TODO: Implement password change functionality
        // This would require re-authentication for security
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password change not yet implemented')),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendEmailVerification() async {
    try {
      await ref.read(authNotifierProvider.notifier).sendEmailVerification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification email sent')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send verification email: $e')),
        );
      }
    }
  }

  void _changeProfilePicture() {
    // TODO: Implement image picker for profile picture
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Profile Picture'),
        content: const Text('Profile picture upload coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
