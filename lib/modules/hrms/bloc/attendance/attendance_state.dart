import 'package:railway_hrms/modules/hrms/data/models/attendance_record.dart';

abstract class AttendanceState {}

class AttendanceInitial extends AttendanceState {}

class AttendanceLoading extends AttendanceState {}

class AttendanceLoaded extends AttendanceState {
  final List<AttendanceRecord> records;
  AttendanceLoaded(this.records);
}

class AttendanceError extends AttendanceState {
  final String message;
  AttendanceError(this.message);
}
