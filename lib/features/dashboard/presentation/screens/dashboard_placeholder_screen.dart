import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../app/theme_config.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/custom_bottom_nav.dart';
import '../../../../core/widgets/custom_cards.dart';
import '../../../../core/widgets/search_field.dart';
import '../../../../l10n/l10n.dart';

/// Production Dashboard Route Placeholder Screen demonstrating foundation integration.
class DashboardPlaceholderScreen extends ConsumerStatefulWidget {
  const DashboardPlaceholderScreen({super.key});

  @override
  ConsumerState<DashboardPlaceholderScreen> createState() => _DashboardPlaceholderScreenState();
}

class _DashboardPlaceholderScreenState extends ConsumerState<DashboardPlaceholderScreen> {
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    final currentTheme = ref.watch(themeModeProvider);
    final currentLocale = ref.watch(localeProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'LiveRestro Sales',
        showBackButton: false,
        actions: [
          IconButton(
            icon: Icon(currentTheme == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => ref.read(themeModeProvider.notifier).toggleTheme(),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.language_rounded),
            onSelected: (code) => ref.read(localeProvider.notifier).setLocale(Locale(code)),
            itemBuilder: (context) => L10n.all
                .map((loc) => PopupMenuItem(
                      value: loc.languageCode,
                      child: Text(L10n.getLanguageName(loc.languageCode)),
                    ))
                .toList(),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SearchField(),
              SizedBox(height: 16.h),
              AppCard(
                backgroundColor: AppColors.primary,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28.r,
                      backgroundColor: Colors.white24,
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'LiveRestro Sales Executive',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'Active Locale: ${currentLocale.languageCode.toUpperCase()}',
                            style: TextStyle(fontSize: 12.sp, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                'Foundation Modules',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(
                    child: AppCard(
                      isOutlined: true,
                      child: Column(
                        children: [
                          Icon(Icons.layers_rounded, color: AppColors.primary, size: 28.sp),
                          SizedBox(height: 8.h),
                          Text(
                            'MVVM',
                            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
                          ),
                          Text('Modular', style: TextStyle(fontSize: 11.sp, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: AppCard(
                      isOutlined: true,
                      child: Column(
                        children: [
                          Icon(Icons.palette_rounded, color: AppColors.accent, size: 28.sp),
                          SizedBox(height: 8.h),
                          Text(
                            'Design System',
                            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
                          ),
                          Text('Material 3', style: TextStyle(fontSize: 11.sp, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _navIndex,
        onTap: (index) => setState(() => _navIndex = index),
      ),
    );
  }
}
