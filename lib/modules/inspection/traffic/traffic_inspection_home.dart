import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/storage/storage_service.dart';
import 'package:railway_hrms/modules/inspection/traffic/level_crossing_form.dart';
import 'package:railway_hrms/modules/inspection/traffic/models.dart';
import 'package:railway_hrms/modules/inspection/traffic/traffic_commercial_station_form.dart';
import 'package:railway_hrms/modules/inspection/traffic/traffic_transport_station_form.dart';

enum _FormKind { commercialStation, transportStation, levelCrossing }

/// Entry point for the Traffic inspection module. Lets the inspector pick
/// which department + form they're conducting, then shows that form.
///
/// The Commercial and Transport station forms both ask about the same
/// physical safety equipment CONDITION (Firefighting equipment, Medicine /
/// first aid) for the same station visit. Rather than let each form ask
/// independently — which was the literal duplication in the source BRD —
/// this screen owns that answer once per station visit and passes a
/// `safetyConditionAlreadyRecordedByOtherDept` flag down so the second
/// department to open the inspection sees it read-only instead of asking
/// again from scratch.
class TrafficInspectionHome extends StatefulWidget {
  final String stationName;
  final String? resumeId;
  const TrafficInspectionHome({
    super.key,
    required this.stationName,
    this.resumeId,
  });

  @override
  State<TrafficInspectionHome> createState() => _TrafficInspectionHomeState();
}

class _TrafficInspectionHomeState extends State<TrafficInspectionHome> {
  String _id = 'traffic-${DateTime.now().millisecondsSinceEpoch}';
  final TrafficCommercialStationData _commercialData =
      TrafficCommercialStationData();
  final TrafficTransportStationData _transportData =
      TrafficTransportStationData();
  final List<LevelCrossingRecord> _levelCrossingRecords = [];

