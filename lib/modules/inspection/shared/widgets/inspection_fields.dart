import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart' show ImageSource;
import 'package:intl/intl.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';
import 'package:railway_hrms/core/media/photo_picker.dart';
import 'package:railway_hrms/modules/inspection/shared/file_utils.dart';
import 'package:railway_hrms/modules/inspection/shared/report/inspection_report.dart';
import 'package:railway_hrms/modules/inspection/shared/widgets/stored_image.dart';

/// The fields every inspection form is built from, on the app's design:
/// pressed-in wells for what is typed or picked, chips for answers, and
/// cards for a form's parts. Each one shows the answer it is given and
/// reports a new one, so the form keeps its answers where it likes.

final RegExp _caution = RegExp(
  r'\b(standby|partial(ly)?|average|fair|moderate|due soon|minor|slow)\b',
  caseSensitive: false,
);

/// The tone an answer is shown in when picked: coral for one that reports
/// something wrong, as "Faulty", gold for one that asks for care, as
/// "Standby", and jade for the rest.
AppTone answerTone(String answer) => switch (ReportTone.of(answer)) {
  ReportTone.bad => AppTone.danger,
  _ when _caution.hasMatch(answer) => AppTone.warning,
  _ => AppTone.brand,
};

/// How a day reads on a form, as "12 Mar 2025".
String formDate(BuildContext context, DateTime day) => DateFormat.yMMMd(
  Localizations.localeOf(context).toLanguageTag(),
).format(day);

/// A question answered by something below it, as chips or a count: its
/// [label] over the answer, with a [note] on what is asked.
class InspectionQuestion extends StatelessWidget {
  const InspectionQuestion({
    super.key,
    required this.label,
    this.child,
    this.note,
    this.trailing,
  });

  final String label;
  final Widget? child;
  final String? note;

  /// Beside the label, as a count stepper.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    final note = this.note;
    final trailing = this.trailing;
    final child = this.child;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: text.titleSmall),
                  if (note != null) ...[
                    AppSpacing.gapXxs,
                    Text(
                      note,
                      style: text.bodySmall?.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[AppSpacing.gapSm, trailing],
          ],
        ),
        if (child != null) ...[AppSpacing.gapSm, child],
      ],
    );
  }
}

/// One of a few answers, as chips: "Yes" or "No", "Working" or "Faulty".
/// The answer picked lights in its tone, coral when it reports a fault.
class InspectionChoiceInput extends StatelessWidget {
  const InspectionChoiceInput({
    super.key,
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
    this.note,
    this.toneOf = answerTone,
  });

  final String label;
  final List<String> options;
  final String? value;
  final ValueChanged<String> onChanged;
  final String? note;

  /// The tone each answer lights in.
  final AppTone Function(String answer) toneOf;

  @override
  Widget build(BuildContext context) => InspectionQuestion(
    label: label,
    note: note,
    child: AppChoiceChips<String>(
      choices: [
        for (final option in options)
          AppChoice(option, option, tone: toneOf(option)),
      ],
      selected: value,
      onSelected: (picked) {
        if (picked == value) return;
        onChanged(picked);
      },
    ),
  );
}

/// What a text field takes.
enum InspectionTextKind {
  /// A line of words, as a name.
  text,

  /// A few lines, as remarks.
  multiline,

  /// A whole number, as a count.
  integer,

  /// A reading, as a voltage.
  decimal,
}

/// A typed answer: words, a count or a reading, with its [unit] at the
/// end and a [note] under it, or a [warning] when the reading looks wrong.
///
/// It shows [value] until typed in, and follows it when it is changed from
/// outside, as a draft is opened, while the field isn't being typed in.
class InspectionTextInput extends StatefulWidget {
  const InspectionTextInput({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.kind = InspectionTextKind.text,
    this.hint,
    this.unit,
    this.glyph,
    this.note,
    this.warning,
    this.enabled = true,
    this.validator,
  });

