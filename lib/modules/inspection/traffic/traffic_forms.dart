import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';
import 'package:railway_hrms/modules/inspection/shared/widgets/inspection_fields.dart';
import 'package:railway_hrms/modules/inspection/shared/widgets/inspection_form_scaffold.dart';
import 'package:railway_hrms/modules/inspection/traffic/models.dart';
import 'package:railway_hrms/modules/inspection/traffic/widgets/traffic_checks.dart';

/// Equipment and systems of the station journal, each with its own words
/// for in order and not.
const _systems = [
  ('slot_frame', 'Slot frame', 'Working', 'Not working'),
  ('sm_control', 'S.M control', 'Functional', 'Non-functional'),
  ('communication', 'Communication', 'Functional', 'Non-functional'),
  ('magneto_phone', 'Magneto phone with gate', 'Functional', 'Non-functional'),
  ('block_instruments', 'Block Instruments', 'Working', 'Not working'),
  ('neal_ball_token', 'Neal ball token', 'Balanced', 'Un-balanced'),
];

Widget _remarks(String value, ValueChanged<String> onChanged) => Builder(
  builder: (context) => InspectionCard(
    title: context.l10n.inspFormNote,
    glyph: AppGlyphs.fileEdit,
    children: [
      InspectionTextInput(
        label: context.l10n.inspFormRemarkLabel,
        hint: context.l10n.inspFormNoteHint,
        kind: InspectionTextKind.multiline,
        value: value,
        onChanged: onChanged,
      ),
    ],
  ),
);

Widget _cards(List<Widget> cards) => Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    for (final (i, card) in cards.indexed) ...[
      if (i > 0) AppSpacing.gapMd,
      card,
    ],
  ],
);

