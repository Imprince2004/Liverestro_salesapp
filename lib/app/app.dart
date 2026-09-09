import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../l10n/app_localizations.dart';
import '../core/theme/app_theme.dart';
import '../l10n/l10n.dart';
import '../routes/app_router.dart';
import '../core/widgets/in_app_notification_banner.dart';
import 'theme_config.dart';

/// LiveRestro Sales Root Application Widget.
class LiveRestroSalesApp extends ConsumerWidget {
  const LiveRestroSalesApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    final fontSize = ref.watch(fontSizeProvider);
    double scale = 1.0;
    if (fontSize == 'Small') scale = 0.85;
    if (fontSize == 'Large') scale = 1.15;
    if (fontSize == 'Extra Large') scale = 1.3;

    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          title: 'LiveRestro Sales',
          debugShowCheckedModeBanner: false,
          themeMode: themeMode,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          locale: locale,
          supportedLocales: L10n.all,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          routerConfig: router,
          builder: (context, routerChild) {
            return InAppNotificationBannerListener(
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(scale),
                ),
                child: routerChild!,
              ),
            );
          },
        );
      },
    );
  }
}
