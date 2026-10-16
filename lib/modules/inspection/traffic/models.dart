class ChecklistItem {
  final String key;
  final String label;

  /// Whether this item reveals an inline quantity field.
  final bool hasQuantity;
  final String quantityLabel;

  /// If true, the quantity field appears when the item IS checked
  /// (e.g. "Firefighting equipment: if Available, ask Quantity").
  /// If false, it appears when the item is UNCHECKED
  /// (e.g. "Hand Signal Lamp: if Not Functional, ask Quantity").
  final bool quantityWhenChecked;

  /// Optional key of an asset-master quantity this item's entered
  /// quantity must not exceed (BRD: "must not be greater than the
  /// quantity defined in asset").
  final String? maxQuantityFromAssetKey;

  const ChecklistItem({
    required this.key,
    required this.label,
    this.hasQuantity = false,
    this.quantityLabel = 'Quantity',
    this.quantityWhenChecked = true,
    this.maxQuantityFromAssetKey,
  });
}

/// Per-item answer: whether it's in the positive state, plus an optional
/// quantity and a free-text remark.
class ChecklistAnswer {
  bool checked;
  String quantity;
  String remarks;
  ChecklistAnswer({this.checked = true, this.quantity = '', this.remarks = ''});

  Map<String, dynamic> toJson() => {
    'checked': checked,
    if (quantity.isNotEmpty) 'quantity': quantity,
    if (remarks.isNotEmpty) 'remarks': remarks,
  };

  factory ChecklistAnswer.fromJson(Map<String, dynamic> json) =>
      ChecklistAnswer(
        checked: json['checked'] as bool? ?? true,
        quantity: json['quantity'] as String? ?? '',
        remarks: json['remarks'] as String? ?? '',
      );
}

/// A named group of checklist items rendered together under one heading
/// (mirrors a BRD "office" / sub-section, e.g. "Booking Office").
class ChecklistSectionConfig {
  final String title;
  final List<ChecklistItem> items;
  final String positiveLabel;
  final String negativeLabel;
  const ChecklistSectionConfig({
    required this.title,
    required this.items,
    this.positiveLabel = 'OK',
    this.negativeLabel = 'Issue',
  });
}

// ---------------------------------------------------------------------------
// SHARED / DE-DUPLICATED CHECKLISTS
// Declared once, reused everywhere the BRD repeats them.
// ---------------------------------------------------------------------------

/// BRD "Special Requirements for Traffic": Firefighting equipment, Medicine
/// / first aid, Fire bucket. The BRD's own note is "Add this in Station
/// Asset, above running rooms" — i.e. these are ASSET MASTER attributes
/// (captured once per station, not per inspection). They belong on the
/// Station Asset record, not repeated inside every inspection form.
/// See [kSafetyEquipmentAvailabilityChecklist] used there, and
/// [kSafetyEquipmentConditionChecklist] below for the separate, legitimate
/// per-visit CONDITION check.
const List<ChecklistItem> kSafetyEquipmentAvailabilityChecklist = [
  ChecklistItem(
    key: 'firefighting_equipment',
    label: 'Firefighting equipment',
    hasQuantity: true,
    quantityLabel: 'Quantity',
    quantityWhenChecked: true, // ask qty when Available
  ),
  ChecklistItem(key: 'medicine_first_aid', label: 'Medicine / first aid'),
  ChecklistItem(key: 'fire_bucket', label: 'Fire bucket'),
];

/// The BRD separately asks whether the SAME equipment is in satisfactory
/// CONDITION — once inside Commercial's "Station Master's Office" section
/// and again, verbatim, inside Transport's "Staff Equipment" section. That
/// second occurrence is a genuine duplicate inspection of the same physical
/// items by two departments. We keep ONE shared config (this list) so the
/// question is defined identically everywhere it's asked, and the
/// Commercial + Transport screens both pass a `readOnlyHint` when the other
/// department has already answered it during the same visit — see
/// `SharedSafetyConditionNotice` in checklist_widgets.dart.
const List<ChecklistItem> kSafetyEquipmentConditionChecklist = [
  ChecklistItem(
    key: 'firefighting_equipment_condition',
    label: 'Firefighting equipment',
  ),
  ChecklistItem(
    key: 'medicine_first_aid_condition',
    label: 'Medicine / first aid',
  ),
];