  _FormKind? _openForm;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.resumeId != null) {
      _id = widget.resumeId!;
      _restoreDraft();
    } else {
      _isLoading = false;
    }
  }

  Future<void> _restoreDraft() async {
    final raw = await StorageService.getInspectionDraft(_id);
    if (raw != null && raw.isNotEmpty) {
      try {
        final payload = jsonDecode(raw) as Map<String, dynamic>;
        setState(() {
          _commercialData.fromJson(payload['commercial'] ?? {});
          _transportData.fromJson(payload['transport'] ?? {});
          if (payload['levelCrossings'] is List) {
            _levelCrossingRecords.clear();
            for (var lc in payload['levelCrossings']) {
              _levelCrossingRecords.add(LevelCrossingRecord.fromJson(lc));
            }
          }
        });
      } catch (e) {
        debugPrint('Error restoring traffic draft: $e');
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _onChanged() {
    if (!mounted) return;
    setState(() {});
    _persistDraft();
  }

  Future<void> _persistDraft() async {
    final payload = {
      'id': _id,
      'stationName': widget.stationName,
      'commercial': _commercialData.toJson(),
      'transport': _transportData.toJson(),
      'levelCrossings': _levelCrossingRecords.map((r) => r.toJson()).toList(),
      'type': 'traffic',
      'timestamp': DateTime.now().toIso8601String(),
    };
    await StorageService.saveInspectionDraft(_id, jsonEncode(payload));

    // Also save a record for the dashboard list
    await StorageService.saveInspectionRecord({
      'id': _id,
      'status': 'in_progress',
      'train': '${widget.stationName} (Traffic)',
      'date': DateTime.now().toIso8601String(),
      'payload': payload,
    });
  }

  bool get _safetyConditionAnsweredByCommercial =>
      _commercialData.safetyEquipmentCondition.answers.isNotEmpty;
  bool get _safetyConditionAnsweredByTransport =>
      _transportData.staffEquipmentCondition.answers.isNotEmpty;

  void _saveDraft() async {
    await _persistDraft();
    if (mounted) {
      showAppMessage(
        context,
        'Traffic inspection draft saved',
        tone: AppDialogTone.success,
      );
    }
  }

  void _submit(String formName) async {
    final payload = {
      'id': _id,
      'stationName': widget.stationName,
      'commercial': _commercialData.toJson(),
      'transport': _transportData.toJson(),
      'levelCrossings': _levelCrossingRecords.map((r) => r.toJson()).toList(),
      'type': 'traffic',
    };

    await StorageService.saveInspectionRecord({
      'id': _id,
      'status': 'pending',
      'train': '${widget.stationName} (Traffic)',
      'date': DateTime.now().toIso8601String(),
      'payload': payload,
    });

    await StorageService.clearInspectionDraft(_id);

    if (mounted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: Colors.green, size: 40),
          title: const Text('Inspection Submitted'),
          content: Text('$formName has been submitted for review.'),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Back to dashboard
              },
              child: const Text('Done'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(body: AppLoader.page());
    }
    if (_openForm == null) return _buildPicker(context);

    switch (_openForm!) {
      case _FormKind.commercialStation:
        return Scaffold(
          appBar: AppBar(
            title: const Text('Traffic (Commercial) — Station'),
            leading: _backButton(),
          ),
          body: TrafficCommercialStationForm(
            stationName: widget.stationName,
            data: _commercialData,
            onChanged: _onChanged,
            onSaveDraft: _saveDraft,
            onSubmit: () =>
                _submit('Traffic (Commercial) — Station inspection'),
            safetyConditionAlreadyRecordedByOtherDept:
                !_safetyConditionAnsweredByCommercial &&
                _safetyConditionAnsweredByTransport,
          ),
        );
      case _FormKind.transportStation:
        return Scaffold(
          appBar: AppBar(
            title: const Text('Traffic (Transport) — Station'),
            leading: _backButton(),
          ),
          body: TrafficTransportStationForm(
            stationName: widget.stationName,
            data: _transportData,
            onChanged: _onChanged,
            onSaveDraft: _saveDraft,
            onSubmit: () => _submit('Traffic (Transport) — Station inspection'),
            safetyConditionAlreadyRecordedByOtherDept:
                !_safetyConditionAnsweredByTransport &&
                _safetyConditionAnsweredByCommercial,
          ),
        );
      case _FormKind.levelCrossing:
        return Scaffold(
          appBar: AppBar(
            title: const Text('Traffic (Transport) — Level Crossing'),
            leading: _backButton(),
          ),
          body: LevelCrossingListScreen(
            stationName: widget.stationName,
            records: _levelCrossingRecords,
            onChanged: _onChanged,
            onSaveDraft: _saveDraft,
            onSubmit: () => _submit('Level Crossing inspection'),
          ),
        );
    }
  }

  Widget _backButton() => Center(
    child: AppBackButton(onPressed: () => setState(() => _openForm = null)),
  );

  Widget _buildPicker(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Traffic Inspection')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            widget.stationName,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Choose the form to conduct.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          _pickerCard(
            context,
            title: 'Traffic (Commercial) — Station',
            subtitle:
                'Booking Office, Statistics, Parcel & Goods Offices, Vending, Station Master\'s Office',
            icon: Icons.storefront,
            onTap: () =>
                setState(() => _openForm = _FormKind.commercialStation),
          ),
          _pickerCard(
            context,
            title: 'Traffic (Transport) — Station',
            subtitle:
                'Registers, Ticketing (TCR), Caution Orders, Staff Equipment, Points, Siding',
            icon: Icons.alt_route,
            onTap: () => setState(() => _openForm = _FormKind.transportStation),
          ),
          _pickerCard(
            context,
            title: 'Traffic (Transport) — Level Crossing',
            subtitle: 'One or more level crossings for this station',
            icon: Icons.fence,
            onTap: () => setState(() => _openForm = _FormKind.levelCrossing),
          ),
        ],
      ),
    );
  }

  Widget _pickerCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: scheme.primaryContainer,
          child: Icon(icon, color: scheme.onPrimaryContainer),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
