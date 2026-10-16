import 'package:railway_hrms/core/models/login_response.dart';

abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {
  final LoginResponse message;
  AuthSuccess(this.message);
}

class AuthError extends AuthState {
  final String error;
  AuthError(this.error);
}