/// BRD "General cleanliness of the station" (Commercial → Station Master's
/// Office). Drinking Water / Firefighting equipment / Medicine are only
/// asked when the corresponding station-asset flags are set — handled via
/// `visibleIf` in the screen, not duplicated here.
const List<ChecklistItem> kGeneralCleanlinessChecklist = [
  ChecklistItem(key: 'platform_inspection', label: 'Platform inspection'),
  ChecklistItem(key: 'waiting_area', label: 'Waiting area'),
  ChecklistItem(key: 'washroom', label: 'Washroom'),
  ChecklistItem(key: 'drainage', label: 'Drainage'),
  ChecklistItem(key: 'lighting_fan', label: 'Lighting / Fan'),
];

/// BRD Transport "Station Journal" registers/books — seven near-identical
/// Updated / Not Updated rows collapsed into one multi-select checklist.
const List<ChecklistItem> kRegisterBooksChecklist = [
  ChecklistItem(key: 'working_rules', label: 'Working Rules'),
  ChecklistItem(key: 'inspection_register', label: 'Inspection Register'),
  ChecklistItem(key: 'train_register', label: 'Train Register'),
  ChecklistItem(key: 'accident_register', label: 'Accident'),
  ChecklistItem(key: 'er_register', label: 'E.R Register'),
  ChecklistItem(key: 'petty_repair', label: 'Petty repair'),
  ChecklistItem(key: 'engine_failure_book', label: 'Engine Failure Book'),
];

/// BRD Transport "Ticketing Data of TCR Office" (Transport variant) books.
const List<ChecklistItem> kTcrTransportBooksChecklist = [
  ChecklistItem(key: 'coad_books', label: 'Coad books'),
  ChecklistItem(key: 'number_exchange_book', label: 'Number exchange book'),
];

/// BRD "Caution Order" list under Transport → Ticketing Data of TCR Office.
/// Thirteen near-identical Issued/Not-Issued(+Total Issued) rows collapsed
/// into one checklist. Extra custom OP codes can still be added at runtime
/// (see `TrafficTransportStationForm._addCustomCautionOrder`).
const List<ChecklistItem> kCautionOrdersChecklist = [
  ChecklistItem(
    key: 'OP-354',
    label: 'OP-354',
    hasQuantity: true,
    quantityLabel: 'Total Issued',
  ),
  ChecklistItem(
    key: '354-A',
    label: '354-A',
    hasQuantity: true,
    quantityLabel: 'Total Issued',
  ),
  ChecklistItem(
    key: 'OP-373',
    label: 'OP-373',
    hasQuantity: true,
    quantityLabel: 'Total Issued',
  ),
  ChecklistItem(
    key: 'OP-371',
    label: 'OP-371',
    hasQuantity: true,
    quantityLabel: 'Total Issued',
  ),
  ChecklistItem(
    key: 'OP-374',
    label: 'OP-374',
    hasQuantity: true,
    quantityLabel: 'Total Issued',
  ),
  ChecklistItem(
    key: 'OP-238',
    label: 'OP-238',
    hasQuantity: true,
    quantityLabel: 'Total Issued',
  ),
  ChecklistItem(
    key: 'OP-239',
    label: 'OP-239',
    hasQuantity: true,
    quantityLabel: 'Total Issued',
  ),
  ChecklistItem(
    key: 'OP-122',
    label: 'OP-122',
    hasQuantity: true,
    quantityLabel: 'Total Issued',
  ),
  ChecklistItem(
    key: 'OP-128',
    label: 'OP-128',
    hasQuantity: true,
    quantityLabel: 'Total Issued',
  ),
  ChecklistItem(
    key: 'OP-129',
    label: 'OP-129',
    hasQuantity: true,
    quantityLabel: 'Total Issued',
  ),
  ChecklistItem(
    key: 'OP-460',
    label: 'OP-460',
    hasQuantity: true,
    quantityLabel: 'Total Issued',
  ),
  ChecklistItem(
    key: 'OP-38',
    label: 'OP-38',
    hasQuantity: true,
    quantityLabel: 'Total Issued',
  ),
  ChecklistItem(
    key: 'OP-39',
    label: 'OP-39',
    hasQuantity: true,
    quantityLabel: 'Total Issued',
  ),
];

