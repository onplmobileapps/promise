import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/di/service_locator.dart';
import 'package:railway_hrms/core/storage/storage_service.dart';
import 'package:railway_hrms/modules/inspection/data/inspection_repository.dart';
import 'package:railway_hrms/modules/inspection/data/user_stations.dart';
import 'package:railway_hrms/modules/inspection/shared/widgets/inspection_fields.dart';

/// A station by name: picked from those the employee inspects, or typed
/// where they can't be had, as with no connection and none kept yet.
class InspectionStationInput extends StatefulWidget {
  const InspectionStationInput({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.note,
  });

  final String label;
  final String? value;
  final ValueChanged<String> onChanged;
  final String? note;

  @override
  State<InspectionStationInput> createState() => _InspectionStationInputState();
}

class _InspectionStationInputState extends State<InspectionStationInput> {
  /// The employee's stations, asked for once however many fields show them.
  static Future<List<String>>? _asked;

  List<String> _names = const [];

  @override
  void initState() {
    super.initState();
    final asked = _asked ??= _load();
    asked.then((names) {
      // None to be had: asked again next time, in case it can be then.
      if (names.isEmpty && identical(_asked, asked)) _asked = null;
      if (mounted) setState(() => _names = names);
    });
  }

  static Future<List<String>> _load() async {
    if (!sl.isRegistered<InspectionRepository>()) return const [];
    final user = (await StorageService.getUser())?.user;
    final loaded = await UserStations.load(
      sl<InspectionRepository>(),
      section: user?.section,
    );
    return [for (final station in loaded.stations) station.displayLabel];
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.value;
    if (_names.isEmpty) {
      return InspectionTextInput(
        label: widget.label,
        value: value,
        glyph: AppGlyphs.station,
        note: widget.note,
        onChanged: widget.onChanged,
      );
    }
    return InspectionSelectInput(
      label: widget.label,
      options: [
        // A name kept from before, among those to pick from.
        if (value != null && value.isNotEmpty && !_names.contains(value)) value,
        ..._names,
      ],
      value: value,
      glyph: AppGlyphs.station,
      note: widget.note,
      onChanged: widget.onChanged,
    );
  }
}