/// The commercial department's station form, step by step.
List<InspectionStep> commercialSteps(
  TrafficCommercialStationData d,
  VoidCallback changed, {
  required bool sharedAnswered,
}) => [
  InspectionStep(
    title: 'Records',
    builder: (_) => _cards([
      TrafficChecklist(
        title: 'Booking Office',
        glyph: AppGlyphs.idCard,
        items: kBookingOfficeChecklist,
        data: d.bookingOffice,
        positiveLabel: 'Updated',
        negativeLabel: 'Not Updated',
        onChanged: changed,
      ),
      TrafficChecklist(
        title: 'Station Statistics (TM-34)',
        glyph: AppGlyphs.gauge,
        items: kStationStatisticsChecklist,
        data: d.stationStatistics,
        positiveLabel: 'Updated',
        negativeLabel: 'Not Updated',
        onChanged: changed,
      ),
      TrafficChecklist(
        title: 'Ticketing Data of TCR Office',
        glyph: AppGlyphs.list,
        items: kTcrCommercialChecklist,
        data: d.tcrOffice,
        positiveLabel: 'Updated',
        negativeLabel: 'Not Updated',
        onChanged: changed,
      ),
      TrafficChecklist(
        title: 'Station Mirror (T.M 35)',
        glyph: AppGlyphs.clipboardList,
        items: kStationMirrorChecklist,
        data: d.stationMirror,
        positiveLabel: 'Updated',
        negativeLabel: 'Not Updated',
        onChanged: changed,
      ),
    ]),
  ),
  InspectionStep(
    title: 'Parcels',
    builder: (_) => _cards([
      TrafficChecklist(
        title: 'Inward Parcel Office',
        glyph: AppGlyphs.arrowDown,
        items: kInwardParcelChecklist,
        data: d.inwardParcel,
        onChanged: changed,
      ),
      InspectionCard(
        title: 'Undelivered Parcels',
        glyph: AppGlyphs.hourglass,
        children: [
          TrafficYesNo(
            label: 'Undelivered parcels present?',
            value: d.undeliveredParcels,
            yesIsFault: true,
            onChanged: (v) {
              d.undeliveredParcels = v;
              changed();
            },
          ),
        ],
      ),
      TrafficChecklist(
        title: 'Outward Parcel Office',
        glyph: AppGlyphs.arrowUp,
        items: kOutwardParcelChecklist,
        data: d.outwardParcel,
        positiveLabel: 'Appropriate',
        negativeLabel: 'In-Appropriate',
        onChanged: changed,
      ),
      InspectionCard(
        title: 'Lost Property Office (LPO)',
        glyph: AppGlyphs.search,
        children: [
          TrafficYesNo(
            label: 'Weighment accuracy available?',
            value: d.lpoWeighmentAvailable,
            onChanged: (v) {
              d.lpoWeighmentAvailable = v;
              changed();
            },
          ),
          if (d.lpoWeighmentAvailable)
            InspectionTextInput(
              label: 'Number',
              value: d.lpoWeighmentNumber,
              onChanged: (v) {
                d.lpoWeighmentNumber = v;
                changed();
              },
            ),
          TrafficYesNo(
            label: 'Items duly evaluated by ICG and CMI?',
            value: d.lpoItemsEvaluated,
            onChanged: (v) {
              d.lpoItemsEvaluated = v;
              changed();
            },
          ),
          if (d.lpoItemsEvaluated)
            InspectionTextInput(
              label: 'Amount',
              value: d.lpoAmount,
              kind: InspectionTextKind.decimal,
              unit: 'Rs',
              onChanged: (v) {
                d.lpoAmount = v;
                changed();
              },
            )
          else
            TrafficDate(
              label: 'Date of Evaluation',
              value: d.lpoDateOfEvaluation,
              onChanged: (v) {
                d.lpoDateOfEvaluation = v;
                changed();
              },
            ),
          const InspectionSubhead('Last Auction of LPO Office'),
          InspectionTextInput(
            label: 'Amount',
            value: d.lpoLastAuctionAmount,
            kind: InspectionTextKind.decimal,
            unit: 'Rs',
            onChanged: (v) {
              d.lpoLastAuctionAmount = v;
              changed();
            },
          ),
          TrafficDate(
            label: 'Date',
            value: d.lpoLastAuctionDate,
            onChanged: (v) {
              d.lpoLastAuctionDate = v;
              changed();
            },
          ),
        ],
      ),
    ]),
  ),
  InspectionStep(
    title: 'Goods',
    builder: (_) => _cards([
      InspectionCard(
        title: 'Goods Office — Weighment Machine',
        glyph: AppGlyphs.gauge,
        children: [
          TrafficDate(
            label: 'Due Date',
            value: d.weighmentDueDate,
            onChanged: (v) {
              d.weighmentDueDate = v;
              changed();
            },
          ),
          TrafficDate(
            label: 'Next Date',
            value: d.weighmentNextDate,
            onChanged: (v) {
              d.weighmentNextDate = v;
              changed();
            },
          ),
        ],
      ),
      TrafficChecklist(
        title: 'Goods Office',
        glyph: AppGlyphs.truck,
        items: kGoodsOfficeChecklist,
        data: d.goodsOffice,
        onChanged: changed,
      ),
    ]),
  ),
  InspectionStep(
    title: 'Station',
    builder: (_) => _cards([
      TrafficChecklist(
        title: 'Vending Shops / Stalls',
        glyph: AppGlyphs.cup,
        items: kVendingStallsChecklist,
        data: d.vendingStalls,
        onChanged: changed,
      ),
      InspectionCard(
        title: 'Vendors',
        glyph: AppGlyphs.users,
        children: [
          TrafficYesNo(
            label: 'Selling of unauthorized items?',
            value: d.sellingUnauthorizedItems,
            yesIsFault: true,
            onChanged: (v) {
              d.sellingUnauthorizedItems = v;
              changed();
            },
          ),
          TrafficYesNo(
            label: 'Unauthorized vendor present at the station?',
            value: d.unauthorizedVendorPresent,
            yesIsFault: true,
            onChanged: (v) {
              d.unauthorizedVendorPresent = v;
              changed();
            },
          ),
        ],
      ),
      TrafficChecklist(
        title: "Station Master's Office",
        glyph: AppGlyphs.building,
        items: kStationMastersOfficeChecklist,
        data: d.stationMastersOffice,
        onChanged: changed,
      ),
      TrafficChecklist(
        title: 'General Cleanliness of the Station',
        glyph: AppGlyphs.station,
        items: kGeneralCleanlinessChecklist,
        data: d.generalCleanliness,
        positiveLabel: 'Satisfactory',
        negativeLabel: 'Not Satisfactory',
        onChanged: changed,
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (sharedAnswered) ...[
            const TrafficSharedNotice(),
            AppSpacing.gapSm,
          ],
          TrafficChecklist(
            title: 'Safety Equipment — Condition',
            note: 'Shared with the Transport department for this visit.',
            glyph: AppGlyphs.shieldCheck,
            items: kSafetyEquipmentConditionChecklist,
            data: d.safetyEquipmentCondition,
            positiveLabel: 'Satisfactory',
            negativeLabel: 'Not Satisfactory',
            enabled: !sharedAnswered,
            onChanged: changed,
          ),
        ],
      ),
      TrafficChecklist(
        title: 'Train(s) Present / Arrived at Station',
        glyph: AppGlyphs.train,
        items: kTrainPresentChecklist,
        data: d.trainsPresent,
        positiveLabel: 'Satisfactory',
        negativeLabel: 'Not Satisfactory',
        onChanged: changed,
      ),
      _remarks(d.finalRemarks, (v) {
        d.finalRemarks = v;
        changed();
      }),
    ]),
  ),
];

