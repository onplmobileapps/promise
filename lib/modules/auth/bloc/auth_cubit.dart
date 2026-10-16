import 'package:dio/dio.dart';
import 'package:railway_hrms/core/bloc/safe_bloc.dart';
import 'package:railway_hrms/core/location/current_location_service.dart';
import 'package:railway_hrms/core/models/login_response.dart';
import 'package:railway_hrms/core/storage/storage_service.dart';
import 'package:railway_hrms/modules/auth/bloc/auth_states.dart';
import 'package:railway_hrms/modules/auth/data/auth_repository.dart';

class AuthCubit extends SafeCubit<AuthState> {
  final AuthRepository _authRepository;
  AuthCubit(this._authRepository) : super(AuthInitial());
  Future<void> loadUserData() async {
    final user = await StorageService.getUser();
    if (user != null) {
      emit(AuthSuccess(user));
    }
  }

  Future<void> login(String empId, String password) async {
    final fcmToken = await StorageService.getFcmToken();
    emit(AuthLoading());
    try {
      final resposne = await _authRepository.login(
        empId,
        password,
        fcmToken ?? '',
      );

      await resposne.fold(
        (failure) async {
          emit(AuthError(failure.message));
        },
        (user) async {
          await StorageService.saveUserCredentials(
            empID: empId,
            password: password,
          );
          final loginResponse = LoginResponse.fromJson(user.data);
          await StorageService.saveUser(loginResponse);

          emit(AuthSuccess(loginResponse));
        },
      );
    } catch (e) {
      emit(AuthError("Login Failed: ${e.toString()}"));
    }
  }

  Future<void> markAttendance(
    String checkin,
    List<MultipartFile> images,
  ) async {
    emit(AuthLoading());
    try {
      final position = await CurrentLocationService.getCurrentLocation();
      if (position != null) {
        final resposne = await _authRepository.markAttendance(
          checkin,
          position.latitude,
          position.longitude,
          images,
        );

        resposne.fold((failure) => emit(AuthError(failure.message)), (message) {
          emit(AuthSuccess(LoginResponse.fromJson(message.data)));
        });
      }
    } catch (e) {
      emit(AuthError("Login Failed: ${e.toString()}"));
    }
  }
}
//