/// BRD "Open for Level Crossing": seventeen Functional / Not Functional
/// (+ Not Functional Quantity, capped by the asset's defined quantity)
/// rows, collapsed into one checklist driven by this single config.
/// `maxQuantityFromAssetKey` lets the screen cap each field against the
/// matching quantity on the Level Crossing asset record.
const List<ChecklistItem> kLevelCrossingEquipmentChecklist = [
  ChecklistItem(
    key: 'hand_signal_lamp',
    label: 'Hand Signal Lamp',
    hasQuantity: true,
    quantityLabel: 'Not Functional Quantity',
    quantityWhenChecked: false,
    maxQuantityFromAssetKey: 'hand_signal_lamp',
  ),
  ChecklistItem(
    key: 'gate_signal_lamp',
    label: 'Gate Signal Lamp',
    hasQuantity: true,
    quantityLabel: 'Not Functional Quantity',
    quantityWhenChecked: false,
    maxQuantityFromAssetKey: 'gate_signal_lamp',
  ),
  ChecklistItem(
    key: 'hand_signal_flag_red',
    label: 'Hand Signal Flag (Red)',
    hasQuantity: true,
    quantityLabel: 'Not Functional Quantity',
    quantityWhenChecked: false,
    maxQuantityFromAssetKey: 'hand_signal_flag_red',
  ),
  ChecklistItem(
    key: 'hand_signal_flag_green',
    label: 'Hand Signal Flag (Green)',
    hasQuantity: true,
    quantityLabel: 'Not Functional Quantity',
    quantityWhenChecked: false,
    maxQuantityFromAssetKey: 'hand_signal_flag_green',
  ),
  ChecklistItem(
    key: 'detonators',
    label: 'Detonators',
    hasQuantity: true,
    quantityLabel: 'Not Functional Quantity',
    quantityWhenChecked: false,
    maxQuantityFromAssetKey: 'detonators',
  ),
  ChecklistItem(
    key: 'safety_chains',
    label: 'Safety Chains',
    hasQuantity: true,
    quantityLabel: 'Not Functional Quantity',
    quantityWhenChecked: false,
    maxQuantityFromAssetKey: 'safety_chains',
  ),
  ChecklistItem(
    key: 'red_disc',
    label: 'Red Disc.',
    hasQuantity: true,
    quantityLabel: 'Not Functional Quantity',
    quantityWhenChecked: false,
    maxQuantityFromAssetKey: 'red_disc',
  ),
  ChecklistItem(
    key: 'pad_locks',
    label: 'Pad Locks',
    hasQuantity: true,
    quantityLabel: 'Not Functional Quantity',
    quantityWhenChecked: false,
    maxQuantityFromAssetKey: 'pad_locks',
  ),
  ChecklistItem(
    key: 'rammer',
    label: 'Rammer',
    hasQuantity: true,
    quantityLabel: 'Not Functional Quantity',
    quantityWhenChecked: false,
    maxQuantityFromAssetKey: 'rammer',
  ),
  ChecklistItem(
    key: 'scrapper',
    label: 'Scrapper',
    hasQuantity: true,
    quantityLabel: 'Not Functional Quantity',
    quantityWhenChecked: false,
    maxQuantityFromAssetKey: 'scrapper',
  ),
  ChecklistItem(
    key: 'wooden_stand',
    label: 'Wooden Stand',
    hasQuantity: true,
    quantityLabel: 'Not Functional Quantity',
    quantityWhenChecked: false,
    maxQuantityFromAssetKey: 'wooden_stand',
  ),
  ChecklistItem(
    key: 'dole_iron_for_water',
    label: 'Dole Iron For Water',
    hasQuantity: true,
    quantityLabel: 'Not Functional Quantity',
    quantityWhenChecked: false,
    maxQuantityFromAssetKey: 'dole_iron_for_water',
  ),
  ChecklistItem(
    key: 'pain_iron_mortor',
    label: 'Pain Iron Mortor',
    hasQuantity: true,
    quantityLabel: 'Not Functional Quantity',
    quantityWhenChecked: false,
    maxQuantityFromAssetKey: 'pain_iron_mortor',
  ),
  ChecklistItem(
    key: 'pick_axe',
    label: 'Pick Axe',
    hasQuantity: true,
    quantityLabel: 'Not Functional Quantity',
    quantityWhenChecked: false,
    maxQuantityFromAssetKey: 'pick_axe',
  ),
  ChecklistItem(
    key: 'inspection_book',
    label: 'Inspection Book',
    hasQuantity: true,
    quantityLabel: 'Not Functional Quantity',
    quantityWhenChecked: false,
    maxQuantityFromAssetKey: 'inspection_book',
  ),
  ChecklistItem(
    key: 'complaint_book',
    label: 'Complaint Book',
    hasQuantity: true,
    quantityLabel: 'Not Functional Quantity',
    quantityWhenChecked: false,
    maxQuantityFromAssetKey: 'complaint_book',
  ),
  ChecklistItem(
    key: 'spade',
    label: 'Spade',
    hasQuantity: true,
    quantityLabel: 'Not Functional Quantity',
    quantityWhenChecked: false,
    maxQuantityFromAssetKey: 'spade',
  ),
];