/// The transport department's station form, step by step.
List<InspectionStep> transportSteps(
  TrafficTransportStationData d,
  VoidCallback changed, {
  required bool sharedAnswered,
  required void Function(String code) addCautionOrder,
}) => [
  InspectionStep(
    title: 'Station Journal',
    builder: (_) => _cards([
      TrafficChecklist(
        title: 'Registers & Books',
        note: 'Staff present is recorded below.',
        glyph: AppGlyphs.clipboardList,
        items: kRegisterBooksChecklist
            .where((item) => item.key != 'staff_present')
            .toList(),
        data: d.stationJournal,
        positiveLabel: 'Updated',
        negativeLabel: 'Not Updated',
        onChanged: changed,
      ),
      InspectionCard(
        title: 'Staff & Systems',
        glyph: AppGlyphs.users,
        children: [
          TrafficYesNo(
            label: 'Staff present',
            value: d.stationJournal.of('staff_present').checked,
            onChanged: (v) {
              d.stationJournal.of('staff_present').checked = v;
              changed();
            },
          ),
          for (final (key, label, good, bad) in _systems)
            TrafficCheck(
              item: ChecklistItem(key: key, label: label),
              answer: d.stationJournal.of(key),
              positiveLabel: good,
              negativeLabel: bad,
              onChanged: changed,
            ),
        ],
      ),
    ]),
  ),
  InspectionStep(
    title: 'Ticketing & Orders',
    builder: (_) => _cards([
      TrafficChecklist(
        title: 'Ticketing Data of TCR Office',
        glyph: AppGlyphs.list,
        items: kTcrTransportBooksChecklist,
        data: d.tcrBooks,
        positiveLabel: 'Available',
        negativeLabel: 'Not Available',
        onChanged: changed,
      ),
      InspectionCard(
        title: 'Operating Document',
        glyph: AppGlyphs.fileEdit,
        children: [
          TrafficYesNo(
            label: 'Operating document issued?',
            value: d.operatingDocumentIssued,
            onChanged: (v) {
              d.operatingDocumentIssued = v;
              changed();
            },
          ),
          if (d.operatingDocumentIssued)
            InspectionTextInput(
              label: 'Total Issued',
              value: d.operatingDocumentTotalIssued,
              kind: InspectionTextKind.integer,
              onChanged: (v) {
                d.operatingDocumentTotalIssued = v;
                changed();
              },
            ),
        ],
      ),
      _CautionOrders(data: d, onChanged: changed, onAdd: addCautionOrder),
    ]),
  ),
  InspectionStep(
    title: 'Equipment & Points',
    builder: (_) => _cards([
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (sharedAnswered) ...[
            const TrafficSharedNotice(),
            AppSpacing.gapSm,
          ],
          TrafficChecklist(
            title: 'Staff Equipment — Condition',
            note: 'Shared with the Commercial department for this visit.',
            glyph: AppGlyphs.shieldCheck,
            items: kSafetyEquipmentConditionChecklist,
            data: d.staffEquipmentCondition,
            positiveLabel: 'Satisfactory',
            negativeLabel: 'Not Satisfactory',
            enabled: !sharedAnswered,
            onChanged: changed,
          ),
          AppSpacing.gapMd,
          TrafficChecklist(
            title: 'Fire Bucket',
            glyph: AppGlyphs.siren,
            items: const [
              ChecklistItem(key: 'fire_bucket_condition', label: 'Fire bucket'),
            ],
            data: d.staffEquipmentCondition,
            positiveLabel: 'Satisfactory',
            negativeLabel: 'Not Satisfactory',
            onChanged: changed,
          ),
        ],
      ),
      TrafficPoints(points: d.points, onChanged: changed),
    ]),
  ),
  InspectionStep(
    title: 'Siding',
    builder: (_) => _cards([
      InspectionCard(
        title: 'Siding',
        glyph: AppGlyphs.route,
        children: [
          TrafficYesNo(
            label: 'Damaged Vehicle for Mughalpura (DVM) stock present?',
            value: d.dvmStockPresent,
            onChanged: (v) {
              d.dvmStockPresent = v;
              changed();
            },
          ),
          TrafficYesNo(
            label: 'Fit stock present?',
            value: d.fitStockPresent,
            onChanged: (v) {
              d.fitStockPresent = v;
              changed();
            },
          ),
          InspectionChoiceInput(
            label: 'Platform level',
            options: const ['Upper', 'Lower'],
            value: d.platformLevel,
            onChanged: (v) {
              d.platformLevel = v;
              changed();
            },
          ),
          TrafficYesNo(
            label: 'Communication with staff?',
            value: d.communicationWithStaff,
            onChanged: (v) {
              d.communicationWithStaff = v;
              changed();
            },
          ),
        ],
      ),
      _remarks(d.finalRemarks, (v) {
        d.finalRemarks = v;
        changed();
      }),
    ]),
  ),
];

