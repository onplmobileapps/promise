import 'package:railway_hrms/modules/hrms/data/models/recent_employee.dart';

abstract class RecentEmpState {}

class RecentEmpInitial extends RecentEmpState {}

class RecentEmpLoading extends RecentEmpState {}

class RecentEmpLoaded extends RecentEmpState {
  final RecentEmployee recentEmployees;
  RecentEmpLoaded(this.recentEmployees);
}

class RecentEmpError extends RecentEmpState {
  final String message;
  RecentEmpError(this.message);
}
