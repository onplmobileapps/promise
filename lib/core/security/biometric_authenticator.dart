import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

/// What a phone checks its owner by.
enum BiometricKind { face, fingerprint }

/// Face ID, Touch ID or a fingerprint, behind an interface so screens can be
/// tested without the platform plugin.
abstract interface class BiometricAuthenticator {
  /// The face or fingerprint set up on this phone, a face first; null when
  /// the phone can't check either, or none is set up. A screen lock alone,
  /// a PIN or a pattern, isn't one.
  Future<BiometricKind?> enrolled();

  /// Asks the user to authenticate, showing [reason]; false if they don't.
  Future<bool> authenticate({required String reason});
}

/// [BiometricAuthenticator] on the device's own biometrics.
class LocalBiometricAuthenticator implements BiometricAuthenticator {
  LocalBiometricAuthenticator([LocalAuthentication? auth])
    : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<BiometricKind?> enrolled() async {
    try {
      if (!await _auth.canCheckBiometrics) return null;
      final kinds = await _auth.getAvailableBiometrics();
      if (kinds.isEmpty) return null;
      // Android names only how strong its checks are; a fingerprint is the
      // usual one there.
      return kinds.contains(BiometricType.face)
          ? BiometricKind.face
          : BiometricKind.fingerprint;
    } on Exception catch (error) {
      debugPrint('Biometrics unavailable: $error');
      return null;
    }
  }

  @override
  Future<bool> authenticate({required String reason}) async {
    try {
      return await _auth.authenticate(localizedReason: reason);
    } on Exception catch (error) {
      debugPrint('Biometric authentication failed: $error');
      return false;
    }
  }
}
