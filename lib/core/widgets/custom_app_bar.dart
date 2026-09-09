import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../constants/colors.dart';
import '../constants/icons.dart';
import '../extensions/context_ext.dart';

/// Production CustomAppBar supporting back navigation, title, and trailing actions.
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;

  const CustomAppBar({
    super.key,
    required this.title,
    this.showBackButton = true,
    this.actions,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return AppBar(
      title: Text(
        title,
        style: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.bold,
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        ),
      ),
      leading: showBackButton && context.canPop()
          ? IconButton(
              icon: const Icon(AppIcons.back, size: 20),
              onPressed: () => context.pop(),
            )
          : null,
      actions: actions,
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(60.h + (bottom?.preferredSize.height ?? 0.0));
}
