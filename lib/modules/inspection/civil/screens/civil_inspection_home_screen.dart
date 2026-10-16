import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/navigation/app_routes.dart';
import 'package:railway_hrms/modules/inspection/civil/models/civil_inspection_catalog.dart';
import 'package:railway_hrms/modules/inspection/civil/screens/civil_asset_form_screen.dart';
import 'package:railway_hrms/modules/inspection/civil/services/civil_inspection_draft_service.dart';

class CivilInspectionHomeScreen extends StatefulWidget {
  const CivilInspectionHomeScreen({super.key});

  @override
  State<CivilInspectionHomeScreen> createState() =>
      _CivilInspectionHomeScreenState();
}

class _CivilInspectionHomeScreenState extends State<CivilInspectionHomeScreen> {
  String? _department;
  String? _subDepartment;

  @override
  void initState() {
    super.initState();
    _department = CivilDeptAssetMap.table.keys.first;
  }

  void _openAsset(String asset) {
    final fields = CivilDeptAssetMap.resolveFields(
      _department!,
      _subDepartment!,
      asset,
    );
    if (fields == null) {
      // Sleepers / Rails / Private Sidings / Point & Crossings / Loops &
      // Sidings route to the bespoke interactive screen instead.
      Navigator.pushNamed(context, AppRoutes.civilInspectionSleepersRails);
      return;
    }
    final formId = 'civil_${_department}_${_subDepartment}_$asset'
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CivilAssetFormScreen(
          department: _department!,
          subDepartment: _subDepartment!,
          asset: asset,
          fields: fields,
          formId: formId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subDepartments = CivilDeptAssetMap.table[_department]!.keys.toList();
    _subDepartment ??= subDepartments.first;
    final assets = CivilDeptAssetMap.table[_department]![_subDepartment]!;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Civil Inspection Forms'),
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
            const _CivilHistoryTab(),
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
          children: CivilDeptAssetMap.table.keys.map((d) {
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
              leading: const Icon(Icons.domain_outlined),
              title: Text(asset),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _openAsset(asset),
            ),
          ),
        ),
      ],
    );
  }
}

class _CivilHistoryTab extends StatefulWidget {
  const _CivilHistoryTab();

  @override
  State<_CivilHistoryTab> createState() => _CivilHistoryTabState();
}

class _CivilHistoryTabState extends State<_CivilHistoryTab> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = CivilInspectionDraftService.getSubmittedRecords();
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
