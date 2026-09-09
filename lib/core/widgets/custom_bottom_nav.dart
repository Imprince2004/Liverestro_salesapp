import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/colors.dart';
import '../extensions/context_ext.dart';

/// Animated Glassmorphic Custom Bottom Navigation Bar.
class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool isAdmin;
  final bool isManager;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.isAdmin = false,
    this.isManager = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    final items = isAdmin
        ? const [
            _NavItem(icon: Icons.dashboard_rounded, label: 'Admin'),
            _NavItem(icon: Icons.storefront_rounded, label: 'Leads'),
            _NavItem(icon: Icons.radar_rounded, label: 'Radar'),
            _NavItem(icon: Icons.admin_panel_settings_rounded, label: 'Settings'),
          ]
        : (isManager
            ? const [
                _NavItem(icon: Icons.hub_rounded, label: 'Manager'),
                _NavItem(icon: Icons.storefront_rounded, label: 'Leads'),
                _NavItem(icon: Icons.radar_rounded, label: 'Radar'),
                _NavItem(icon: Icons.person_rounded, label: 'Profile'),
              ]
            : const [
                _NavItem(icon: Icons.home_rounded, label: 'Home'),
                _NavItem(icon: Icons.person_search_rounded, label: 'Leads'),
                _NavItem(icon: Icons.location_on_rounded, label: 'Visits'),
                _NavItem(icon: Icons.grid_view_rounded, label: 'More'),
              ]);

    return SafeArea(
      child: Container(
        margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 10.h),
        height: 64.h,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF191629) : Colors.white,
          borderRadius: BorderRadius.circular(22.r),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withValues(alpha: 0.45) : const Color(0xFF714B67).withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: isDark ? const Color(0xFF2E2946) : const Color(0xFFEDE8EC),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (index) {
            final selected = currentIndex == index;
            final item = items[index];

            return InkWell(
              onTap: () => onTap(index),
              borderRadius: BorderRadius.circular(16.r),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(horizontal: selected ? 16.w : 12.w, vertical: 8.h),
                decoration: selected
                    ? BoxDecoration(
                        color: isDark ? const Color(0xFF714B67).withValues(alpha: 0.3) : const Color(0xFF714B67),
                        borderRadius: BorderRadius.circular(16.r),
                      )
                    : null,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.icon,
                      size: 20.sp,
                      color: selected
                          ? (isDark ? const Color(0xFFE2C4DC) : Colors.white)
                          : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                    ),
                    if (selected) ...[
                      SizedBox(width: 6.w),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 11.5.sp,
                          fontWeight: FontWeight.bold,
                          color: isDark ? const Color(0xFFE2C4DC) : Colors.white,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;

  const _NavItem({required this.icon, required this.label});
}