  final String label;
  final String? value;
  final ValueChanged<String> onChanged;
  final InspectionTextKind kind;
  final String? hint;
  final String? unit;
  final AppGlyph? glyph;
  final String? note;

  /// Said in gold under the field in place of the [note], as when a
  /// reading is out of its range.
  final String? warning;
  final bool enabled;
  final FormFieldValidator<String>? validator;

  @override
  State<InspectionTextInput> createState() => _InspectionTextInputState();
}

class _InspectionTextInputState extends State<InspectionTextInput> {
  late final TextEditingController _text = TextEditingController(
    text: widget.value ?? '',
  );
  final FocusNode _focus = FocusNode();

  @override
  void didUpdateWidget(InspectionTextInput old) {
    super.didUpdateWidget(old);
    final value = widget.value ?? '';
    if (!_focus.hasFocus && value != _text.text) _text.text = value;
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final unit = widget.unit;
    final (keyboard, formatters, lines) = switch (widget.kind) {
      InspectionTextKind.text => (TextInputType.text, null, 1),
      InspectionTextKind.multiline => (TextInputType.multiline, null, 4),
      InspectionTextKind.integer => (
        TextInputType.number,
        [FilteringTextInputFormatter.digitsOnly],
        1,
      ),
      InspectionTextKind.decimal => (
        const TextInputType.numberWithOptions(decimal: true),
        [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
        1,
      ),
    };
    final multiline = widget.kind == InspectionTextKind.multiline;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          controller: _text,
          focusNode: _focus,
          label: widget.label,
          hint: widget.hint,
          glyph: widget.glyph,
          enabled: widget.enabled,
          keyboardType: keyboard,
          inputFormatters: formatters,
          textInputAction: multiline
              ? TextInputAction.newline
              : TextInputAction.next,
          minLines: multiline ? 2 : null,
          maxLines: lines,
          validator: widget.validator,
          onChanged: widget.onChanged,
          suffix: unit == null
              ? null
              : Padding(
                  padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
                  child: Text(
                    unit,
                    style: context.textTheme.labelMedium?.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                ),
        ),
        InspectionFieldNote(
          text: widget.warning ?? widget.note,
          warning: widget.warning != null,
        ),
      ],
    );
  }
}

/// A line under a field: a quiet note, or a warning in gold. It eases in
/// and out as it comes and goes.
class InspectionFieldNote extends StatelessWidget {
  const InspectionFieldNote({super.key, this.text, this.warning = false});

