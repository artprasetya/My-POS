import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_pos/core/constants/app_colors.dart';
import 'package:my_pos/core/constants/app_sizes.dart';
import 'package:my_pos/features/auth/presentation/bloc/auth_bloc.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameController = TextEditingController();
  final _pinController = TextEditingController();
  final bool _isEditing = false;

  @override
  void dispose() {
    _nameController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<AuthBloc>().add(AuthLogoutRequested());
              Navigator.pop(context);
            },
            child:
                const Text('Logout', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is! AuthAuthenticated) return const SizedBox.shrink();

        final user = state.user;
        if (!_isEditing) {
          _nameController.text = user.fullName;
          _pinController.text = user.pin ?? '';
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Settings'),
            actions: [
              IconButton(
                onPressed: _showLogoutDialog,
                icon: const Icon(Icons.logout_rounded, color: AppColors.error),
              ),
              const SizedBox(width: AppSizes.sm),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(AppSizes.lg),
            children: [
              // Profile Header
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.primarySurface,
                      child: Text(
                        user.fullName.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.md),
                    Text(
                      user.fullName,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    Text(
                      user.email,
                      style: TextStyle(color: AppColors.mediumGray),
                    ),
                    const SizedBox(height: AppSizes.md),
                    Chip(
                      label: Text(user.role.toUpperCase()),
                      backgroundColor: AppColors.primarySurface,
                      labelStyle: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.huge),

              // Settings Sections
              _buildSectionTitle('Profile Information'),
              _buildSettingItem(
                icon: Icons.person_outline_rounded,
                title: 'Full Name',
                subtitle: user.fullName,
                onTap: () => _showEditProfileDialog(user.fullName),
              ),
              _buildSettingItem(
                icon: Icons.dialpad_rounded,
                title: 'Cashier PIN',
                subtitle: user.pin == null ? 'Not set' : '****',
                onTap: _showEditPinDialog,
              ),

              const SizedBox(height: AppSizes.xl),
              _buildSectionTitle('Store Settings (Coming in Phase 10)'),
              _buildSettingItem(
                icon: Icons.store_rounded,
                title: 'Store Info',
                subtitle: 'Name, Address, Tax settings',
                onTap: null,
              ),
              _buildSettingItem(
                icon: Icons.print_rounded,
                title: 'Printer Setup',
                subtitle: 'Bluetooth or IP Printer',
                onTap: null,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
          letterSpacing: 1.2,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        side: BorderSide(color: AppColors.lightGray.withValues(alpha: 0.5)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.extraLightGray,
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 13)),
        trailing:
            onTap != null ? const Icon(Icons.chevron_right_rounded) : null,
        onTap: onTap,
      ),
    );
  }

  void _showEditProfileDialog(String currentName) {
    _nameController.text = currentName;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: TextField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'Full Name'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              context.read<AuthBloc>().add(
                    AuthUpdateProfileRequested(
                        fullName: _nameController.text.trim()),
                  );
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditPinDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set/Change PIN'),
        content: TextField(
          controller: _pinController,
          decoration: const InputDecoration(labelText: '4-Digit PIN'),
          keyboardType: TextInputType.number,
          maxLength: 4,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              context.read<AuthBloc>().add(
                    AuthUpdateProfileRequested(pin: _pinController.text.trim()),
                  );
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
