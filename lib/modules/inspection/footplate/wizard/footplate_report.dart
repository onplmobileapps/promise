import 'package:flutter/material.dart';
import 'package:railway_hrms/modules/inspection/footplate/models/footplate_models.dart';
import 'package:railway_hrms/modules/inspection/shared/report/inspection_report.dart';

String _time(TimeOfDay? t) => t == null
    ? ''
    : '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

String _clock(DateTime? at) =>
    at == null ? '' : _time(TimeOfDay.fromDateTime(at));

/// A footplate inspection as its report reads: the train and crew, the
/// locomotive, each station's assets with their photos, the asset checks,
/// punctuality and the caution orders received.
InspectionReport footplateReport(
  FootplateInspectionData data, {
  required String title,
}) {
  final s = data.trainSchedule;
  return InspectionReport(
    title: title,
    subtitle: [?s.trainNo, ?s.station].join(' · '),
    date: DateTime.now(),
    facts: [
      ReportRow('Train', s.trainNo, tone: ReportTone.plain),
      ReportRow('Engine', s.engineNo, tone: ReportTone.plain),
      ReportRow('Station', s.station, tone: ReportTone.plain),
    ],
    sections: [
      ReportSection(
        title: 'Train Schedule',
        step: 0,
        rows: [
          ReportRow('Load', s.load, tone: ReportTone.plain),
          ReportRow('Direction', s.direction, tone: ReportTone.plain),
          ReportRow('Arrival', _time(s.arrival), tone: ReportTone.plain),
          ReportRow('Departure', _time(s.departure), tone: ReportTone.plain),
          ReportRow(
            'Late margin',
            s.lateMargin == 0 ? '' : '${s.lateMargin} s',
            tone: ReportTone.plain,
          ),
          ReportRow('Driver', s.driver?.display, tone: ReportTone.plain),
          ReportRow(
            'Assistant driver',
            s.assistantDriver?.display,
            tone: ReportTone.plain,
          ),
          ReportRow(
            'Guard incharge',
            s.guardIncharge?.display,
            tone: ReportTone.plain,
          ),
        ],
      ),
      ReportSection(
        title: 'Condition of Locomotive',
        step: 1,
        rows: [
          for (final item in kLocomotiveItems)
            if (data.locomotive.getStatus(item) case final status)
              ReportRow(
                item,
                [
                  if (kLocomotiveFieldConfigs[item]?.directSelect ?? false)
                    status.selectedIssues.join(', ')
                  else ...[
                    status.isFunctional ? 'OK' : 'Issue',
                    if (status.selectedIssues.isNotEmpty)
                      status.selectedIssues.join(', '),
                    if (status.integerValue != null) '${status.integerValue}',
                    if (status.dateValue != null)
                      displayValue(status.dateValue),
                  ],
                ].where((part) => part.isNotEmpty).join(' — '),
                tone: kLocomotiveFieldConfigs[item]?.directSelect ?? false
                    ? ReportTone.plain
                    : status.isFunctional
                    ? ReportTone.good
                    : ReportTone.bad,
              ),
        ],
      ),
      for (final station in data.stationAssets)
        ReportSection(
          title: 'Station Assets · ${station.stationName}',
          step: 2,
          note: station.overallRemarks,
          photos: [for (final a in station.assets) ...a.photos],
          rows: [
            for (final asset in station.assets)
              ReportRow(
                asset.assetName,
                [
                  ?asset.status,
                  if (asset.remarks?.isNotEmpty ?? false) asset.remarks!,
                ].join(' — '),
                tone: !asset.isChecked
                    ? ReportTone.missing
                    : asset.hasIssue
                    ? ReportTone.bad
                    : ReportTone.good,
              ),
          ],
        ),
      ReportSection(
        title: 'Asset Checks',
        step: 3,
        rows: [
          for (final entry in data.assetChecks)
            for (final MapEntry(:key, :value) in entry.answers.entries)
              if (displayValue(value) case final shown when shown.isNotEmpty)
                ReportRow(
                  '${entry.assetType} · ${_label(entry.assetType, key)}',
                  shown,
                ),
        ],
      ),
      ReportSection(
        title: 'Punctuality',
        step: 4,
        rows: [
          for (final stop in data.punctuality)
            ReportRow(
              stop.station,
              [
                'Arr ${_clock(stop.scheduleArrival)} / ${_clock(stop.actualArrival)}',
                'Dep ${_clock(stop.scheduleDeparture)} / ${_clock(stop.actualDeparture)}',
                if (stop.remarks.isNotEmpty) stop.remarks,
              ].join(' — '),
              tone: stop.hasDifference ? ReportTone.bad : ReportTone.good,
            ),
        ],
      ),
      ReportSection(
        title: 'Caution Orders / OPs',
        step: 4,
        note: data.finalRemarks,
        rows: [
          for (final op in data.ops)
            ReportRow(op.opCode, op.decimal, tone: ReportTone.plain),
        ],
      ),
    ],
  );
}

/// A configured asset question's label, or its key made readable.
String _label(String assetType, String key) {
  for (final field
      in kAssetFieldConfig[assetType] ?? const <RadioFieldConfig>[]) {
    if (field.key == key) return field.label;
  }
  final words = key.replaceAll('_', ' ');
  return words.isEmpty ? key : words[0].toUpperCase() + words.substring(1);
}
