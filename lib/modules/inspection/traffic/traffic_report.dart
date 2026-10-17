import 'package:railway_hrms/modules/inspection/shared/report/inspection_report.dart';
import 'package:railway_hrms/modules/inspection/traffic/models.dart';

ReportRow _yesNo(String label, bool value, {bool yesIsFault = false}) =>
    ReportRow(
      label,
      value ? 'Yes' : 'No',
      tone: value == yesIsFault ? ReportTone.bad : ReportTone.good,
    );

ReportRow _text(String label, String value) =>
    ReportRow(label, value, tone: ReportTone.plain);

/// A checklist's items as report rows: each as found, with its count and
/// remark.
List<ReportRow> _checks(
  List<ChecklistItem> items,
  ChecklistFormData data, {
  String positive = 'OK',
  String negative = 'Issue',
  bool defaultChecked = true,
}) => [
  for (final item in items)
    _check(
      item,
      data.answers[item.key] ?? ChecklistAnswer(checked: defaultChecked),
      positive: positive,
      negative: negative,
      plain: !defaultChecked,
    ),
];

ReportRow _check(
  ChecklistItem item,
  ChecklistAnswer answer, {
  required String positive,
  required String negative,
  required bool plain,
}) => ReportRow(
  item.label,
  [
    answer.checked ? positive : negative,
    if (answer.quantity.isNotEmpty) '${item.quantityLabel}: ${answer.quantity}',
    if (answer.remarks.isNotEmpty) answer.remarks,
  ].join(' — '),
  tone: plain
      ? ReportTone.plain
      : answer.checked
      ? ReportTone.good
      : ReportTone.bad,
);

ReportSection _section(
  String title,
  List<ChecklistItem> items,
  ChecklistFormData data, {
  required int step,
  String positive = 'OK',
  String negative = 'Issue',
}) => ReportSection(
  title: title,
  step: step,
  rows: _checks(items, data, positive: positive, negative: negative),
);

/// The commercial station form as its report reads.
List<ReportSection> commercialReport(TrafficCommercialStationData d) => [
  _section(
    'Booking Office',
    kBookingOfficeChecklist,
    d.bookingOffice,
    step: 0,
    positive: 'Updated',
    negative: 'Not Updated',
  ),
  _section(
    'Station Statistics (TM-34)',
    kStationStatisticsChecklist,
    d.stationStatistics,
    step: 0,
    positive: 'Updated',
    negative: 'Not Updated',
  ),
  _section(
    'Ticketing Data of TCR Office',
    kTcrCommercialChecklist,
    d.tcrOffice,
    step: 0,
    positive: 'Updated',
    negative: 'Not Updated',
  ),
  _section(
    'Station Mirror (T.M 35)',
    kStationMirrorChecklist,
    d.stationMirror,
    step: 0,
    positive: 'Updated',
    negative: 'Not Updated',
  ),
  ReportSection(
    title: 'Parcels',
    step: 1,
    rows: [
      ..._checks(kInwardParcelChecklist, d.inwardParcel),
      _yesNo(
        'Undelivered parcels present',
        d.undeliveredParcels,
        yesIsFault: true,
      ),
      ..._checks(
        kOutwardParcelChecklist,
        d.outwardParcel,
        positive: 'Appropriate',
        negative: 'In-Appropriate',
      ),
    ],
  ),
  ReportSection(
    title: 'Lost Property Office (LPO)',
    step: 1,
    rows: [
      _yesNo('Weighment accuracy available', d.lpoWeighmentAvailable),
      if (d.lpoWeighmentAvailable) _text('Number', d.lpoWeighmentNumber),
      _yesNo('Items evaluated by ICG and CMI', d.lpoItemsEvaluated),
      if (d.lpoItemsEvaluated)
        _text('Amount', d.lpoAmount)
      else
        _text('Date of evaluation', d.lpoDateOfEvaluation),
      _text('Last auction amount', d.lpoLastAuctionAmount),
      _text('Last auction date', d.lpoLastAuctionDate),
    ],
  ),
  ReportSection(
    title: 'Goods Office',
    step: 2,
    rows: [
      _text('Weighment machine due date', d.weighmentDueDate),
      _text('Weighment machine next date', d.weighmentNextDate),
      ..._checks(kGoodsOfficeChecklist, d.goodsOffice),
    ],
  ),
  ReportSection(
    title: 'Vending Shops / Stalls',
    step: 3,
    rows: [
      ..._checks(kVendingStallsChecklist, d.vendingStalls),
      _yesNo(
        'Selling of unauthorized items',
        d.sellingUnauthorizedItems,
        yesIsFault: true,
      ),
      _yesNo(
        'Unauthorized vendor present',
        d.unauthorizedVendorPresent,
        yesIsFault: true,
      ),
    ],
  ),
  _section(
    "Station Master's Office",
    kStationMastersOfficeChecklist,
    d.stationMastersOffice,
    step: 3,
  ),
  _section(
    'General Cleanliness of the Station',
    kGeneralCleanlinessChecklist,
    d.generalCleanliness,
    step: 3,
    positive: 'Satisfactory',
    negative: 'Not Satisfactory',
  ),
  _section(
    'Safety Equipment — Condition',
    kSafetyEquipmentConditionChecklist,
    d.safetyEquipmentCondition,
    step: 3,
    positive: 'Satisfactory',
    negative: 'Not Satisfactory',
  ),
  ReportSection(
    title: 'Train(s) Present / Arrived',
    step: 3,
    rows: _checks(
      kTrainPresentChecklist,
      d.trainsPresent,
      positive: 'Satisfactory',
      negative: 'Not Satisfactory',
    ),
    note: d.finalRemarks,
  ),
];

