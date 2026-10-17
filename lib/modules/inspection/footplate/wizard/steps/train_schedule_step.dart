import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/modules/inspection/footplate/models/footplate_models.dart';
import 'package:railway_hrms/modules/inspection/shared/widgets/inspection_fields.dart';

/// The train ridden: its number, load, engine and direction, the station
/// and times, and its crew.
class TrainScheduleStep extends StatelessWidget {
  const TrainScheduleStep({
    super.key,
    required this.data,
    required this.onChanged,
  });

  final TrainScheduleData data;
  final VoidCallback onChanged;

  Person? _person(String display) {
    for (final person in kStaffDirectory) {
      if (person.display == display) return person;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final d = data;
    final staff = [for (final person in kStaffDirectory) person.display];
    Widget crew(String label, Person? value, void Function(Person?) set) =>
        InspectionSelectInput(
          label: label,
          options: staff,
          value: value?.display,
          glyph: AppGlyphs.user,
          onChanged: (picked) {
            set(_person(picked));
            onChanged();
          },
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InspectionCard(
          title: 'Train & Locomotive',
          subtitle: 'Fills the train particulars of the report.',
          glyph: AppGlyphs.train,
          children: [
            InspectionSelectInput(
              label: 'Train No',
              options: kTrainNumbers,
              value: d.trainNo,
              glyph: AppGlyphs.trainFilled,
              onChanged: (v) {
                d.trainNo = v;
                onChanged();
              },
            ),
            InspectionTextInput(
              label: 'Load',
              value: d.load,
              onChanged: (v) {
                d.load = v;
                onChanged();
              },
            ),
            InspectionSelectInput(
              label: 'Engine No',
              options: kEngineNumbers,
              value: d.engineNo,
              note: 'The locomotive number of the asset.',
              onChanged: (v) {
                d.engineNo = v;
                onChanged();
              },
            ),
            InspectionChoiceInput(
              label: 'Direction',
              options: const ['Up', 'Down'],
              value: d.direction,
              onChanged: (v) {
                d.direction = v;
                onChanged();
              },
            ),
          ],
        ),
        AppSpacing.gapMd,
        InspectionCard(
          title: 'Station & Timing',
          glyph: AppGlyphs.clock,
          children: [
            InspectionSelectInput(
              label: 'Station',
              options: kStations,
              value: d.station,
              glyph: AppGlyphs.station,
              onChanged: (v) {
                d.station = v;
                onChanged();
              },
            ),
            InspectionFieldGrid(
              items: [
                InspectionGridItem(
                  InspectionTimeInput(
                    label: 'Arrival',
                    value: d.arrival,
                    onChanged: (t) {
                      d.arrival = t;
                      onChanged();
                    },
                  ),
                ),
                InspectionGridItem(
                  InspectionTimeInput(
                    label: 'Departure',
                    value: d.departure,
                    onChanged: (t) {
                      d.departure = t;
                      onChanged();
                    },
                  ),
                ),
              ],
            ),
            InspectionTextInput(
              label: 'Late Margin',
              unit: 's',
              kind: InspectionTextKind.integer,
              value: d.lateMargin == 0 ? '' : '${d.lateMargin}',
              onChanged: (v) {
                d.lateMargin = int.tryParse(v) ?? 0;
                onChanged();
              },
            ),
          ],
        ),
        AppSpacing.gapMd,
        InspectionCard(
          title: 'Crew',
          subtitle: 'Name, designation, department, org unit.',
          glyph: AppGlyphs.users,
          children: [
            crew("Driver", d.driver, (p) => d.driver = p),
            crew(
              'Assistant Driver',
              d.assistantDriver,
              (p) => d.assistantDriver = p,
            ),
            crew('Guard Incharge', d.guardIncharge, (p) => d.guardIncharge = p),
          ],
        ),
      ],
    );
  }
}
