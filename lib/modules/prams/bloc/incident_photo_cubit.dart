import 'dart:io';
import 'package:railway_hrms/core/bloc/safe_bloc.dart';
import 'package:railway_hrms/modules/prams/services/file_upload_service.dart';

// State definition
class IncidentPhotosState {
  final List<File> photos;
  final bool isLoading;
  final String? errorMessage;

  const IncidentPhotosState({
    this.photos = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  bool get canAddMore => photos.length < 5;
  int get remainingSlots => 5 - photos.length;

  IncidentPhotosState copyWith({
    List<File>? photos,
    bool? isLoading,
    String? errorMessage,
  }) {
    return IncidentPhotosState(
      photos: photos ?? this.photos,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

// Cubit definition
class IncidentPhotosCubit extends SafeCubit<IncidentPhotosState> {
  final FileUploadService _uploadService;

  IncidentPhotosCubit(this._uploadService) : super(const IncidentPhotosState());

  Future<void> pickFromGallery() async {
    if (!state.canAddMore) return;

    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final pickedFiles = await _uploadService.pickImagesFromGallery(
        currentCount: state.photos.length,
      );

      if (pickedFiles.isNotEmpty) {
        final updatedList = List<File>.from(state.photos)..addAll(pickedFiles);
        emit(state.copyWith(photos: updatedList, isLoading: false));
      } else {
        emit(state.copyWith(isLoading: false));
      }
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to pick photos: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> captureFromCamera() async {
    if (!state.canAddMore) return;

    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final photo = await _uploadService.capturePhotoFromCamera();
      if (photo != null) {
        final updatedList = List<File>.from(state.photos)..add(photo);
        emit(state.copyWith(photos: updatedList, isLoading: false));
      } else {
        emit(state.copyWith(isLoading: false));
      }
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to capture photo: ${e.toString()}',
        ),
      );
    }
  }

  void removePhotoAt(int index) {
    if (index < 0 || index >= state.photos.length) return;
    final updatedList = List<File>.from(state.photos)..removeAt(index);
    emit(state.copyWith(photos: updatedList));
  }

  /// Removes all selected photos (used by the form's Reset button).
  void clear() => emit(const IncidentPhotosState());
}