/// BRD Commercial "Booking Office".
const List<ChecklistItem> kBookingOfficeChecklist = [
  ChecklistItem(key: 'ticketing_proceeding', label: 'Ticketing Proceeding'),
  ChecklistItem(key: 'dtc_book', label: 'DTC book'),
  ChecklistItem(key: 'cash_handling', label: 'Cash handling'),
  ChecklistItem(key: 'rabta_system', label: 'RABTA System'),
  ChecklistItem(key: 'cash_book_register', label: 'Cash Book/Register entries'),
  ChecklistItem(key: 'fare_on_pcts', label: 'Fare on PCTs'),
  ChecklistItem(key: 'fare_on_fare_board', label: 'Fare on fare board'),
  ChecklistItem(key: 'ticket_tube', label: 'Ticket tube'),
];

/// BRD Commercial "Station Statistics (TM-34)".
const List<ChecklistItem> kStationStatisticsChecklist = [
  ChecklistItem(key: 'earning', label: 'Earning'),
  ChecklistItem(key: 'passenger_coaching', label: 'Passenger (Coaching)'),
  ChecklistItem(key: 'parcel_luggage', label: 'Parcel/luggage'),
  ChecklistItem(key: 'goods_earning', label: 'Goods Earning'),
  ChecklistItem(key: 'misc_earning', label: 'Miscellaneous Earning'),
  ChecklistItem(key: 'misc_expenditure', label: 'Miscellaneous Expenditure'),
];

/// BRD Commercial "Ticketing Data of TCR Office" (Commercial variant).
const List<ChecklistItem> kTcrCommercialChecklist = [
  ChecklistItem(key: 'pcts_collected', label: 'PCTs collected'),
  ChecklistItem(key: 'efts_collected', label: 'EFTs collected'),
  ChecklistItem(
    key: 'passengers_per_month',
    label: 'No of passengers/per month',
  ),
  ChecklistItem(key: 'refund_management', label: 'Refund management'),
];

/// BRD Commercial "Station Mirror (T.M 35)".
const List<ChecklistItem> kStationMirrorChecklist = [
  ChecklistItem(key: 'daily_earning', label: 'Daily Earning'),
  ChecklistItem(key: 'passenger', label: 'Passenger'),
  ChecklistItem(key: 'parcel', label: 'Parcel'),
  ChecklistItem(key: 'goods', label: 'Goods'),
  ChecklistItem(key: 'demurrage_wharfage', label: 'Demurrage / wharfage'),
  ChecklistItem(key: 'panels_received', label: 'Number of panels received'),
  ChecklistItem(key: 'parcel_delivered', label: 'Number of Parcel delivered'),
  ChecklistItem(key: 'misc_earnings', label: 'Miscellaneous Earnings'),
  ChecklistItem(key: 'misc_expenditures', label: 'Miscellaneous Expenditures'),
];