  final String? text;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = this.text;
    return AnimatedSize(
      duration: AppMotion.short,
      curve: AppMotion.enter,
      alignment: AlignmentDirectional.topStart,
      child: text == null
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.only(
                top: AppSpacing.xs,
                left: AppSpacing.xxs,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (warning) ...[
                    AppGlyphIcon(
                      AppGlyphs.triangleAlert,
                      size: AppSizes.iconXs,
                      color: colors.onGoldContainer,
                    ),
                    AppSpacing.gapXs,
                  ],
                  Expanded(
                    child: Text(
                      text,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: warning
                            ? colors.onGoldContainer
                            : colors.textSecondary,
                        fontWeight: warning ? AppFonts.semiBold : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

/// One of many answers, picked from a sheet: a type, a make, a station.
class InspectionSelectInput extends StatelessWidget {
  const InspectionSelectInput({
    super.key,
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
    this.hint,
    this.glyph,
    this.note,
  });

  final String label;
  final List<String> options;
  final String? value;
  final ValueChanged<String> onChanged;
  final String? hint;
  final AppGlyph? glyph;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final value = this.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSelectField<String>(
          // Shows an answer set from outside, as a draft's.
          key: ValueKey(value),
          label: label,
          hint: hint ?? context.l10n.inspFormSelect,
          sheetTitle: label,
          glyph: glyph,
          options: options,
          optionLabel: (option) => option,
          initialValue: value != null && options.contains(value) ? value : null,
          onChanged: onChanged,
        ),
        InspectionFieldNote(text: note),
      ],
    );
  }
}

/// A day, picked on wheels from a sheet, with a [status] under it, such as
/// whether what it dates is overdue.
class InspectionDateInput extends StatelessWidget {
  const InspectionDateInput({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.firstDate,
    this.lastDate,
    this.status,
    this.note,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;

  /// The earliest and latest days it may be; thirty years back and ten on
  /// by default.
  final DateTime? firstDate;
  final DateTime? lastDate;
  final Widget? status;
  final String? note;

  Future<void> _pick(BuildContext context) async {
    final l10n = context.l10n;
    final now = DateTime.now();
    final picked = await showAppDateSheet(
      context: context,
      title: label,
      closeLabel: l10n.actionClose,
      doneLabel: l10n.inspFormDone,
      initial: value ?? now,
      firstDate: firstDate ?? DateTime(now.year - 30),
      lastDate: lastDate ?? DateTime(now.year + 10, 12, 31),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final value = this.value;
    final status = this.status;
    final shown = value == null
        ? context.l10n.inspFormSelectDate
        : formDate(context, value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          label: label,
          value: shown,
          child: ExcludeSemantics(
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: () => _pick(context),
                borderRadius: AppRadius.borderLg,
                splashFactory: NoSplash.splashFactory,
                child: AppFieldFrame(
                  label: label,
                  glyph: AppGlyphs.calendar,
                  trailing: Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: AppGlyphIcon(
                      AppGlyphs.chevronDown,
                      size: AppSizes.iconMd,
                      color: colors.textTertiary,
                    ),
                  ),
                  child: Text(
                    shown,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: value == null
                        ? context.textTheme.labelLarge?.copyWith(
                            color: colors.textTertiary,
                            fontWeight: FontWeight.normal,
                          )
                        : const TextStyle(
                            fontFeatures: AppFonts.tabularFigures,
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (status != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: status,
            ),
          ),
        InspectionFieldNote(text: note),
      ],
    );
  }
}

/// A count set a step at a time, as fire extinguishers on a platform.
class InspectionCountInput extends StatelessWidget {
  const InspectionCountInput({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 99,
    this.note,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  final String? note;

  @override
  Widget build(BuildContext context) => InspectionQuestion(
    label: label,
    note: note,
    trailing: AppCountStepper(
      value: value,
      min: min,
      max: max,
      decreaseLabel: context.l10n.inspFormDecrease,
      increaseLabel: context.l10n.inspFormIncrease,
      onChanged: onChanged,
    ),
  );
}

/// The note asked for when an answer reports a fault: it opens under the
/// answer, on a coral tint, while [visible].
class InspectionRemarkInput extends StatelessWidget {
  const InspectionRemarkInput({
    super.key,
    required this.visible,
    required this.value,
    required this.onChanged,
    this.label,
  });

  final bool visible;
  final String? value;
  final ValueChanged<String> onChanged;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    return AnimatedSize(
      duration: AppMotion.medium,
      curve: AppMotion.enter,
      alignment: Alignment.topCenter,
      child: !visible
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.dangerContainer,
                  borderRadius: AppRadius.borderXl,
                  border: Border.all(color: colors.dangerRing),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: InspectionTextInput(
                    label: label ?? l10n.inspFormRemarkLabel,
                    hint: l10n.inspFormRemarkHint,
                    glyph: AppGlyphs.fileEdit,
                    kind: InspectionTextKind.multiline,
                    value: value,
                    onChanged: onChanged,
                  ),
                ),
              ),
            ),
    );
  }
}

/// A heading inside a part of a form, over the questions it groups.
class InspectionSubhead extends StatelessWidget {
  const InspectionSubhead(this.title, {super.key, this.note});

  final String title;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final note = this.note;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionLabel(title),
          if (note != null) ...[
            AppSpacing.gapXxs,
            Text(
              note,
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A due date's state, as a pill: overdue in coral, due soon in gold, in
/// date in jade.
class InspectionStatusPill extends StatelessWidget {
  const InspectionStatusPill(this.label, {super.key, required this.tone});

  final String label;
  final AppTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppPill(
      label,
      tone: tone,
      dot: switch (tone) {
        AppTone.danger => colors.danger,
        AppTone.warning => colors.gold,
        AppTone.brand => colors.success,
        _ => colors.textTertiary,
      },
    );
  }
}

/// One field of an [InspectionFieldGrid]; a [wide] one takes a whole row.
@immutable
class InspectionGridItem {
  const InspectionGridItem(this.child, {this.wide = false});

  final Widget child;
  final bool wide;
}

/// Fields one under another on a phone, and two to a row where there is
/// room, as on a tablet.
class InspectionFieldGrid extends StatelessWidget {
  const InspectionFieldGrid({super.key, required this.items});

  final List<InspectionGridItem> items;

  /// The narrowest a field gets beside another.
  static const double _pairWidth = 560;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final rows = <Widget>[];
      if (box.maxWidth < _pairWidth) {
        rows.addAll(items.map((item) => item.child));
      } else {
        Widget? waiting;
        void flush() {
          final left = waiting;
          if (left == null) return;
          rows.add(
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: left),
                AppSpacing.gapMd,
                const Spacer(),
              ],
            ),
          );
          waiting = null;
        }

        for (final item in items) {
          if (item.wide) {
            flush();
            rows.add(item.child);
          } else if (waiting case final left?) {
            rows.add(
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: left),
                  AppSpacing.gapMd,
                  Expanded(child: item.child),
                ],
              ),
            );
            waiting = null;
          } else {
            waiting = item.child;
          }
        }
        flush();
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, row) in rows.indexed) ...[
            if (i > 0) AppSpacing.gapLg,
            row,
          ],
        ],
      );
    },
  );
}

