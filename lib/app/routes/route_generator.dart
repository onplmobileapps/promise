import 'package:flutter/material.dart';
import 'package:railway_hrms/app/routes/app_route_registry.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final builder = AppRouteRegistry.builderFor(settings.name);
    if (builder != null) {
      return MaterialPageRoute(builder: builder, settings: settings);
    }
    return _errorRoute();
  }

  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(
      builder: (context) => Scaffold(
        body: Center(
          child: Text(
            context.l10n.routeNotFound,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
      ),
    );
  }
}