/// The caution orders issued, each with its total, and a field that adds
/// an order not on the list.
class _CautionOrders extends StatefulWidget {
  const _CautionOrders({
    required this.data,
    required this.onChanged,
    required this.onAdd,
  });

  final TrafficTransportStationData data;
  final VoidCallback onChanged;
  final void Function(String code) onAdd;

  @override
  State<_CautionOrders> createState() => _CautionOrdersState();
}

class _CautionOrdersState extends State<_CautionOrders> {
  String _code = '';
  int _field = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final orders = widget.data.cautionOrders;
    final standard = kCautionOrdersChecklist.map((e) => e.key).toSet();
    final items = [
      ...kCautionOrdersChecklist,
      for (final code in orders.answers.keys)
        if (!standard.contains(code))
          ChecklistItem(
            key: code,
            label: code,
            hasQuantity: true,
            quantityLabel: 'Total Issued',
          ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TrafficChecklist(
          title: 'Caution Order',
          note: 'Mark each OP issued and record how many.',
          glyph: AppGlyphs.triangleAlert,
          items: items,
          data: orders,
          positiveLabel: 'Issued',
          negativeLabel: 'Not issued',
          defaultChecked: false,
          onChanged: widget.onChanged,
        ),
        AppSpacing.gapMd,
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: InspectionTextInput(
                // A fresh field once an order is added.
                key: ValueKey(_field),
                label: 'Add another OP code',
                hint: 'e.g. OP-400',
                value: _code,
                onChanged: (typed) => _code = typed,
              ),
            ),
            AppSpacing.gapSm,
            AppTileButton(
              icon: const AppGlyphIcon(AppGlyphs.plus),
              tooltip: l10n.inspFormAddRow('order'),
              onPressed: () {
                final code = _code.trim();
                if (code.isEmpty) return;
                widget.onAdd(code);
                setState(() {
                  _code = '';
                  _field++;
                });
              },
            ),
          ],
        ),
      ],
    );
  }
}

