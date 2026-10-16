import 'package:flutter/widgets.dart';
import 'package:railway_hrms/core/navigation/app_routes.dart';
import 'package:railway_hrms/modules/auth/screens/forgot_password_view.dart';
import 'package:railway_hrms/modules/auth/screens/login_view.dart';

/// Sign-in screens, by route name.
final Map<String, WidgetBuilder> authRoutes = {
  AppRoutes.login: (_) => const LoginView(),
  AppRoutes.forgotPassword: (_) => const ForgotPasswordView(),
};
