import 'package:go_router/go_router.dart';

import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/hours/presentation/hour_registration_screen.dart';
import '../../features/payroll/presentation/payroll_history_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../constants/app_routes.dart';

final appRouter = GoRouter(
  initialLocation: AppRoutes.dashboard,
  routes: [
    GoRoute(
      path: AppRoutes.dashboard,
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: AppRoutes.registerHours,
      builder: (context, state) => const HourRegistrationScreen(),
    ),
    GoRoute(
      path: AppRoutes.payrollHistory,
      builder: (context, state) => const PayrollHistoryScreen(),
    ),
    GoRoute(
      path: AppRoutes.settings,
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
