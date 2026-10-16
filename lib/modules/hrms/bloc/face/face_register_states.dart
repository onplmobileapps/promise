abstract class FaceRegisterStates {}

class FaceVerifyInitialState extends FaceRegisterStates {}

class FaceVerifying extends FaceRegisterStates {}

class FaceVerified extends FaceRegisterStates {
  String message;
  FaceVerified(this.message);
}

class FaceVerifyError extends FaceRegisterStates {
  String error;
  FaceVerifyError(this.error);
}
