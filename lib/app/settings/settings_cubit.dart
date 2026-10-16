import 'package:railway_hrms/app/settings/settings_states.dart';
import 'package:railway_hrms/core/bloc/safe_bloc.dart';
import 'package:railway_hrms/core/security/biometric_authenticator.dart';
import 'package:railway_hrms/core/storage/storage_service.dart';

/// Biometric sign-in's setting: whether it is on, and whether this phone
/// can do it at all.
class SettingsCubit extends SafeCubit<SettingsState> {
  SettingsCubit(this._biometrics) : super(SettingsInitial());

  final BiometricAuthenticator _biometrics;

  Future<void> loadSettings() async {
    emit(SettingsLoading());
    try {
      emit(
        SettingsLoaded(
          isBiometricEnabled: await StorageService.isBiometricEnabled(),
          canCheckBiometrics: await _biometrics.enrolled() != null,
        ),
      );
    } catch (_) {
      // Without a reading, the switch stays off and can't be used.
      emit(
        SettingsLoaded(isBiometricEnabled: false, canCheckBiometrics: false),
      );
    }
  }

  /// Turns biometric sign-in off, or on once the employee confirms it's
  /// them with [reason] shown. False when turning it on wasn't confirmed.
  Future<bool> toggleBiometrics(bool enabled, {required String reason}) async {
    final state = this.state;
    if (state is! SettingsLoaded) return false;
    if (!enabled) {
      await StorageService.setBiometricEnabled(false);
      emit(state.copyWith(isBiometricEnabled: false));
      return true;
    }
    final confirmed = await _biometrics.authenticate(reason: reason);
    if (confirmed) {
      await StorageService.setBiometricEnabled(true);
      emit(state.copyWith(isBiometricEnabled: true));
    }
    return confirmed;
  }
}