/// BRD Commercial "Inward Parcel Office".
const List<ChecklistItem> kInwardParcelChecklist = [
  ChecklistItem(
    key: 'luggage_proper_invoice',
    label: 'Luggage / Parcel against proper invoice',
  ),
  ChecklistItem(key: 'delivery_book', label: 'Delivery Book'),
  ChecklistItem(key: 'condition_of_parcel', label: 'Condition of parcel'),
  ChecklistItem(
    key: 'delivery_issuance_procedure',
    label: 'Procedure of delivery issuance',
  ),
  ChecklistItem(key: 'signature_of_consignee', label: 'Signature of consignee'),
];

/// BRD Commercial "Outward Parcel Office".
const List<ChecklistItem> kOutwardParcelChecklist = [
  ChecklistItem(key: 'weighment_accuracy_outward', label: 'Weighment accuracy'),
  ChecklistItem(key: 'invoice_preparation', label: 'Invoice Preparation'),
  ChecklistItem(key: 'condition_of_packages', label: 'Condition of packages'),
  ChecklistItem(key: 'sealing_of_consignment', label: 'Sealing of consignment'),
];

/// BRD Commercial "Goods Office" (the on/off checklist part; weighment
/// machine due/next dates and siding/vending are handled separately).
const List<ChecklistItem> kGoodsOfficeChecklist = [
  ChecklistItem(key: 'siding_operation', label: 'Siding Operation'),
  ChecklistItem(key: 'yard_management', label: 'Yard Management'),
  ChecklistItem(key: 'booking_procedure', label: 'Booking procedure'),
  ChecklistItem(key: 'demurrage_wharfage_goods', label: 'Demurrage/wharfage'),
  ChecklistItem(key: 'delivery_books_goods', label: 'Delivery books'),
  ChecklistItem(key: 'tally_books', label: 'Tally Books'),
  ChecklistItem(key: 'wagon_condition_record', label: 'Wagon Condition Record'),
];

/// BRD Commercial "Vending shops / stalls".
const List<ChecklistItem> kVendingStallsChecklist = [
  ChecklistItem(
    key: 'license_agreement',
    label: 'License agreement of stall / vendor',
  ),
  ChecklistItem(key: 'medical_card', label: 'Medical Card of vendor'),
  ChecklistItem(
    key: 'approved_rate_list',
    label: 'Display of approved rate list',
  ),
  ChecklistItem(
    key: 'hygiene_quality',
    label: 'Hygiene and Quality of consumable items',
  ),
];

/// BRD Commercial "Station Master's Office" (top part).
const List<ChecklistItem> kStationMastersOfficeChecklist = [
  ChecklistItem(key: 'staff_present', label: 'Staff Present'),
  ChecklistItem(key: 'public_complaint_book', label: 'Public complaint book'),
  ChecklistItem(key: 'station_record', label: 'Station Record'),
];

/// BRD Commercial "Train(s) Present/Arrived at Station".
const List<ChecklistItem> kTrainPresentChecklist = [
  ChecklistItem(key: 'condition_of_rake', label: 'Condition of rake inspected'),
  ChecklistItem(key: 'electric_fans_lights', label: 'Electric fans/Lights'),
  ChecklistItem(
    key: 'doors_windows_berths_seats',
    label: 'Condition of doors/windows/berths/seats',
  ),
  ChecklistItem(
    key: 'washrooms_inspected',
    label: 'Condition of washrooms inspected',
  ),
  ChecklistItem(key: 'janitorial_services', label: 'Janitorial services'),
];

// ---------------------------------------------------------------------------
// Form data holders
// ---------------------------------------------------------------------------

/// Which department opened the inspection — used only to decide which
/// screen to show; the underlying station identity is shared.
class ChecklistFormData {
  final Map<String, ChecklistAnswer> answers = {};

