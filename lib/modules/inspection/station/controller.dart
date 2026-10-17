import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:railway_hrms/core/storage/storage_service.dart';
import 'package:railway_hrms/modules/inspection/station/models.dart';
import 'package:railway_hrms/modules/inspection/station/section_data.dart';

enum OverdueStatus { empty, overdue, dueSoon, valid }

class OverdueInfo {
  final OverdueStatus status;
  final String text;
  const OverdueInfo(this.status, this.text);
}

/// The answers of a station inspection, kept as it is filled in and as a
/// draft on the phone between visits.
class StationInspectionController extends ChangeNotifier {
  /// Where the draft is kept; also its entry among the dashboard's drafts.
  static const String draftId = 'station_inspection_draft_v1';

  final Map<String, dynamic> fields = {};
  final Map<String, List<int>> repeatRows = {};
  int _rowSeq = 1;

  /// The station inspected, as its name and its number on the server.
  String? station;
  int? stationId;
  DateTime inspDate = DateTime.now();

  /// The step the draft was left on.
  int currentStep = 0;

  StationInspectionController() {
    for (final type in kRepeatDefs.keys) {
      _ensureRepeat(type);
    }
  }

  /// Something has been filled in.
  bool get hasAnswers => fields.values.any(
    (value) => value != null && value.toString().trim().isNotEmpty,
  );

  void setStation(String? name, {int? id}) {
    station = name;
    stationId = id;
    notifyListeners();
  }

  void setDate(DateTime day) {
    inspDate = day;
    notifyListeners();
  }

  Map<String, dynamic> toDraftJson() => {
    'currentStep': currentStep,
    'station': station,
    'stationId': stationId,
    'inspDate': inspDate.toIso8601String(),
    'fields': {
      for (final MapEntry(:key, :value) in fields.entries)
        key: value is DateTime ? value.toIso8601String() : value,
    },
    'repeatRows': repeatRows,
  };

  void fromDraftJson(Map<String, dynamic> json) {
    currentStep = json['currentStep'] is int ? json['currentStep'] as int : 0;
    station = json['station'] as String?;
    stationId = switch (json['stationId']) {
      final int id => id,
      final Object id => int.tryParse('$id'),
      null => null,
    };
    inspDate =
        DateTime.tryParse(json['inspDate']?.toString() ?? '') ?? DateTime.now();

    if (json['fields'] case final Map<dynamic, dynamic> saved) {
      fields.clear();
      saved.forEach((key, val) {
        final id = key.toString();
        final lower = id.toLowerCase();
        // Dates are kept as text; fields named for one read back as one.
        final day = val is String && lower.contains('date')
            ? DateTime.tryParse(val)
            : null;
        fields[id] = day ?? val;
      });
    }

    if (json['repeatRows'] case final Map<dynamic, dynamic> rows) {
      repeatRows.clear();
      rows.forEach((key, val) {
        if (val is List) {
          repeatRows[key.toString()] = [
            for (final e in val) e is int ? e : int.tryParse('$e') ?? 0,
          ];
        }
      });
      // New rows are numbered past the ones kept.
      final highest = repeatRows.values
          .expand((rows) => rows)
          .fold(0, (a, b) => a > b ? a : b);
      _rowSeq = highest + 1;
      for (final type in kRepeatDefs.keys) {
        _ensureRepeat(type);
      }
    }

    notifyListeners();
  }

  Future<void> saveDraftToDisk() =>
      StorageService.saveInspectionDraft(draftId, jsonEncode(toDraftJson()));

  Future<bool> loadDraftFromDisk() async {
    final raw = await StorageService.getInspectionDraft(draftId);
    if (raw == null || raw.trim().isEmpty) return false;
    try {
      fromDraftJson(jsonDecode(raw) as Map<String, dynamic>);
      return true;
    } on Object catch (e) {
      debugPrint('Station draft could not be read: $e');
      return false;
    }
  }

  /// Forgets the draft, and its entry among the dashboard's drafts.
  Future<void> clearDraftFromDisk() =>
      StorageService.deleteInspectionRecord(draftId);

  // ---------------------------------------------------------------------
  // Field access
  // ---------------------------------------------------------------------

  T? get<T>(String id) => fields[id] as T?;

  void setField(String id, dynamic value) {
    fields[id] = value;
    notifyListeners();
  }

  /// Answers each of [ids] still blank with [value], at once.
  void fillBlank(Iterable<String> ids, Object value) {
    for (final id in ids) {
      if (!isFilled(id)) fields[id] = value;
    }
    notifyListeners();
  }

  bool isFilled(String id) {
    final v = fields[id];
    if (v == null) return false;
    if (v is String) return v.trim().isNotEmpty;
    return true;
  }

  // ---------------------------------------------------------------------
  // Repeatable rows
  // ---------------------------------------------------------------------

