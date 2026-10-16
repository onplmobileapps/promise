import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/modules/inspection/electrical/models/electrical_inspection_catalog.dart';
import 'package:railway_hrms/modules/inspection/electrical/screens/electrical_asset_form_screen.dart';
import 'package:railway_hrms/modules/inspection/electrical/services/electrical_inspection_draft_service.dart';

class ElectricalInspectionHomeScreen extends StatefulWidget {
  const ElectricalInspectionHomeScreen({super.key});

  @override
  State<ElectricalInspectionHomeScreen> createState() =>
      _ElectricalInspectionHomeScreenState();
}

class _ElectricalInspectionHomeScreenState
    extends State<ElectricalInspectionHomeScreen> {
  String? _department;
  String? _subDepartment;

  @override
  void initState() {
    super.initState();
    _department = ElectricalInspectionCatalog.table.keys.first;
  }

  void _openAsset(String asset, Map<String, dynamic> assetData) {
    final fields = ElectricalInspectionCatalog.resolveFields(
      _department!,
      _subDepartment!,
      asset,
      assetData,
    );

    if (fields == null) {
      // Handle custom forms if needed in the future
      return;
    }

    final formId = 'electrical_${_department}_${_subDepartment}_$asset'
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ElectricalAssetFormScreen(
          department: _department!,
          subDepartment: _subDepartment!,
          asset: asset,
          fields: fields,
          formId: formId,
          assetData: assetData,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subDepartments = ElectricalInspectionCatalog.table[_department]!.keys
        .toList();
    _subDepartment ??= subDepartments.first;
    final assets =
        ElectricalInspectionCatalog.table[_department]![_subDepartment]!;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Electrical Inspection Forms'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'New Inspection'),
              Tab(text: 'My Drafts / History'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildPicker(subDepartments, assets),
            const _ElectricalHistoryTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildPicker(List<String> subDepartments, List<String> assets) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Department', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: ElectricalInspectionCatalog.table.keys.map((d) {
            return ChoiceChip(
              label: Text(d),
              selected: _department == d,
              onSelected: (_) => setState(() {
                _department = d;
                _subDepartment = null;
              }),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        const Text(
          'Sub-department',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: subDepartments.map((s) {
            return ChoiceChip(
              label: Text(s),
              selected: _subDepartment == s,
              onSelected: (_) => setState(() => _subDepartment = s),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        const Text('Asset', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        ...assets.map(
          (asset) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const Icon(Icons.electrical_services_outlined),
              title: Text(asset),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showAssetDataDialog(asset),
            ),
          ),
        ),
      ],
    );
  }

  void _showAssetDataDialog(String asset) {
    // For RTL sub-department, we need coach/asset data
    if (_subDepartment == 'RTL') {
      _showCoachSelectionDialog(asset);
    } else {
      // For Power sub-department, we can proceed with default data
      _openAsset(asset, {});
    }
  }

  void _showCoachSelectionDialog(String asset) {
    // This would typically show a coach/asset selection dialog
    // For now, we'll use mock data
    final mockAssetData = {
      'coach_type': 'German',
      'category': 'AC Sleeper',
      'dining': true,
      'sleeper': true,
      'parlour': false,
      'destination_board': 'Electrical',
      'ac_quantity': 2,
      'dg_quantity': 1,
      'fire_extinguishers_quantity': 2,
      'lights_door': 2,
      'lights_hall': 4,
      'lights_toilet': 2,
      'lights_panel': 1,
      'fans': 8,
      'shades': 4,
      'mobile_charging_units': 4,
    };

    _openAsset(asset, mockAssetData);
  }
}

class _ElectricalHistoryTab extends StatefulWidget {
  const _ElectricalHistoryTab();

  @override
  State<_ElectricalHistoryTab> createState() => _ElectricalHistoryTabState();
}

class _ElectricalHistoryTabState extends State<_ElectricalHistoryTab> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = ElectricalInspectionDraftService.getSubmittedRecords();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: AppLoader());
        }
        final records = snapshot.data!;
        if (records.isEmpty) {
          return const Center(child: Text('No submitted inspections yet.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: records.length,
          itemBuilder: (context, i) {
            final r = records[i];
            return Card(
              child: ListTile(
                leading: const Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                ),
                title: Text(r['formId'] as String),
                subtitle: Text('Submitted ${r['finishedAt']}'),
              ),
            );
          },
        );
      },
    );
  }
}