/// The level crossings of the station, one step each.
List<InspectionStep> levelCrossingSteps(
  List<LevelCrossingRecord> records,
  VoidCallback changed,
) => [
  for (final (i, record) in records.indexed)
    InspectionStep(
      title: 'Crossing ${i + 1}',
      builder: (context) => _Crossing(
        key: ObjectKey(record),
        number: i + 1,
        record: record,
        last: i == records.length - 1,
        canRemove: records.length > 1,
        onChanged: changed,
        onAdd: () {
          records.add(LevelCrossingRecord());
          changed();
        },
        onRemove: () {
          records.remove(record);
          changed();
        },
      ),
    ),
];

class _Crossing extends StatelessWidget {
  const _Crossing({
    super.key,
    required this.number,
    required this.record,
    required this.last,
    required this.canRemove,
    required this.onChanged,
    required this.onAdd,
    required this.onRemove,
  });

  final int number;
  final LevelCrossingRecord record;
  final bool last;
  final bool canRemove;
  final VoidCallback onChanged;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    Widget select(
      String label,
      List<String> options,
      String value,
      void Function(String) set,
    ) => InspectionChoiceInput(
      label: label,
      options: options,
      value: value.isEmpty ? null : value,
      onChanged: (v) {
        set(v);
        onChanged();
      },
    );
    return _cards([
      InspectionCard(
        title: l10n.inspTrafficCrossing(number),
        glyph: AppGlyphs.triangleAlert,
        trailing: canRemove
            ? AppButton(
                label: l10n.inspFormRemoveRow,
                size: AppButtonSize.small,
                variant: AppButtonVariant.quietDanger,
                leadingGlyph: AppGlyphs.trash,
                expand: false,
                onPressed: onRemove,
              )
            : null,
        children: [
          InspectionSelectInput(
            label: 'Sponsoring Agency',
            options: kSponsoringAgencyOptions,
            value: record.sponsoringAgency.isEmpty
                ? null
                : record.sponsoringAgency,
            onChanged: (v) {
              record.sponsoringAgency = v;
              onChanged();
            },
          ),
          select(
            'Road Surface — Type',
            kRoadSurfaceTypeOptions,
            record.roadSurfaceType,
            (v) => record.roadSurfaceType = v,
          ),
          select(
            'Road Surface — Soiling',
            kRoadSurfaceSoilingOptions,
            record.roadSurfaceSoiling,
            (v) => record.roadSurfaceSoiling = v,
          ),
          select(
            'Communication Mechanism',
            kCommunicationMechanismOptions,
            record.communicationMechanism,
            (v) => record.communicationMechanism = v,
          ),
          InspectionTextInput(
            label: 'Jurisdiction',
            unit: 'm',
            kind: InspectionTextKind.decimal,
            value: record.jurisdictionMeters,
            onChanged: (v) {
              record.jurisdictionMeters = v;
              onChanged();
            },
          ),
          InspectionTextInput(
            label: 'Latitude',
            kind: InspectionTextKind.decimal,
            value: record.latitude,
            onChanged: (v) {
              record.latitude = v;
              onChanged();
            },
          ),
          InspectionTextInput(
            label: 'Longitude',
            kind: InspectionTextKind.decimal,
            value: record.longitude,
            onChanged: (v) {
              record.longitude = v;
              onChanged();
            },
          ),
        ],
      ),
      TrafficChecklist(
        title: 'Equipment',
        glyph: AppGlyphs.wrench,
        items: kLevelCrossingEquipmentChecklist,
        data: record.equipment,
        positiveLabel: 'Functional',
        negativeLabel: 'Not Functional',
        onChanged: onChanged,
      ),
      if (last)
        AppButton(
          label: l10n.inspTrafficAddCrossing,
          variant: AppButtonVariant.secondary,
          leadingGlyph: AppGlyphs.plus,
          onPressed: onAdd,
        ),
    ]);
  }
}