/// A part of a form on a card: its 3D [glyph] on a tile, [title] and
/// [subtitle], then its fields.
class InspectionCard extends StatelessWidget {
  const InspectionCard({
    super.key,
    required this.children,
    this.title,
    this.subtitle,
    this.glyph,
    this.trailing,
  });

  final List<Widget> children;
  final String? title;
  final String? subtitle;
  final AppGlyph? glyph;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    final title = this.title;
    final subtitle = this.subtitle;
    final glyph = this.glyph;
    final trailing = this.trailing;
    return RepaintBoundary(
      child: DecoratedBox(
        decoration: appCardDecoration(
          context,
          radius: AppRadius.borderHeroCard,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md + AppSpacing.xxs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (title != null) ...[
                Row(
                  children: [
                    if (glyph != null) ...[
                      AppIconTile(
                        size: AppSizes.rowTile,
                        child: AppGlyphIcon(
                          glyph,
                          size: AppSizes.iconMd,
                          color: colors.iconAccent,
                          depth: true,
                        ),
                      ),
                      AppSpacing.gapSm,
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Semantics(
                            header: true,
                            child: Text(title, style: text.titleSmall),
                          ),
                          if (subtitle != null)
                            Text(
                              subtitle,
                              style: text.bodySmall?.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (trailing != null) ...[AppSpacing.gapSm, trailing],
                  ],
                ),
                AppSpacing.gapLg,
              ],
              for (final (i, child) in children.indexed) ...[
                if (i > 0) AppSpacing.gapLg,
                child,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Facts about what is inspected, each label beside its value, as an
/// asset's department and type.
class InspectionFacts extends StatelessWidget {
  const InspectionFacts(this.facts, {super.key});

  final List<(String, String)> facts;

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, (label, value)) in facts.indexed) ...[
          if (i > 0) AppSpacing.gapSm,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: text.bodySmall?.copyWith(color: colors.textSecondary),
                ),
              ),
              AppSpacing.gapMd,
              Flexible(
                flex: 2,
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style: text.labelLarge,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Several of a few answers, as chips, as the defects seen on a part.
class InspectionMultiChoiceInput extends StatelessWidget {
  const InspectionMultiChoiceInput({
    super.key,
    required this.label,
    required this.options,
    required this.values,
    required this.onChanged,
    this.note,
    this.toneOf = answerTone,
  });

  final String label;
  final List<String> options;
  final List<String> values;
  final ValueChanged<List<String>> onChanged;
  final String? note;
  final AppTone Function(String answer) toneOf;

  @override
  Widget build(BuildContext context) => InspectionQuestion(
    label: label,
    note: note,
    child: AppMultiChoiceChips<String>(
      choices: [
        for (final option in options)
          AppChoice(option, option, tone: toneOf(option)),
      ],
      selected: values.toSet(),
      onToggled: (option) {
        onChanged(
          values.contains(option)
              ? [...values.where((v) => v != option)]
              : [...values, option],
        );
      },
    ),
  );
}

/// A time of day, picked on a wheel from a sheet.
class InspectionTimeInput extends StatelessWidget {
  const InspectionTimeInput({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final TimeOfDay? value;
  final ValueChanged<TimeOfDay> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final value = this.value;
    final shown = value?.format(context) ?? l10n.inspFormSelectTime;
    return Semantics(
      button: true,
      label: label,
      value: shown,
      child: ExcludeSemantics(
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: AppRadius.borderLg,
            splashFactory: NoSplash.splashFactory,
            onTap: () async {
              final picked = await showAppTimeSheet(
                context: context,
                title: label,
                closeLabel: l10n.actionClose,
                doneLabel: l10n.inspFormDone,
                initial: value ?? TimeOfDay.now(),
              );
              if (picked != null) onChanged(picked);
            },
            child: AppFieldFrame(
              label: label,
              glyph: AppGlyphs.clock,
              child: Text(
                shown,
                style: value == null
                    ? context.textTheme.labelLarge?.copyWith(
                        color: colors.textTertiary,
                        fontWeight: FontWeight.normal,
                      )
                    : const TextStyle(fontFeatures: AppFonts.tabularFigures),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Photos taken for part of an inspection: a strip of them, the camera
/// key that adds one, and a hold that offers to remove one. Kept as the
/// paths the forms store.
class InspectionPhotosInput extends StatelessWidget {
  const InspectionPhotosInput({
    super.key,
    required this.photos,
    required this.onChanged,
  });

  final List<String> photos;
  final ValueChanged<List<String>> onChanged;

  Future<void> _take(BuildContext context) async {
    final shot = await PhotoPicker.pick(
      source: ImageSource.camera,
      context: context,
      maxWidth: 1600,
      imageQuality: 80,
    );
    if (shot == null) return;
    final kept = await FootplateFileUtils.saveImagePermanently(shot.path);
    onChanged([...photos, kept]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    return InspectionQuestion(
      label: l10n.inspFormPhotos,
      child: AppGrid(
        columns: 3,
        spacing: AppSpacing.smd,
        children: [
          for (final photo in photos)
            GestureDetector(
              onLongPress: () async {
                final sure = await showAppDialog(
                  context: context,
                  tone: AppDialogTone.warning,
                  title: l10n.inspFormRemovePhoto,
                  primaryLabel: l10n.inspFormRemoveRow,
                  secondaryLabel: l10n.actionCancel,
                );
                if (sure == true) {
                  onChanged([...photos.where((p) => p != photo)]);
                }
              },
              child: ClipRRect(
                borderRadius: AppRadius.borderLg,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: StoredImage(path: photo),
                ),
              ),
            ),
          AspectRatio(
            aspectRatio: 1,
            child: Material(
              color: colors.surfaceSunken,
              borderRadius: AppRadius.borderLg,
              child: InkWell(
                borderRadius: AppRadius.borderLg,
                onTap: () => _take(context),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppGlyphIcon(
                      AppGlyphs.camera,
                      color: colors.iconAccent,
                      depth: true,
                    ),
                    AppSpacing.gapXs,
                    Text(
                      l10n.inspFormAddPhoto,
                      style: context.textTheme.labelSmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
