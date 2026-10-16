import 'package:flutter/foundation.dart';
import 'package:railway_hrms/core/storage/storage_service.dart';

/// Who is signed in, as the screens greet and describe them.
@immutable
class SignedInUser {
  const SignedInUser({
    required this.name,
    required this.role,
    this.employeeId = '',
    this.sapId = '',
  });

  /// No one known yet, as while the stored user loads.
  static const nobody = SignedInUser(name: '', role: '');

  final String name;

  /// The designation, or the role when there is none.
  final String role;
  final String employeeId;
  final String sapId;

  String get firstName => name.trim().split(RegExp(r'\s+')).first;

  /// The signed-in user from storage, or [nobody].
  static Future<SignedInUser> load() async {
    try {
      final user = (await StorageService.getUser())?.user;
      String clean(Object? value) => value?.toString().trim() ?? '';
      final role = clean(user?.designation).isNotEmpty
          ? clean(user?.designation)
          : clean(user?.roleData?.name);
      return SignedInUser(
        name: clean(user?.fullName),
        role: role,
        employeeId: clean(user?.empid),
        sapId: clean(user?.sapid),
      );
    } catch (_) {
      return nobody;
    }
  }
}