  /// Returns the answer for [key], creating it on first access.
  /// [defaultChecked] controls the initial state — most checklists default
  /// to true ("OK by default, flag the exceptions"), but a few (e.g.
  /// Caution Orders — most are NOT issued) read more naturally starting
  /// unchecked, so the inspector selects the ones that DO apply.
  ChecklistAnswer of(String key, {bool defaultChecked = true}) =>
      answers.putIfAbsent(key, () => ChecklistAnswer(checked: defaultChecked));

  void markAll(List<ChecklistItem> items, {required bool checked}) {
    for (final item in items) {
      of(item.key).checked = checked;
    }
  }

  int issueCountFor(List<ChecklistItem> items) => items
      .where((i) => answers[i.key] != null && !answers[i.key]!.checked)
      .length;

  Map<String, dynamic> toJson() =>
      answers.map((k, v) => MapEntry(k, v.toJson()));
}

/// A single ad-hoc "Point" on the station (BRD: "Ask this for each point on
/// the station" — implies a variable number of points, so this is a
/// growable list rather than a fixed field).
class StationPointEntry {
  String label;
  bool workingProperly;
  StationPointEntry({required this.label, this.workingProperly = true});
}

/// A single Level Crossing record. The BRD's "Add" button at the bottom of
/// the Level Crossing form implies a station can have more than one level
/// crossing, so — consistent with how Station Assets are handled elsewhere
/// in Footplate — this is modelled as a repeatable list, not a singleton.
class LevelCrossingRecord {
  String id = 'traffic-lc-${DateTime.now().millisecondsSinceEpoch}';
  String
  sponsoringAgency; // District Administration / Local Government / Provincial Government / Highway Department
  String roadSurfaceType; // Metal / Non-Metal
  String roadSurfaceSoiling; // Soiling / Non-Soiling
  String communicationMechanism; // Phone / Bell / Wireless / Nothing
  final ChecklistFormData equipment = ChecklistFormData();
  String jurisdictionMeters;
  String latitude;
  String longitude;

  LevelCrossingRecord({
    this.sponsoringAgency = '',
    this.roadSurfaceType = '',
    this.roadSurfaceSoiling = '',
    this.communicationMechanism = '',
    this.jurisdictionMeters = '',
    this.latitude = '',
    this.longitude = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'sponsoringAgency': sponsoringAgency,
    'roadSurfaceType': roadSurfaceType,
    'roadSurfaceSoiling': roadSurfaceSoiling,
    'communicationMechanism': communicationMechanism,
    'equipment': equipment.toJson(),
    'jurisdictionMeters': jurisdictionMeters,
    'latitude': latitude,
    'longitude': longitude,
  };

  factory LevelCrossingRecord.fromJson(Map<String, dynamic> json) {
    final record = LevelCrossingRecord(
      sponsoringAgency: json['sponsoringAgency'] ?? '',
      roadSurfaceType: json['roadSurfaceType'] ?? '',
      roadSurfaceSoiling: json['roadSurfaceSoiling'] ?? '',
      communicationMechanism: json['communicationMechanism'] ?? '',
      jurisdictionMeters: json['jurisdictionMeters'] ?? '',
      latitude: json['latitude'] ?? '',
      longitude: json['longitude'] ?? '',
    );
    record.id = json['id'] as String? ?? record.id;
    if (json['equipment'] is Map) {
      json['equipment'].forEach((k, v) {
        record.equipment.answers[k.toString()] = ChecklistAnswer.fromJson(
          Map<String, dynamic>.from(v),
        );
      });
    }
    return record;
  }
}

/// Root data for the Commercial-department Station form.
class TrafficCommercialStationData {
  String id = 'traffic-commercial-${DateTime.now().millisecondsSinceEpoch}';
  final ChecklistFormData bookingOffice = ChecklistFormData();
  final ChecklistFormData stationStatistics = ChecklistFormData();
  final ChecklistFormData tcrOffice = ChecklistFormData();
  final ChecklistFormData stationMirror = ChecklistFormData();
  final ChecklistFormData inwardParcel = ChecklistFormData();
  final ChecklistFormData outwardParcel = ChecklistFormData();
  final ChecklistFormData goodsOffice = ChecklistFormData();
  final ChecklistFormData vendingStalls = ChecklistFormData();
  final ChecklistFormData stationMastersOffice = ChecklistFormData();
  final ChecklistFormData generalCleanliness = ChecklistFormData();
  final ChecklistFormData safetyEquipmentCondition = ChecklistFormData();
  final ChecklistFormData trainsPresent = ChecklistFormData();

