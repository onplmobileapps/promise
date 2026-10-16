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

class StationInspectionController extends ChangeNotifier {
  static const String _draftStorageKey = 'station_inspection_draft_v1';

  final Map<String, dynamic> fields = {};
  final Map<String, List<int>> repeatRows = {};
  int _rowSeq = 1;

  String? station;
  String stationOther = '';
  DateTime inspDate = DateTime.now();
  bool isStarted = false;
  bool isFaceVerified = false;
  String? faceImagePath;
  int currentStep = 0;

  StationInspectionController() {
    for (final type in kRepeatDefs.keys) {
      _ensureRepeat(type);
    }
  }

  // ---------------------------------------------------------------------
  // Preparation Flow
  // ---------------------------------------------------------------------

  void startInspection() {
    isStarted = true;
    notifyListeners();
  }

  void setStation(String? v) {
    station = v;
    notifyListeners();
  }

  void setFaceVerified(bool verified, String? path) {
    isFaceVerified = verified;
    faceImagePath = path;
    notifyListeners();
  }

  void resetInspection() {
    isStarted = false;
    isFaceVerified = false;
    faceImagePath = null;
    station = null;
    stationOther = '';
    inspDate = DateTime.now();
    currentStep = 0;
    fields.clear();
    notifyListeners();
  }

  Map<String, dynamic> toDraftJson() {
    final serializableFields = <String, dynamic>{};
    fields.forEach((key, val) {
      if (val is DateTime) {
        serializableFields[key] = val.toIso8601String();
      } else {
        serializableFields[key] = val;
      }
    });

    return {
      'currentStep': currentStep,
      'station': station,
      'stationOther': stationOther,
      'inspDate': inspDate.toIso8601String(),
      'isFaceVerified': isFaceVerified,
      'faceImagePath': faceImagePath,
      'fields': serializableFields,
      'repeatRows': repeatRows,
    };
  }

  void fromDraftJson(Map<String, dynamic> json) {
    currentStep = json['currentStep'] is int ? json['currentStep'] as int : 0;
    station = json['station'] as String?;
    stationOther = json['stationOther'] as String? ?? '';
    if (json['inspDate'] != null) {
      inspDate =
          DateTime.tryParse(json['inspDate'].toString()) ?? DateTime.now();
    }
    // Face verification must be completed fresh for every session
    isFaceVerified = false;
    faceImagePath = null;

    if (json['fields'] is Map) {
      fields.clear();
      (json['fields'] as Map).forEach((key, val) {
        final strKey = key.toString();
        final strVal = val?.toString();
        if (strVal != null &&
            (strKey.toLowerCase().contains('date') ||
                strKey.toLowerCase().contains('time'))) {
          final dt = DateTime.tryParse(strVal);
          if (dt != null) {
            fields[strKey] = dt;
          } else {
            fields[strKey] = val;
          }
        } else {
          fields[strKey] = val;
        }
      });
    }

    if (json['repeatRows'] is Map) {
      repeatRows.clear();
      (json['repeatRows'] as Map).forEach((key, val) {
        if (val is List) {
          repeatRows[key.toString()] = List<int>.from(
            val.map((e) => e is int ? e : int.tryParse(e.toString()) ?? 0),
          );
        }
      });
    }

    notifyListeners();
  }

  Future<void> saveDraftToDisk() async {
    final payload = jsonEncode(toDraftJson());
    await StorageService.saveInspectionDraft(_draftStorageKey, payload);
  }

