// accident_display_extension.dart
//
// The generated Accidents model only has raw API fields (trainNumber,
// trainName, accidentDateTime as a String, etc). This extension adds the
// formatted values the list/card UI actually needs, without adding any
// fields to the generated model itself.

import 'package:railway_hrms/modules/prams/data/models/accident_list_item.dart';

extension AccidentDisplay on Accidents {
  /// "105-UP Tezgam Express" style label.
  String get trainRoute {
    final numberPart = [
      trainNumber ?? '',
      trainDirection ?? '',
    ].where((s) => s.isNotEmpty).join('-');
    final parts = [numberPart, trainName ?? ''].where((s) => s.isNotEmpty);
    return parts.isEmpty ? 'Unknown Train' : parts.join(' ');
  }

  /// Best available label for "where it happened".
  String get incidentLocation {
    if ((blockSectionLabel ?? '').isNotEmpty) return blockSectionLabel!;
    if ((blockSectionName ?? '').isNotEmpty) return blockSectionName!;
    if ((nearestStationName ?? '').isNotEmpty) {
      return 'Near $nearestStationName';
    }
    return 'Location not recorded';
  }

  DateTime? get _incidentDateTime => DateTime.tryParse(accidentDateTime ?? '');

  /// "12 May 2025"
  String get dateLabel {
    final dt = _incidentDateTime;
    if (dt == null) return 'N/A';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  /// "10:45 AM"
  String get timeLabel {
    final dt = _incidentDateTime;
    if (dt == null) return '';
    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour12:$minute $period';
  }

  /// "10 mins ago" / "2 days ago", based on the most recent timestamp available.
  String get updatedLabel {
    final raw = updatedAt ?? reportedAt ?? createdAt;
    final dt = DateTime.tryParse(raw ?? '');
    if (dt == null) return 'recently';

    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} min${diff.inMinutes == 1 ? '' : 's'} ago';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
    }
    return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
  }

  /// "Under Investigation" from "under_investigation" / "UNDER_INVESTIGATION".
  String get statusLabel {
    final raw = (status ?? 'reported').replaceAll('_', ' ');
    return raw
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }

  /// Card title: prefer the human meaning, fall back through the chain.
  String get displayTitle {
    if ((accidentClassMeaning ?? '').isNotEmpty) return accidentClassMeaning!;
    if ((accidentClassCode ?? '').isNotEmpty) return accidentClassCode!;
    if ((accidentId ?? '').isNotEmpty) return accidentId!;
    return 'Accident #${id ?? '-'}';
  }

  /// Lowercased text blob used for search matching.
  String get searchBlob => [
    displayTitle,
    trainRoute,
    originStationName ?? '',
    destinationStationName ?? '',
    incidentLocation,
    statusLabel,
  ].join(' ').toLowerCase();
}
