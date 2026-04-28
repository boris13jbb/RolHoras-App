import 'package:flutter/material.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class RolPagosApp extends StatelessWidget {
  const RolPagosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'RolPagosApp',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      routerConfig: appRouter,
    );
  }
}
