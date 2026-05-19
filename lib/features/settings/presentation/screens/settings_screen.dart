import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_pos/core/constants/app_colors.dart';
import 'package:my_pos/core/constants/app_sizes.dart';
import 'package:my_pos/core/bloc/locale_bloc.dart';
import 'package:my_pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:my_pos/l10n/app_localizations.dart';

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

  void _showLogoutDialog(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.logout),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              context.read<AuthBloc>().add(AuthLogoutRequested());
              Navigator.pop(context);
            },
            child: Text(l10n.logout,
                style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.language),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('English'),
              leading: const Text('🇺🇸'),
              onTap: () {
                context
                    .read<LocaleBloc>()
                    .add(LocaleChanged(const Locale('en')));
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Bahasa Indonesia'),
              leading: const Text('🇮🇩'),
              onTap: () {
                context
                    .read<LocaleBloc>()
                    .add(LocaleChanged(const Locale('id')));
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
            title: Text(l10n.settings),
            actions: [
              IconButton(
                onPressed: () => _showLogoutDialog(l10n),
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
                        user.fullName.isNotEmpty
                            ? user.fullName.substring(0, 1).toUpperCase()
                            : '?',
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
                      style: const TextStyle(color: AppColors.mediumGray),
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

              // Profile Section
              _buildSectionTitle('Profile Information'),
              _buildSettingItem(
                icon: Icons.person_outline_rounded,
                title: 'Full Name',
                subtitle: user.fullName,
                onTap: () => _showEditProfileDialog(user.fullName, l10n),
              ),
              /*
              _buildSettingItem(
                icon: Icons.dialpad_rounded,
                title: 'Cashier PIN',
                subtitle: user.pin == null ? 'Not set' : '****',
                onTap: () => _showEditPinDialog(l10n),
              ),
              */

              const SizedBox(height: AppSizes.xl),
              // App Settings Section
              _buildSectionTitle('App Preferences'),
              _buildSettingItem(
                icon: Icons.language_rounded,
                title: l10n.language,
                subtitle: Localizations.localeOf(context).languageCode == 'en'
                    ? 'English'
                    : 'Bahasa Indonesia',
                onTap: () => _showLanguageDialog(l10n),
              ),
              _buildSettingItem(
                icon: Icons.dark_mode_outlined,
                title: l10n.darkMode,
                subtitle: 'Off',
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        side: BorderSide(
            color: isDark
                ? AppColors.darkBorder
                : AppColors.lightGray.withValues(alpha: 0.5)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBorder : AppColors.extraLightGray,
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

  void _showEditProfileDialog(String currentName, AppLocalizations l10n) {
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
              child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () {
              context.read<AuthBloc>().add(
                    AuthUpdateProfileRequested(
                        fullName: _nameController.text.trim()),
                  );
              Navigator.pop(context);
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  void _showEditPinDialog(AppLocalizations l10n) {
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
              child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () {
              context.read<AuthBloc>().add(
                    AuthUpdateProfileRequested(pin: _pinController.text.trim()),
                  );
              Navigator.pop(context);
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }
}
