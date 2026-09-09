import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/colors.dart';
import '../constants/icons.dart';
import '../extensions/context_ext.dart';

/// Production SearchField with clear button and filter triggers.
class SearchField extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFilterTap;
  final VoidCallback? onClear;

  const SearchField({
    super.key,
    this.controller,
    this.hintText = 'Search restaurants, leads, orders...',
    this.onChanged,
    this.onFilterTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: TextStyle(
        fontSize: 14.sp,
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          fontSize: 14.sp,
          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
        ),
        prefixIcon: const Icon(AppIcons.search, color: AppColors.primary),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (controller != null && controller!.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: () {
                  controller?.clear();
                  if (onClear != null) onClear!();
                },
              ),
            if (onFilterTap != null)
              IconButton(
                icon: const Icon(AppIcons.filter, color: AppColors.accent),
                onPressed: onFilterTap,
              ),
          ],
        ),
      ),
    );
  }
}