/// The transport station form as its report reads.
List<ReportSection> transportReport(TrafficTransportStationData d) {
  final orders = d.cautionOrders.answers.entries
      .where((order) => order.value.checked)
      .map(
        (order) => ReportRow(
          order.key,
          order.value.quantity.isEmpty
              ? 'Issued'
              : 'Issued — ${order.value.quantity}',
          tone: ReportTone.plain,
        ),
      )
      .toList();
  return [
    _section(
      'Registers & Books',
      kRegisterBooksChecklist,
      d.stationJournal,
      step: 0,
      positive: 'Updated',
      negative: 'Not Updated',
    ),
    ReportSection(
      title: 'Staff & Systems',
      step: 0,
      rows: [
        _yesNo('Staff present', d.stationJournal.of('staff_present').checked),
        for (final key in const [
          'slot_frame',
          'sm_control',
          'communication',
          'magneto_phone',
          'block_instruments',
          'neal_ball_token',
        ])
          if (d.stationJournal.answers[key] case final answer?)
            ReportRow(
              key.replaceAll('_', ' '),
              answer.checked ? 'In order' : 'Fault',
              tone: answer.checked ? ReportTone.good : ReportTone.bad,
            ),
      ],
    ),
    _section(
      'Ticketing Data of TCR Office',
      kTcrTransportBooksChecklist,
      d.tcrBooks,
      step: 1,
      positive: 'Available',
      negative: 'Not Available',
    ),
    ReportSection(
      title: 'Operating Document & Caution Orders',
      step: 1,
      rows: [
        _yesNo('Operating document issued', d.operatingDocumentIssued),
        if (d.operatingDocumentIssued)
          _text('Total issued', d.operatingDocumentTotalIssued),
        ...orders,
      ],
    ),
    ReportSection(
      title: 'Staff Equipment — Condition',
      step: 2,
      rows: _checks(
        [
          ...kSafetyEquipmentConditionChecklist,
          const ChecklistItem(
            key: 'fire_bucket_condition',
            label: 'Fire bucket',
          ),
        ],
        d.staffEquipmentCondition,
        positive: 'Satisfactory',
        negative: 'Not Satisfactory',
      ),
    ),
    ReportSection(
      title: 'Points',
      step: 2,
      rows: [
        for (final point in d.points)
          ReportRow(
            point.label,
            point.workingProperly ? 'Working' : 'Not working',
          ),
      ],
    ),
    ReportSection(
      title: 'Siding',
      step: 3,
      rows: [
        _yesNo('DVM stock present', d.dvmStockPresent),
        _yesNo('Fit stock present', d.fitStockPresent),
        _text('Platform level', d.platformLevel),
        _yesNo('Communication with staff', d.communicationWithStaff),
      ],
      note: d.finalRemarks,
    ),
  ];
}

/// The level crossings as their report reads.
List<ReportSection> levelCrossingReport(List<LevelCrossingRecord> records) => [
  for (final (i, r) in records.indexed) ...[
    ReportSection(
      title: 'Crossing ${i + 1}',
      step: i,
      rows: [
        _text('Sponsoring agency', r.sponsoringAgency),
        _text('Road surface type', r.roadSurfaceType),
        _text('Road surface soiling', r.roadSurfaceSoiling),
        _text('Communication', r.communicationMechanism),
        _text('Jurisdiction (m)', r.jurisdictionMeters),
        _text(
          'Location',
          r.latitude.isEmpty ? '' : '${r.latitude}, ${r.longitude}',
        ),
      ],
    ),
    ReportSection(
      title: 'Crossing ${i + 1} · Equipment',
      step: i,
      rows: _checks(
        kLevelCrossingEquipmentChecklist,
        r.equipment,
        positive: 'Functional',
        negative: 'Not Functional',
      ),
    ),
  ],
];
