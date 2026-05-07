import 'package:flutter/material.dart';
import 'package:my_pos/core/constants/app_colors.dart';
import 'package:my_pos/core/constants/app_sizes.dart';

/// Search bar widget used across the app
class PosSearchBar extends StatelessWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFilterTap;
  final TextEditingController? controller;
  final bool showFilter;

  const PosSearchBar({
    super.key,
    this.hintText = 'Search...',
    this.onChanged,
    this.onFilterTap,
    this.controller,
    this.showFilter = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.extraLightGray,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: AppSizes.md),
          Icon(
            Icons.search_rounded,
            color: isDark ? AppColors.darkTextSecondary : AppColors.mediumGray,
            size: AppSizes.iconLg,
          ),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: Theme.of(context).textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: hintText,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
                filled: false,
              ),
            ),
          ),
          if (showFilter) ...[
            Container(
              width: 1,
              height: 24,
              color: isDark ? AppColors.darkBorder : AppColors.lightGray,
            ),
            IconButton(
              onPressed: onFilterTap,
              icon: Icon(
                Icons.tune_rounded,
                color: isDark ? AppColors.darkTextSecondary : AppColors.gray,
                size: AppSizes.iconMd,
              ),
            ),
          ] else
            const SizedBox(width: AppSizes.md),
        ],
      ),
    );
  }
}
