import 'package:flutter/foundation.dart';
import 'package:railway_hrms/core/di/service_locator.dart';
import 'package:railway_hrms/core/face_verification/face_remote_datasource.dart';
import 'package:railway_hrms/core/face_verification/face_repository.dart';
import 'package:railway_hrms/core/face_verification/face_repository_impl.dart';
import 'package:railway_hrms/core/network/dio_client.dart';
import 'package:railway_hrms/core/permissions/permission_gate.dart';
import 'package:railway_hrms/core/security/biometric_authenticator.dart';
import 'package:railway_hrms/core/theme/appearance_controller.dart';
import 'package:railway_hrms/core/theme/text_look_controller.dart';
import 'package:railway_hrms/core/update/app_updater.dart';
import 'package:railway_hrms/core/update/play_app_updater.dart';
import 'package:railway_hrms/core/update/store_listing_updater.dart';
import 'package:railway_hrms/modules/auth/bloc/auth_cubit.dart';
import 'package:railway_hrms/modules/auth/data/auth_remote_datasource.dart';
import 'package:railway_hrms/modules/auth/data/auth_repository.dart';
import 'package:railway_hrms/modules/auth/data/auth_repository_impl.dart';
import 'package:railway_hrms/modules/hrms/bloc/face/face_verification_cubit.dart';
import 'package:railway_hrms/modules/prams/bloc/accident_cubit.dart';
import 'package:railway_hrms/modules/prams/bloc/incident_photo_cubit.dart';
import 'package:railway_hrms/modules/prams/data/accident_remote_datasource.dart';
import 'package:railway_hrms/modules/prams/data/accident_repository.dart';
import 'package:railway_hrms/modules/prams/data/accident_repository_impl.dart';
import 'package:railway_hrms/modules/prams/services/file_upload_service.dart';
import 'package:railway_hrms/modules/tracking/bloc/real_time_tracking_cubit.dart';
import 'package:railway_hrms/modules/tracking/data/train_remote_datasource.dart';
import 'package:railway_hrms/modules/tracking/data/train_repository.dart';
import 'package:railway_hrms/modules/tracking/data/train_repository_impl.dart';
import 'package:railway_hrms/modules/tracking/services/track_history_store.dart';

/// Registers the app's services with [sl], module by module.
Future<void> init() async {
  // The look is read before the first frame, so it never flashes.
  final appearance = AppearanceController();
  await appearance.load();
  sl.registerSingleton<AppearanceController>(appearance);
  final textLook = TextLookController();
  await textLook.load();
  sl.registerSingleton<TextLookController>(textLook);
  // Core
  sl.registerLazySingleton(() => DioClient());
  sl.registerLazySingleton<FaceRemoteDataSource>(
    () => FaceRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<FaceRepository>(() => FaceRepositoryImpl(sl()));
  sl.registerLazySingleton<BiometricAuthenticator>(
    () => LocalBiometricAuthenticator(),
  );
  sl.registerLazySingleton<PermissionGate>(() => PermissionGate());
  // Google Play updates the app in place; iOS, and any install Play didn't
  // make, update from the store listing.
  sl.registerLazySingleton<AppUpdater>(
    () => defaultTargetPlatform == TargetPlatform.android
        ? PlayAppUpdater(fallback: StoreListingUpdater())
        : StoreListingUpdater(),
  );

  // Auth
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()));
  sl.registerFactory<AuthCubit>(() => AuthCubit(sl()));

  // HRMS
  sl.registerFactory<FaceVerificationCubit>(
    () => FaceVerificationCubit(sl<FaceRepository>()),
  );

  // Tracking
  sl.registerLazySingleton<TrainRemoteDataSource>(
    () => TrainRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<TrainRepository>(() => TrainRepositoryImpl(sl()));
  sl.registerLazySingleton<TrackHistoryStore>(TrackHistoryStore.new);
  sl.registerFactory<RealTimeTrackingCubit>(
    () => RealTimeTrackingCubit(sl(), history: sl<TrackHistoryStore>()),
  );

  // PRAMS
  sl.registerLazySingleton<AccidentRemoteDataSource>(
    () => AccidentRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<AccidentRepository>(
    () => AccidentRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => FileUploadService());
  sl.registerFactory<AccidentCubit>(
    () => AccidentCubit(repository: sl<AccidentRepository>()),
  );
  sl.registerFactory<IncidentPhotosCubit>(
    () => IncidentPhotosCubit(sl<FileUploadService>()),
  );
}
