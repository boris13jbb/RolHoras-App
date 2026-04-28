import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_routes.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    required this.title,
    required this.selectedIndex,
    required this.body,
    this.floatingActionButton,
    super.key,
  });

  final String title;
  final int selectedIndex;
  final Widget body;
  final Widget? floatingActionButton;

  static const _destinations = [
    _AppDestination('Dashboard', Icons.dashboard_outlined, AppRoutes.dashboard),
    _AppDestination(
      'Registrar',
      Icons.add_circle_outline,
      AppRoutes.registerHours,
    ),
    _AppDestination(
      'Historial',
      Icons.picture_as_pdf_outlined,
      AppRoutes.payrollHistory,
    ),
    _AppDestination('Ajustes', Icons.settings_outlined, AppRoutes.settings),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useRail = constraints.maxWidth >= 720;

        return Scaffold(
          appBar: AppBar(title: Text(title)),
          floatingActionButton: floatingActionButton,
          bottomNavigationBar: useRail
              ? null
              : NavigationBar(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (index) => _goTo(context, index),
                  destinations: [
                    for (final destination in _destinations)
                      NavigationDestination(
                        icon: Icon(destination.icon),
                        label: destination.label,
                      ),
                  ],
                ),
          body: SafeArea(
            child: Row(
              children: [
                if (useRail)
                  NavigationRail(
                    selectedIndex: selectedIndex,
                    onDestinationSelected: (index) => _goTo(context, index),
                    labelType: NavigationRailLabelType.all,
                    destinations: [
                      for (final destination in _destinations)
                        NavigationRailDestination(
                          icon: Icon(destination.icon),
                          label: Text(destination.label),
                        ),
                    ],
                  ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: body,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _goTo(BuildContext context, int index) {
    final route = _destinations[index].route;
    if (GoRouterState.of(context).uri.path != route) {
      context.go(route);
    }
  }
}

class _AppDestination {
  const _AppDestination(this.label, this.icon, this.route);

  final String label;
  final IconData icon;
  final String route;
}
