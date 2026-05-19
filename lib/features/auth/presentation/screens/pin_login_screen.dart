import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:my_pos/core/constants/app_colors.dart';
import 'package:my_pos/core/constants/app_sizes.dart';
import 'package:my_pos/features/auth/presentation/bloc/auth_bloc.dart';

class PinLoginScreen extends StatefulWidget {
  const PinLoginScreen({super.key});

  @override
  State<PinLoginScreen> createState() => _PinLoginScreenState();
}

class _PinLoginScreenState extends State<PinLoginScreen> {
  String _pin = '';
  final int _pinLength = 4;
  bool _isLoading = false;

  void _onKeyPress(String value) {
    if (_isLoading) return;
    if (_pin.length < _pinLength) {
      setState(() {
        _pin += value;
      });

      if (_pin.length == _pinLength) {
        _submit();
      }
    }
  }

  void _onBackspace() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
      });
    }
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    
    // Use the AuthBloc to login with PIN
    // Note: We need to add AuthPinLoginRequested to AuthBloc
    context.read<AuthBloc>().add(AuthPinLoginRequested(pin: _pin));
    
    // The AuthBloc listener in LoginScreen or a parent will handle navigation
    // but we can also add a listener here if needed.
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            context.go('/dashboard');
          } else if (state is AuthError) {
            setState(() {
              _isLoading = false;
              _pin = ''; // Clear PIN on error
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: AppSizes.xxl),
              // Header
              const Icon(
                Icons.lock_person_rounded,
                size: 64,
                color: AppColors.primary,
              ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
              const SizedBox(height: AppSizes.xl),
              Text(
                'Enter Cashier PIN',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppSizes.sm),
              Text(
                'Enter your 4-digit access code',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.gray,
                    ),
              ),
              const SizedBox(height: AppSizes.huge),

              // PIN Indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pinLength, (index) {
                  final isActive = index < _pin.length;
                  return AnimatedContainer(
                    duration: 200.ms,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive
                          ? AppColors.primary
                          : (isDark ? AppColors.darkCard : AppColors.lightGray),
                      border: Border.all(
                        color: isActive
                            ? AppColors.primary
                            : AppColors.mediumGray.withValues(alpha: 0.3),
                        width: 2,
                      ),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 10,
                                spreadRadius: 2,
                              )
                            ]
                          : [],
                    ),
                  );
                }),
              ),
              const Spacer(),

              // Numpad
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                _buildNumpad(),
              
              const SizedBox(height: AppSizes.huge),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumpad() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.huge),
      child: Column(
        children: [
          _buildNumpadRow(['1', '2', '3']),
          const SizedBox(height: AppSizes.xl),
          _buildNumpadRow(['4', '5', '6']),
          const SizedBox(height: AppSizes.xl),
          _buildNumpadRow(['7', '8', '9']),
          const SizedBox(height: AppSizes.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SizedBox(width: 75), // Placeholder for alignment
              _buildNumpadButton('0'),
              SizedBox(
                width: 75,
                height: 75,
                child: IconButton(
                  onPressed: _isLoading ? null : _onBackspace,
                  icon: const Icon(Icons.backspace_outlined),
                  color: AppColors.gray,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }

  Widget _buildNumpadRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((key) => _buildNumpadButton(key)).toList(),
    );
  }

  Widget _buildNumpadButton(String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onKeyPress(label),
        borderRadius: BorderRadius.circular(AppSizes.radiusRound),
        child: Container(
          width: 75,
          height: 75,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isDark ? AppColors.darkDivider : AppColors.lightGray,
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