  Future<bool> loadDraftFromDisk() async {
    final raw = await StorageService.getInspectionDraft(_draftStorageKey);
    if (raw != null && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        fromDraftJson(decoded);
        return true;
      } catch (e) {
        debugPrint('Error loading station draft from disk: $e');
      }
    }
    return false;
  }

  Future<void> clearDraftFromDisk() async {
    await StorageService.clearInspectionDraft(_draftStorageKey);
  }

  // ---------------------------------------------------------------------
  // Field access
  // ---------------------------------------------------------------------

  T? get<T>(String id) => fields[id] as T?;

  void setField(String id, dynamic value) {
    fields[id] = value;
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

  // ---------------------------------------------------------------------
  // Summary text (for review + copy/print)
  // ---------------------------------------------------------------------

  String buildSummaryText(List<InspectionSection> sections) {
    final lines = <String>[];
    lines.add('STATION INSPECTION — SIGNAL & TELECOM SYSTEM');
    final stationName = station == 'Other' ? stationOther : (station ?? '');
    lines.add('Station: ${stationName.isEmpty ? '—' : stationName}');
    lines.add('Date: ${_formatDate(inspDate)}');
    lines.add('');

    for (final section in sections) {
      if (section.isReview) continue;
      final entries = <String>[];

      if (section.isSignals) {
        for (var i = 0; i < kSignalNames.length; i++) {
          for (final part in kSignalParts) {
            final fid = 'sig_${i}_${part[0]}';
            final v = fields[fid];
            if (v != null) {
              entries.add('  • ${kSignalNames[i]} — ${part[1]}: $v');
              if (v == 'Unsatisfactory') {
                final r = fields['${fid}_remark'];
                if (r != null && r.toString().trim().isNotEmpty) {
                  entries.add('    - Remarks: $r');
                }
              }
            }
          }
        }
      } else if (section.isRepeatSection) {
        final type = section.repeatType!;
        final def = kRepeatDefs[type]!;
        final rows = rowsFor(type);
        for (var i = 0; i < rows.length; i++) {
          final rowId = rows[i];
          final rowHasData = def.cols.any(
            (c) => isFilled('${rowPrefix(type, rowId)}_${c.key}'),
          );
          if (!rowHasData) continue;
          entries.add('  ${def.label} ${i + 1}:');
          for (final col in def.cols) {
            final fid = '${rowPrefix(type, rowId)}_${col.key}';
            final v = fields[fid];
            if (v != null && v.toString().trim().isNotEmpty) {
              entries.add(
                '    - ${col.label.isEmpty ? col.key : col.label}: $v',
              );
              final spec = col.build(fid);
              if (spec.kind == FieldKind.toggleRemark &&
                  classifyValue(v.toString()) == FieldTone.negative) {
                final r = fields[spec.remarkId];
                if (r != null && r.toString().trim().isNotEmpty) {
                  entries.add('      - Remarks: $r');
                }
              }
            }
          }
          if (def.hasTotal) {
            entries.add('    - Total: ${rowTotal(type, rowId)}');
          }
        }
      } else {
        for (final item in section.items) {
          if (item is! FieldFormItem) continue;
          final spec = item.spec;
          final v = fields[spec.id];
          if (v == null || v.toString().trim().isEmpty) continue;
          entries.add('  • ${spec.label}: ${_displayValue(v)}');
          if (spec.kind == FieldKind.toggleRemark) {
            final r = fields[spec.remarkId];
            if (r != null && r.toString().trim().isNotEmpty) {
              entries.add('    - Remarks: $r');
            }
          }
        }
      }

      if (entries.isNotEmpty) {
        lines.add(section.title.toUpperCase());
        lines.addAll(entries);
        lines.add('');
      }
    }

    lines.add('SUBMITTED BY');
    lines.add('  • Name: ${fields['submittedName'] ?? '—'}');
    lines.add('  • Designation: ${fields['submittedDesignation'] ?? '—'}');
    final submittedDate = fields['submittedDate'] as DateTime?;
    lines.add(
      '  • Date: ${submittedDate != null ? _formatDate(submittedDate) : '—'}',
    );
    final remarks = fields['remarks'];
    if (remarks != null && remarks.toString().trim().isNotEmpty) {
      lines.add('  • Remarks: $remarks');
    }
    return lines.join('\n');
  }

  static String _displayValue(dynamic v) {
    if (v is DateTime) return _formatDate(v);
    return v.toString();
  }
}