  // Lost Property Office — has its own branching (Yes/No + Amount/Date),
  // not a good fit for the generic checklist.
  bool lpoWeighmentAvailable = false;
  String lpoWeighmentNumber = '';
  bool lpoItemsEvaluated = false;
  String lpoAmount = '';
  String lpoDateOfEvaluation = '';
  String lpoLastAuctionAmount = '';
  String lpoLastAuctionDate = '';

  // Goods Office weighment machine dates.
  String weighmentDueDate = '';
  String weighmentNextDate = '';

  // Inward Parcel Office branching.
  bool undeliveredParcels = false;

  // Vending shops branching.
  bool sellingUnauthorizedItems = false;
  bool unauthorizedVendorPresent = false;

  String finalRemarks = '';

  Map<String, dynamic> toJson() => {
    'id': id,
    'bookingOffice': bookingOffice.toJson(),
    'stationStatistics': stationStatistics.toJson(),
    'tcrOffice': tcrOffice.toJson(),
    'stationMirror': stationMirror.toJson(),
    'inwardParcel': inwardParcel.toJson(),
    'outwardParcel': outwardParcel.toJson(),
    'goodsOffice': goodsOffice.toJson(),
    'vendingStalls': vendingStalls.toJson(),
    'stationMastersOffice': stationMastersOffice.toJson(),
    'generalCleanliness': generalCleanliness.toJson(),
    'safetyEquipmentCondition': safetyEquipmentCondition.toJson(),
    'trainsPresent': trainsPresent.toJson(),
    'lpoWeighmentAvailable': lpoWeighmentAvailable,
    'lpoWeighmentNumber': lpoWeighmentNumber,
    'lpoItemsEvaluated': lpoItemsEvaluated,
    'lpoAmount': lpoAmount,
    'lpoDateOfEvaluation': lpoDateOfEvaluation,
    'lpoLastAuctionAmount': lpoLastAuctionAmount,
    'lpoLastAuctionDate': lpoLastAuctionDate,
    'weighmentDueDate': weighmentDueDate,
    'weighmentNextDate': weighmentNextDate,
    'undeliveredParcels': undeliveredParcels,
    'sellingUnauthorizedItems': sellingUnauthorizedItems,
    'unauthorizedVendorPresent': unauthorizedVendorPresent,
    'finalRemarks': finalRemarks,
  };

  void fromJson(Map<String, dynamic> json) {
    id = json['id'] as String? ?? id;
    _restoreChecklist(bookingOffice, json['bookingOffice']);
    _restoreChecklist(stationStatistics, json['stationStatistics']);
    _restoreChecklist(tcrOffice, json['tcrOffice']);
    _restoreChecklist(stationMirror, json['stationMirror']);
    _restoreChecklist(inwardParcel, json['inwardParcel']);
    _restoreChecklist(outwardParcel, json['outwardParcel']);
    _restoreChecklist(goodsOffice, json['goodsOffice']);
    _restoreChecklist(vendingStalls, json['vendingStalls']);
    _restoreChecklist(stationMastersOffice, json['stationMastersOffice']);
    _restoreChecklist(generalCleanliness, json['generalCleanliness']);
    _restoreChecklist(
      safetyEquipmentCondition,
      json['safetyEquipmentCondition'],
    );
    _restoreChecklist(trainsPresent, json['trainsPresent']);
    lpoWeighmentAvailable = json['lpoWeighmentAvailable'] ?? false;
    lpoWeighmentNumber = json['lpoWeighmentNumber'] ?? '';
    lpoItemsEvaluated = json['lpoItemsEvaluated'] ?? false;
    lpoAmount = json['lpoAmount'] ?? '';
    lpoDateOfEvaluation = json['lpoDateOfEvaluation'] ?? '';
    lpoLastAuctionAmount = json['lpoLastAuctionAmount'] ?? '';
    lpoLastAuctionDate = json['lpoLastAuctionDate'] ?? '';
    weighmentDueDate = json['weighmentDueDate'] ?? '';
    weighmentNextDate = json['weighmentNextDate'] ?? '';
    undeliveredParcels = json['undeliveredParcels'] ?? false;
    sellingUnauthorizedItems = json['sellingUnauthorizedItems'] ?? false;
    unauthorizedVendorPresent = json['unauthorizedVendorPresent'] ?? false;
    finalRemarks = json['finalRemarks'] ?? '';
  }

