import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../shared/domain/entities/user_entity.dart';
import '../core/utils/logging/navigation_logger.dart';
import '../features/splash/presentation/screens/splash_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/otp_verification_screen.dart';
import '../features/auth/presentation/screens/two_factor_auth_screen.dart';
import '../features/auth/presentation/screens/create_pin_screen.dart';
import '../features/auth/presentation/screens/pin_login_screen.dart';
import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../features/restaurants/presentation/screens/restaurant_search_screen.dart';
import '../features/restaurants/presentation/screens/nearby_food_places_screen.dart';
import '../features/leads/presentation/screens/lead_list_screen.dart';
import '../features/leads/presentation/screens/create_lead_screen.dart';
import '../features/visits/presentation/screens/visit_list_screen.dart';
import '../features/visits/presentation/screens/start_visit_screen.dart';
import '../features/orders/presentation/screens/order_list_screen.dart';
import '../features/orders/presentation/screens/create_order_screen.dart';
import '../features/orders/presentation/screens/pos_software_orders_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/profile/presentation/screens/my_profile_detail_screen.dart';
import '../features/profile/presentation/screens/edit_profile_screen.dart';
import '../features/profile/presentation/screens/attendance_screen.dart';
import '../features/profile/presentation/screens/attendance_history_screen.dart';
import '../features/profile/presentation/screens/documents_hub_screen.dart';
import '../features/profile/presentation/screens/product_catalog_screen.dart';
import '../features/profile/presentation/screens/leaderboard_screen.dart';
import '../features/profile/presentation/screens/notification_hub_screen.dart';
import '../features/profile/presentation/screens/settings_hub_screen.dart';
import '../features/profile/presentation/screens/help_support_screen.dart';
import '../features/profile/presentation/screens/expenses_screen.dart';
import '../features/leads/presentation/screens/follow_ups_screen.dart';
import '../features/tracking/presentation/screens/gps_tracking_screen.dart';
import '../features/calendar/presentation/screens/calendar_screen.dart';
import '../features/tasks/presentation/screens/tasks_screen.dart';
import '../features/reports/presentation/screens/reports_screen.dart';
import '../features/ai_assistant/presentation/screens/ai_assistant_screen.dart';
import '../features/manager/presentation/screens/super_admin_hub_screen.dart';
import '../features/manager/presentation/screens/manager_hub_screen.dart';
import 'route_names.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: RouteNames.splash,
    debugLogDiagnostics: true,
    observers: [NavigationLogger()],
    routes: [
      GoRoute(
        path: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteNames.otp,
        builder: (context, state) => const OtpVerificationScreen(),
      ),
      GoRoute(
        path: RouteNames.twoFactorAuth,
        builder: (context, state) => const TwoFactorAuthScreen(),
      ),
      GoRoute(
        path: RouteNames.createPin,
        builder: (context, state) => const CreatePinScreen(),
      ),
      GoRoute(
        path: RouteNames.pinLogin,
        builder: (context, state) => const PinLoginScreen(),
      ),
      GoRoute(
        path: RouteNames.dashboard,
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: RouteNames.restaurantSearch,
        builder: (context, state) => const RestaurantSearchScreen(),
      ),
      GoRoute(
        path: RouteNames.nearbyFoodPlaces,
        builder: (context, state) => const NearbyFoodPlacesScreen(),
      ),
      GoRoute(
        path: RouteNames.leadList,
        builder: (context, state) => const LeadListScreen(),
      ),
      GoRoute(
        path: RouteNames.createLead,
        builder: (context, state) => const CreateLeadScreen(),
      ),
      GoRoute(
        path: RouteNames.visitManagement,
        builder: (context, state) => const VisitListScreen(),
      ),
      GoRoute(
        path: RouteNames.startVisit,
        builder: (context, state) => const StartVisitScreen(),
      ),
      GoRoute(
        path: RouteNames.orderList,
        builder: (context, state) => const OrderListScreen(),
      ),
      GoRoute(
        path: RouteNames.createOrder,
        builder: (context, state) => const CreateOrderScreen(),
      ),
      GoRoute(
        path: RouteNames.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: RouteNames.myProfileDetail,
        builder: (context, state) => const MyProfileDetailScreen(),
      ),
      GoRoute(
        path: RouteNames.editProfile,
        builder: (context, state) {
          if (state.extra is Map<String, dynamic>) {
            final extraMap = state.extra as Map<String, dynamic>;
            final user = extraMap['user'] as UserEntity;
            final triggerDob = extraMap['triggerDobPicker'] as bool? ?? false;
            return EditProfileScreen(user: user, triggerDobPicker: triggerDob);
          }
          final user = state.extra as UserEntity;
          return EditProfileScreen(user: user);
        },
      ),
      GoRoute(
        path: RouteNames.attendance,
        builder: (context, state) => const AttendanceScreen(),
      ),
      GoRoute(
        path: RouteNames.attendanceHistory,
        builder: (context, state) => const AttendanceHistoryScreen(),
      ),
      GoRoute(
        path: RouteNames.documentsHub,
        builder: (context, state) => const DocumentsHubScreen(),
      ),
      GoRoute(
        path: RouteNames.productCatalog,
        builder: (context, state) => const ProductCatalogScreen(),
      ),
      GoRoute(
        path: RouteNames.leaderboard,
        builder: (context, state) => const LeaderboardScreen(),
      ),
      GoRoute(
        path: RouteNames.notificationHub,
        builder: (context, state) => const NotificationHubScreen(),
      ),
      GoRoute(
        path: RouteNames.settingsHub,
        builder: (context, state) => const SettingsHubScreen(),
      ),
      GoRoute(
        path: RouteNames.helpSupport,
        builder: (context, state) => const HelpSupportScreen(),
      ),
      GoRoute(
        path: RouteNames.expenses,
        builder: (context, state) => const ExpensesScreen(),
      ),
      GoRoute(
        path: RouteNames.followUps,
        builder: (context, state) => const FollowUpsScreen(),
      ),
      GoRoute(
        path: RouteNames.gpsTracking,
        builder: (context, state) => const GpsTrackingScreen(),
      ),
      GoRoute(
        path: RouteNames.calendar,
        builder: (context, state) => const CalendarScreen(),
      ),
      GoRoute(
        path: RouteNames.tasks,
        builder: (context, state) => const TasksScreen(),
      ),
      GoRoute(
        path: RouteNames.reports,
        builder: (context, state) => const ReportsScreen(),
      ),
      GoRoute(
        path: RouteNames.aiAssistant,
        builder: (context, state) => const AiAssistantScreen(),
      ),
      GoRoute(
        path: RouteNames.superAdminHub,
        builder: (context, state) => const SuperAdminHubScreen(),
      ),
      GoRoute(
        path: RouteNames.managerHub,
        builder: (context, state) => const ManagerHubScreen(),
      ),
      GoRoute(
        path: RouteNames.posOrders,
        builder: (context, state) => const PosSoftwareOrdersScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri}'),
      ),
    ),
  );
});
