import 'package:flutter/foundation.dart';

/// A face the camera saw live and the server matched to the employee:
/// who signed an inspection, when and where.
@immutable
class InspectionIdentity {
  const InspectionIdentity({
    required this.photoPath,
    required this.verifiedAt,
    this.latitude,
    this.longitude,
  });

  /// The photo the face was matched on, kept with the app's documents as
  /// `FootplateFileUtils` stores it.
  final String photoPath;
  final DateTime verifiedAt;
  final double? latitude;
  final double? longitude;

  bool get hasPlace => latitude != null && longitude != null;

  Map<String, dynamic> toJson() => {
    'photo': photoPath,
    'verified_at': verifiedAt.toIso8601String(),
    'latitude': ?latitude,
    'longitude': ?longitude,
  };

  static InspectionIdentity? fromJson(Object? json) {
    if (json is! Map) return null;
    final photo = json['photo']?.toString();
    final at = DateTime.tryParse(json['verified_at']?.toString() ?? '');
    if (photo == null || photo.isEmpty || at == null) return null;
    return InspectionIdentity(
      photoPath: photo,
      verifiedAt: at,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}

/// The face checks an inspection is bounded by: when it was started and
/// when it was submitted.
@immutable
class InspectionSignatures {
  const InspectionSignatures({this.start, this.submit});

  final InspectionIdentity? start;
  final InspectionIdentity? submit;

  /// Both checks, for a report that goes out.
  bool get complete => start != null && submit != null;

  InspectionSignatures copyWith({
    InspectionIdentity? start,
    InspectionIdentity? submit,
  }) => InspectionSignatures(
    start: start ?? this.start,
    submit: submit ?? this.submit,
  );

  Map<String, dynamic> toJson() => {
    'start_verification': ?start?.toJson(),
    'submit_verification': ?submit?.toJson(),
  };
}
