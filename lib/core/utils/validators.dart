/// Whether [email] looks like an e-mail address.
bool isValidEmail(String email) {
  return RegExp(
    r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
  ).hasMatch(email);
}

/// Digits in a Pakistani mobile number: 03 and nine more.
const pakistaniMobileLength = 11;

/// What can be wrong with a Pakistani mobile number as typed.
enum MobileNumberProblem {
  /// Nothing typed.
  empty,

  /// It doesn't start with 03, or has something other than digits in it.
  prefix,

  /// It isn't 11 digits long.
  length,
}

/// What is wrong with [number] as a Pakistani mobile number, which is 03
/// and nine more digits, such as 03001234567; null when nothing is. A
/// number too short to judge yet, like "0", has only its length wrong.
MobileNumberProblem? mobileNumberProblem(String number) {
  final digits = number.trim();
  if (digits.isEmpty) return MobileNumberProblem.empty;
  if (!RegExp(r'^\d+$').hasMatch(digits) ||
      !(digits.length == 1 ? digits == '0' : digits.startsWith('03'))) {
    return MobileNumberProblem.prefix;
  }
  if (digits.length != pakistaniMobileLength) {
    return MobileNumberProblem.length;
  }
  return null;
}

/// Whether [number] is a Pakistani mobile number: 03 and nine more digits.
bool isValidPakistaniMobile(String number) =>
    mobileNumberProblem(number) == null;

/// [number] in international form for display, such as +92 300 1234567.
String formatPakistaniMobile(String number) {
  final digits = number.trim();
  final local = digits.startsWith('0') ? digits.substring(1) : digits;
  if (local.length != 10) return digits;
  return '+92 ${local.substring(0, 3)} ${local.substring(3)}';
}
