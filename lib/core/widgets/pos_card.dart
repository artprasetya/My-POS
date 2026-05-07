import 'package:flutter/material.dart';
import 'package:my_pos/core/constants/app_colors.dart';
import 'package:my_pos/core/constants/app_sizes.dart';

/// A reusable card widget with consistent styling
class PosCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;
  final Border? border;
  final List<BoxShadow>? boxShadow;

  const PosCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
    this.border,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: padding ?? const EdgeInsets.all(AppSizes.lg),
        decoration: BoxDecoration(
          color: color ?? (isDark ? AppColors.darkCard : AppColors.white),
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: border ??
              Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightGray,
              ),
          boxShadow: boxShadow,
        ),
        child: child,
      ),
    );
  }
}
