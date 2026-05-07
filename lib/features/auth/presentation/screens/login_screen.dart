import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:my_pos/core/constants/app_colors.dart';
import 'package:my_pos/core/constants/app_sizes.dart';
import 'package:my_pos/features/auth/presentation/bloc/auth_bloc.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isRegister = false;
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    if (_isRegister) {
      context.read<AuthBloc>().add(AuthRegisterRequested(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            fullName: _nameController.text.trim(),
          ));
    } else {
      context.read<AuthBloc>().add(AuthLoginRequested(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            context.go('/dashboard');
          } else if (state is AuthError) {
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
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.xxl),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo & Title
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.point_of_sale_rounded,
                        color: AppColors.white,
                        size: 36,
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 600.ms)
                        .scale(begin: const Offset(0.5, 0.5)),
                    const SizedBox(height: AppSizes.xxl),
                    Text(
                      'My POS',
                      style: Theme.of(context)
                          .textTheme
                          .displayMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    )
                        .animate()
                        .fadeIn(delay: 200.ms, duration: 600.ms)
                        .slideY(begin: 0.3),
                    const SizedBox(height: AppSizes.sm),
                    Text(
                      _isRegister
                          ? 'Create your account'
                          : 'Sign in to your account',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.gray,
                          ),
                    )
                        .animate()
                        .fadeIn(delay: 400.ms, duration: 600.ms),
                    const SizedBox(height: AppSizes.huge),

                    // Form
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Name field (register only)
                          if (_isRegister) ...[
                            TextFormField(
                              controller: _nameController,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                hintText: 'Full Name',
                                prefixIcon: const Icon(
                                  Icons.person_outline_rounded,
                                  color: AppColors.mediumGray,
                                ),
                                filled: true,
                                fillColor: isDark
                                    ? AppColors.darkCard
                                    : AppColors.extraLightGray,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your name';
                                }
                                return null;
                              },
                            )
                                .animate()
                                .fadeIn(delay: 500.ms, duration: 400.ms)
                                .slideX(begin: -0.1),
                            const SizedBox(height: AppSizes.lg),
                          ],

                          // Email
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              hintText: 'Email address',
                              prefixIcon: const Icon(
                                Icons.email_outlined,
                                color: AppColors.mediumGray,
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? AppColors.darkCard
                                  : AppColors.extraLightGray,
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
                          )
                              .animate()
                              .fadeIn(delay: 500.ms, duration: 400.ms)
                              .slideX(begin: -0.1),
                          const SizedBox(height: AppSizes.lg),

                          // Password
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            decoration: InputDecoration(
                              hintText: 'Password',
                              prefixIcon: const Icon(
                                Icons.lock_outline_rounded,
                                color: AppColors.mediumGray,
                              ),
                              suffixIcon: IconButton(
                                onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: AppColors.mediumGray,
                                ),
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? AppColors.darkCard
                                  : AppColors.extraLightGray,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          )
                              .animate()
                              .fadeIn(delay: 600.ms, duration: 400.ms)
                              .slideX(begin: -0.1),
                          const SizedBox(height: AppSizes.xxl),

                          // Submit Button
                          BlocBuilder<AuthBloc, AuthState>(
                            builder: (context, state) {
                              final isLoading = state is AuthLoading;
                              return SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: isLoading ? null : _submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          AppSizes.radiusMd),
                                    ),
                                  ),
                                  child: isLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    AppColors.white),
                                          ),
                                        )
                                      : Text(
                                          _isRegister
                                              ? 'Create Account'
                                              : 'Sign In',
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.white,
                                          ),
                                        ),
                                ),
                              );
                            },
                          )
                              .animate()
                              .fadeIn(delay: 700.ms, duration: 400.ms)
                              .slideY(begin: 0.2),
                          const SizedBox(height: AppSizes.xl),

                          // Toggle login/register
                          TextButton(
                            onPressed: () =>
                                setState(() => _isRegister = !_isRegister),
                            child: Text.rich(
                              TextSpan(
                                text: _isRegister
                                    ? 'Already have an account? '
                                    : 'Don\'t have an account? ',
                                style: TextStyle(
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.gray,
                                ),
                                children: [
                                  TextSpan(
                                    text:
                                        _isRegister ? 'Sign In' : 'Register',
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                              .animate()
                              .fadeIn(delay: 800.ms, duration: 400.ms),

                          const SizedBox(height: AppSizes.xl),
                          // Divider
                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: isDark
                                      ? AppColors.darkDivider
                                      : AppColors.lightGray,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: AppSizes.md),
                                child: Text(
                                  'OR',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.mediumGray,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: isDark
                                      ? AppColors.darkDivider
                                      : AppColors.lightGray,
                                ),
                              ),
                            ],
                          ).animate().fadeIn(delay: 900.ms),
                          const SizedBox(height: AppSizes.xl),

                          // PIN Login Button
                          OutlinedButton.icon(
                            onPressed: () => context.push('/login/pin'),
                            icon: const Icon(Icons.dialpad_rounded),
                            label: const Text('Sign in with PIN'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 52),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppSizes.radiusMd),
                              ),
                            ),
                          ).animate().fadeIn(delay: 1000.ms),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
