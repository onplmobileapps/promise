abstract class SettingsState {}

class SettingsInitial extends SettingsState {}

class SettingsLoading extends SettingsState {}

class SettingsLoaded extends SettingsState {
  SettingsLoaded({
    required this.isBiometricEnabled,
    required this.canCheckBiometrics,
  });

  final bool isBiometricEnabled;
  final bool canCheckBiometrics;

  SettingsLoaded copyWith({
    bool? isBiometricEnabled,
    bool? canCheckBiometrics,
  }) => SettingsLoaded(
    isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
    canCheckBiometrics: canCheckBiometrics ?? this.canCheckBiometrics,
  );
}