  void _restoreChecklist(ChecklistFormData data, dynamic json) {
    if (json is Map) {
      json.forEach((k, v) {
        data.answers[k.toString()] = ChecklistAnswer.fromJson(
          Map<String, dynamic>.from(v),
        );
      });
    }
  }
}

/// Root data for the Transport-department Station form.
class TrafficTransportStationData {
  String id = 'traffic-transport-${DateTime.now().millisecondsSinceEpoch}';
  final ChecklistFormData stationJournal = ChecklistFormData();
  final ChecklistFormData tcrBooks = ChecklistFormData();
  final ChecklistFormData cautionOrders = ChecklistFormData();
  final ChecklistFormData staffEquipmentCondition = ChecklistFormData();

  bool operatingDocumentIssued = false;
  String operatingDocumentTotalIssued = '';

  // "Ask this for each point on the station" — growable list.
  final List<StationPointEntry> points = [];

  // Siding.
  bool dvmStockPresent = false;
  bool fitStockPresent = false;
  String platformLevel = 'Upper'; // Upper / Lower
  bool communicationWithStaff = true;

  String finalRemarks = '';

  Map<String, dynamic> toJson() => {
    'id': id,
    'stationJournal': stationJournal.toJson(),
    'tcrBooks': tcrBooks.toJson(),
    'cautionOrders': cautionOrders.toJson(),
    'staffEquipmentCondition': staffEquipmentCondition.toJson(),
    'operatingDocumentIssued': operatingDocumentIssued,
    'operatingDocumentTotalIssued': operatingDocumentTotalIssued,
    'points': points
        .map((p) => {'label': p.label, 'workingProperly': p.workingProperly})
        .toList(),
    'dvmStockPresent': dvmStockPresent,
    'fitStockPresent': fitStockPresent,
    'platformLevel': platformLevel,
    'communicationWithStaff': communicationWithStaff,
    'finalRemarks': finalRemarks,
  };

  void fromJson(Map<String, dynamic> json) {
    id = json['id'] as String? ?? id;
    _restoreChecklist(stationJournal, json['stationJournal']);
    _restoreChecklist(tcrBooks, json['tcrBooks']);
    _restoreChecklist(cautionOrders, json['cautionOrders']);
    _restoreChecklist(staffEquipmentCondition, json['staffEquipmentCondition']);
    operatingDocumentIssued = json['operatingDocumentIssued'] ?? false;
    operatingDocumentTotalIssued = json['operatingDocumentTotalIssued'] ?? '';
    if (json['points'] is List) {
      points.clear();
      for (var p in json['points']) {
        points.add(
          StationPointEntry(
            label: p['label'] ?? '',
            workingProperly: p['workingProperly'] ?? true,
          ),
        );
      }
    }
    dvmStockPresent = json['dvmStockPresent'] ?? false;
    fitStockPresent = json['fitStockPresent'] ?? false;
    platformLevel = json['platformLevel'] ?? 'Upper';
    communicationWithStaff = json['communicationWithStaff'] ?? true;
    finalRemarks = json['finalRemarks'] ?? '';
  }

  void _restoreChecklist(ChecklistFormData data, dynamic json) {
    if (json is Map) {
      json.forEach((k, v) {
        data.answers[k.toString()] = ChecklistAnswer.fromJson(
          Map<String, dynamic>.from(v),
        );
      });
    }
  }
}
