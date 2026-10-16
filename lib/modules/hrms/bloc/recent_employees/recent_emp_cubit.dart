import 'package:railway_hrms/core/bloc/safe_bloc.dart';
import 'package:railway_hrms/modules/hrms/bloc/recent_employees/recent_emp_states.dart';
import 'package:railway_hrms/modules/hrms/data/employee_attendance_repository.dart';
import 'package:railway_hrms/modules/hrms/data/models/recent_employee.dart';

class RecentEmpCubit extends SafeCubit<RecentEmpState> {
  final EmployeeAttendanceRepository getAttendnaceRepository;
  RecentEmpCubit(this.getAttendnaceRepository) : super(RecentEmpInitial());

  Future<void> getRecentEmployee() async {
    emit(RecentEmpLoading());
    try {
      final response = await getAttendnaceRepository.getRecentEmployees();
      response.fold(
        (l) => emit(RecentEmpError(l.message)),
        (data) => emit(RecentEmpLoaded(RecentEmployee.fromJson(data.data))),
      );
    } catch (_) {
      emit(RecentEmpError("Couldn't load recent employees."));
    }
  }
}