  List<int> rowsFor(String type) => _ensureRepeat(type);

  List<int> _ensureRepeat(String type) {
    return repeatRows.putIfAbsent(type, () {
      final def = kRepeatDefs[type]!;
      return List.generate(def.minRows, (_) => _rowSeq++);
    });
  }

  void addRow(String type) {
    _ensureRepeat(type).add(_rowSeq++);
    notifyListeners();
  }

  void removeRow(String type, int rowId) {
    final def = kRepeatDefs[type]!;
    final rows = _ensureRepeat(type);
    if (rows.length <= def.minRows) return;
    rows.remove(rowId);
    final prefix = '${type}_${rowId}_';
    fields.removeWhere((key, _) => key.startsWith(prefix));
    notifyListeners();
  }

  String rowPrefix(String type, int rowId) => '${type}_$rowId';

  double rowTotal(String type, int rowId) {
    final def = kRepeatDefs[type]!;
    double sum = 0;
    for (final col in def.cols) {
      if ([
        'engg',
        'elect',
        'tcom',
        'tfc',
        'sig',
        'oc',
        'store',
      ].contains(col.key)) {
        final v = fields['${rowPrefix(type, rowId)}_${col.key}'];
        if (v is num) sum += v.toDouble();
      }
    }
    return sum;
  }

  // ---------------------------------------------------------------------
  // Fire extinguisher stepper -> dynamic per-extinguisher date fields
  // ---------------------------------------------------------------------

  int get fireExtCount => (fields['fireExtCount'] as int?) ?? 0;

  String fireExtDateId(int i) => 'fireExtDate_$i';

  // ---------------------------------------------------------------------
  // Overdue calculation (dateOverdue fields)
  // ---------------------------------------------------------------------

  OverdueInfo overdueInfo(String fieldId, int years) {
    final date = fields[fieldId] as DateTime?;
    if (date == null) {
      return const OverdueInfo(OverdueStatus.empty, 'Enter date to calculate');
    }
    final due = DateTime(date.year + years, date.month, date.day);
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final diffDays = due.difference(todayOnly).inDays;
    final dueStr = _formatDate(due);
    if (diffDays < 0) {
      final overdueBy = diffDays.abs();
      return OverdueInfo(
        OverdueStatus.overdue,
        'Overdue by $overdueBy day${overdueBy == 1 ? '' : 's'} (due $dueStr)',
      );
    } else if (diffDays <= 30) {
      return OverdueInfo(
        OverdueStatus.dueSoon,
        'Due soon — $diffDays day${diffDays == 1 ? '' : 's'} left ($dueStr)',
      );
    } else {
      return OverdueInfo(
        OverdueStatus.valid,
        'Valid until $dueStr ($diffDays days left)',
      );
    }
  }

  static String _formatDate(DateTime d) {
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
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}';
  }

  // ---------------------------------------------------------------------
  // Block-instrument overhaul period auto-adjustment
  // ---------------------------------------------------------------------

  int overhaulYearsForBlockType(String? blockType) {
    return kBlockOverhaulYears[blockType] ?? 5;
  }

  // ---------------------------------------------------------------------
  // Progress
  // ---------------------------------------------------------------------

  /// Returns (filled, total) for a fixed (non-repeat) section.
  (int, int) sectionFillProgress(InspectionSection section) {
    if (section.isSignals) {
      int total = 0, filled = 0;
      for (var i = 0; i < kSignalNames.length; i++) {
        for (final part in kSignalParts) {
          total++;
          final fid = 'sig_${i}_${part[0]}';
          if (isFilled(fid)) filled++;
        }
      }
      return (filled, total);
    }
    if (section.isRepeatSection) {
      final type = section.repeatType!;
      final def = kRepeatDefs[type]!;
      final rows = rowsFor(type);
      int total = 0, filled = 0;
      for (final rowId in rows) {
        for (final col in def.cols) {
          if (col.label.isEmpty) continue; // conditional remark-style column
          total++;
          if (isFilled('${rowPrefix(type, rowId)}_${col.key}')) filled++;
        }
      }
      return (filled, total);
    }
    int total = 0, filled = 0;
    for (final item in section.items) {
      if (item is FieldFormItem) {
        total++;
        if (isFilled(item.spec.id)) filled++;
        // Each extinguisher counted asks for its filling date.
        if (item.spec.id == 'fireExtCount') {
          for (var n = 1; n <= fireExtCount; n++) {
            total++;
            if (isFilled(fireExtDateId(n))) filled++;
          }
        }
      }
    }
    return (filled, total);
  }

  double overallProgress(List<InspectionSection> sections) {
    int total = 0, filled = 0;
    for (final s in sections) {
      final (f, t) = sectionFillProgress(s);
      total += t;
      filled += f;
    }
    if (total == 0) return 0;
    return filled / total;
  }
}
