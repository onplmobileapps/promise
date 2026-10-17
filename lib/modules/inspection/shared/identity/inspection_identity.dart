import 'package:flutter/foundation.dart';

/// A face the camera saw live and the server matched to the employee:
/// who signed an inspection, when and where.
///
/// A face taken with no connection can't be matched there and then: it is
/// kept, [matched] false, with its [photos] and [embeddings], and matched
/// before the inspection it signs goes out.
@immutable
class InspectionIdentity {
  const InspectionIdentity({
    required this.photoPath,
    required this.verifiedAt,
    this.latitude,
    this.longitude,
    this.matched = true,
    this.photos = const [],
    this.embeddings = const [],
  });

  /// The photo the face was matched on, kept with the app's documents as
  /// `FootplateFileUtils` stores it.
  final String photoPath;
  final DateTime verifiedAt;
  final double? latitude;
  final double? longitude;

  /// The face server has matched it to the employee.
  final bool matched;

  /// Every photo the check took, as the server is sent them to match.
  final List<String> photos;

  /// The face's embedding in each of [photos].
  final List<List<double>> embeddings;

  bool get hasPlace => latitude != null && longitude != null;

  /// The same check, once the server has matched it.
  InspectionIdentity asMatched() => InspectionIdentity(
    photoPath: photoPath,
    verifiedAt: verifiedAt,
    latitude: latitude,
    longitude: longitude,
  );

  /// The check as an inspection goes out with it.
  Map<String, dynamic> toJson() => {
    'photo': photoPath,
    'verified_at': verifiedAt.toIso8601String(),
    'latitude': ?latitude,
    'longitude': ?longitude,
  };

  /// The check as the phone keeps it, with what matching it later needs.
  Map<String, dynamic> toStoreJson() => {
    ...toJson(),
    if (!matched) ...{
      'matched': false,
      'photos': photos,
      'embeddings': embeddings,
    },
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
      matched: json['matched'] != false,
      photos: [for (final path in json['photos'] as List? ?? const []) '$path'],
      embeddings: [
        for (final face in json['embeddings'] as List? ?? const [])
          if (face is List) [for (final n in face) (n as num).toDouble()],
      ],
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

  /// No check is waiting to be matched.
  bool get matched => (start?.matched ?? true) && (submit?.matched ?? true);

  InspectionSignatures copyWith({
    InspectionIdentity? start,
    InspectionIdentity? submit,
  }) => InspectionSignatures(
    start: start ?? this.start,
    submit: submit ?? this.submit,
  );

  /// The checks as an inspection goes out with them.
  Map<String, dynamic> toJson() => {
    'start_verification': ?start?.toJson(),
    'submit_verification': ?submit?.toJson(),
  };

  /// The checks as the phone keeps them.
  Map<String, dynamic> toStoreJson() => {
    'start_verification': ?start?.toStoreJson(),
    'submit_verification': ?submit?.toStoreJson(),
  };

  static InspectionSignatures fromJson(Object? json) => json is Map
      ? InspectionSignatures(
          start: InspectionIdentity.fromJson(json['start_verification']),
          submit: InspectionIdentity.fromJson(json['submit_verification']),
        )
      : const InspectionSignatures();
}
