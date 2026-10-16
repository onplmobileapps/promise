import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart' hide FormField;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:railway_hrms/core/design_system/components/app_dialog.dart';
import 'package:railway_hrms/core/media/photo_picker.dart';
import 'package:railway_hrms/modules/inspection/footplate/dynamic_form/input_formatters.dart';
import 'package:railway_hrms/modules/inspection/footplate/dynamic_form/models.dart';
import 'package:railway_hrms/modules/inspection/footplate/dynamic_form/validator.dart';
import 'package:railway_hrms/modules/inspection/shared/file_utils.dart';

/// Dynamic form renderer that renders fields based on template
class DynamicFormRenderer extends StatefulWidget {
  final FormTemplate template;
  final FormData formData;
  final VoidCallback? onChanged;
  final bool enabled;
  final bool showValidationErrors;

  const DynamicFormRenderer({
    super.key,
    required this.template,
    required this.formData,
    this.onChanged,
    this.enabled = true,
    this.showValidationErrors = true,
  });
  @override
  State<DynamicFormRenderer> createState() => _DynamicFormRendererState();
}

class _DynamicFormRendererState extends State<DynamicFormRenderer> {
  final Map<String, List<Offset?>> _signaturePoints = {};
  final Map<String, GlobalKey> _signatureKeys = {};
  final Map<String, TextEditingController> _controllers = {};

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(DynamicFormRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync controllers if formData changed externally
    _controllers.forEach((key, controller) {
      final value = widget.formData.getValue(key)?.toString() ?? '';
      if (controller.text != value) {
        controller.text = value;
      }
    });
  }

  GlobalKey _signatureKey(String fieldKey) {
    return _signatureKeys.putIfAbsent(fieldKey, GlobalKey.new);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widget.template.sections
            .map((section) => _buildSection(section))
            .toList(),
      ),
    );
  }

  Widget _buildSection(FormSection section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            section.title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        ...section.fields.map((field) {
          // Check if field should be visible
          if (!field.isVisible(widget.formData.values)) {
            return const SizedBox.shrink();
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildField(field),
          );
        }),
        const Divider(height: 32),
      ],
    );
  }

  Widget _buildField(DynamicFormField field) {
    switch (field.type) {
      case FieldType.text:
      case FieldType.number:
        return _buildTextField(field);
      case FieldType.remarks:
        return _buildRemarksField(field);
      case FieldType.dropdown:
        return _buildDropdownField(field);
      case FieldType.radio:
        return _buildRadioField(field);
      case FieldType.checkbox:
        return _buildCheckboxField(field);
      case FieldType.date:
        return _buildDateField(field);
      case FieldType.gps:
        return _buildGPSField(field);
      case FieldType.image:
        return _buildImageField(field);
      case FieldType.signature:
        return _buildSignatureField(field);
    }
  }

  Widget _buildTextField(DynamicFormField field) {
    final errorText = widget.showValidationErrors
        ? widget.formData.errors[field.key]
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          field.label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          enabled: widget.enabled,
          controller: _getController(field.key),
          keyboardType: KeyboardTypeHelper.getKeyboardType(field.type),
          textInputAction: TextInputAction.done,
          inputFormatters: [
            ...InputFormatterFactory.createFormatters(field.inputFormatter),
            if (field.inputFormatter?.maxLength != null)
              LengthLimitingTextInputFormatter(field.inputFormatter!.maxLength),
          ],
          decoration: InputDecoration(
            hintText: field.placeholder,
            errorText: errorText,
            border: const OutlineInputBorder(),
            filled: !widget.enabled,
          ),
          onChanged: (value) {
            widget.formData.setValue(field.key, value);
            _validateField(field);
            widget.onChanged?.call();
          },
          onSubmitted: (_) => FocusScope.of(context).unfocus(),
        ),
        if (field.validation.required)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '* Required',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.red),
            ),
          ),
      ],
    );
  }

  Widget _buildRemarksField(DynamicFormField field) {
    final errorText = widget.showValidationErrors
        ? widget.formData.errors[field.key]
        : null;
    final formatter = field.inputFormatter;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          field.label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          enabled: widget.enabled,
          controller: _getController(field.key),
          maxLines: formatter?.maxLines ?? 5,
          minLines: formatter?.minLines ?? 3,
          keyboardType: TextInputType.multiline,
          inputFormatters: [
            if (formatter?.maxLength != null)
              LengthLimitingTextInputFormatter(formatter!.maxLength),
          ],
          decoration: InputDecoration(
            hintText: field.placeholder,
            errorText: errorText,
            border: const OutlineInputBorder(),
            filled: !widget.enabled,
          ),
          onChanged: (value) {
            widget.formData.setValue(field.key, value);
            _validateField(field);
            widget.onChanged?.call();
          },
        ),
        if (field.validation.required)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '* Required',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.red),
            ),
          ),
      ],
    );
  }

  Widget _buildDropdownField(DynamicFormField field) {
    final errorText = widget.showValidationErrors
        ? widget.formData.errors[field.key]
        : null;
    final value = widget.formData.getValue(field.key);
    final currentValue = value?.toString();

    // Mock lookup data - in production, this would come from a service
    final lookupOptions = _getLookupOptions(field.lookupCategory);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          field.label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: currentValue,
          decoration: InputDecoration(
            hintText: field.placeholder,
            errorText: errorText,
            border: const OutlineInputBorder(),
            filled: !widget.enabled,
          ),
          items: lookupOptions.map((option) {
            return DropdownMenuItem<String>(value: option, child: Text(option));
          }).toList(),
          onChanged: widget.enabled
              ? (value) {
                  widget.formData.setValue(field.key, value);
                  _validateField(field);
                  widget.onChanged?.call();
                }
              : null,
        ),
        if (field.validation.required)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '* Required',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.red),
            ),
          ),
      ],
    );
  }

  Widget _buildRadioField(DynamicFormField field) {
    final errorText = widget.showValidationErrors
        ? widget.formData.errors[field.key]
        : null;
    final value = widget.formData.getValue(field.key);
    final currentValue = value?.toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          field.label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        RadioGroup<String>(
          groupValue: currentValue,
          onChanged: (value) {
            if (value != null) {
              widget.formData.setValue(field.key, value);
              _validateField(field);
              widget.onChanged?.call();
            }
          },
          child: Column(
            children: [
              ...field.options.map((option) {
                return RadioListTile<String>(
                  title: Text(option.label),
                  value: option.value,
                );
              }),
            ],
          ),
        ),

        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              errorText,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.red),
            ),
          ),
        if (field.validation.required)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '* Required',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.red),
            ),
          ),
      ],
    );
  }

  Widget _buildCheckboxField(DynamicFormField field) {
    final value = widget.formData.getValue(field.key);
    final currentValue = value is List
        ? List<String>.from(value.map((e) => e.toString()))
        : <String>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          field.label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        ...field.options.map((option) {
          return CheckboxListTile(
            title: Text(option.label),
            value: currentValue.contains(option.value),
            onChanged: widget.enabled
                ? (checked) {
                    final updatedList = List<String>.from(currentValue);
                    if (checked == true) {
                      updatedList.add(option.value);
                    } else {
                      updatedList.remove(option.value);
                    }
                    widget.formData.setValue(field.key, updatedList);
                    widget.onChanged?.call();
                  }
                : null,
          );
        }),
      ],
    );
  }

  Widget _buildDateField(DynamicFormField field) {
    final errorText = widget.showValidationErrors
        ? widget.formData.errors[field.key]
        : null;
    final currentValue = widget.formData.getValue(field.key);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          field.label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: widget.enabled
              ? () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    widget.formData.setValue(
                      field.key,
                      DateFormat('yyyy-MM-dd').format(picked),
                    );
                    _validateField(field);
                    widget.onChanged?.call();
                  }
                }
              : null,
          child: InputDecorator(
            decoration: InputDecoration(
              hintText: field.placeholder ?? 'Select date',
              errorText: errorText,
              border: const OutlineInputBorder(),
              filled: !widget.enabled,
              suffixIcon: const Icon(Icons.calendar_today),
            ),
            child: Text(
              currentValue != null
                  ? currentValue.toString()
                  : field.placeholder ?? 'Select date',
            ),
          ),
        ),
        if (field.validation.required)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '* Required',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.red),
            ),
          ),
      ],
    );
  }

  Widget _buildGPSField(DynamicFormField field) {
    final currentValue = widget.formData.getValue(field.key);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          field.label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              const Icon(Icons.location_on, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  currentValue?.toString() ?? 'GPS location not captured',
                  style: TextStyle(
                    color: currentValue != null ? Colors.black : Colors.grey,
                  ),
                ),
              ),
              if (field.autoCapture && widget.enabled)
                TextButton.icon(
                  onPressed: () {
                    showAppMessage(
                      context,
                      'GPS capture not implemented',
                      tone: AppDialogTone.error,
                    );
                  },
                  icon: const Icon(Icons.my_location),
                  label: const Text('Capture'),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageField(DynamicFormField field) {
    final currentValue = widget.formData.getValue(field.key);
    final imagePath = currentValue is String ? currentValue : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          field.label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: widget.enabled ? () => _pickImage(field) : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.outline),
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(context).colorScheme.surfaceContainerLowest,
            ),
            clipBehavior: Clip.antiAlias,
            child: imagePath != null
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(
                        File(imagePath),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          child: const Center(
                            child: Icon(
                              Icons.broken_image_rounded,
                              size: 48,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: IconButton.filledTonal(
                          onPressed: () {
                            widget.formData.setValue(field.key, null);
                            widget.onChanged?.call();
                          },
                          icon: const Icon(Icons.close_rounded),
                          tooltip: 'Remove image',
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_rounded,
                        size: 48,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to capture or upload image',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
          ),
        ),
        if (field.validation.required)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '* Required',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.red),
            ),
          ),
      ],
    );
  }

  Widget _buildSignatureField(DynamicFormField field) {
    final errorText = widget.showValidationErrors
        ? widget.formData.errors[field.key]
        : null;
    final currentValue = widget.formData.getValue(field.key);
    final signatureBytes = currentValue is Uint8List ? currentValue : null;
    final points = _signaturePoints.putIfAbsent(field.key, () => []);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          field.label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          height: 140,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(
              color: errorText != null
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.outline,
            ),
            borderRadius: BorderRadius.circular(12),
            color: Theme.of(context).colorScheme.surface,
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              RepaintBoundary(
                key: _signatureKey(field.key),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (signatureBytes != null)
                      Image.memory(signatureBytes, fit: BoxFit.contain),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanStart: widget.enabled
                          ? (details) => setState(() {
                              points.add(details.localPosition);
                            })
                          : null,
                      onPanUpdate: widget.enabled
                          ? (details) => setState(() {
                              points.add(details.localPosition);
                            })
                          : null,
                      onPanEnd: widget.enabled
                          ? (_) {
                              points.add(null);
                              _saveInlineSignature(field);
                            }
                          : null,
                      child: CustomPaint(
                        painter: _SignaturePainter(
                          points: points,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ],
                ),
              ),
              if (signatureBytes == null && points.whereType<Offset>().isEmpty)
                IgnorePointer(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.draw_rounded,
                          size: 42,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Draw signature here',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              if (signatureBytes != null ||
                  points.whereType<Offset>().isNotEmpty)
                Positioned(
                  right: 4,
                  top: 4,
                  child: IconButton.filledTonal(
                    onPressed: widget.enabled
                        ? () => setState(() {
                            points.clear();
                            widget.formData.setValue(field.key, null);
                            widget.onChanged?.call();
                          })
                        : null,
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Clear signature',
                  ),
                ),
            ],
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              errorText,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.red),
            ),
          ),
        if (field.validation.required)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '* Required',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.red),
            ),
          ),
      ],
    );
  }

  Future<void> _pickImage(DynamicFormField field) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Take photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    if (!mounted) return;
    final picked = await PhotoPicker.pick(
      source: source,
      context: context,
      imageQuality: 85,
      maxWidth: 2000,
    );
    if (picked == null) return;

    final permanentPath = await FootplateFileUtils.saveImagePermanently(
      picked.path,
    );

    widget.formData.setValue(field.key, permanentPath);
    _validateField(field);
    widget.onChanged?.call();
  }

  Future<void> _saveInlineSignature(DynamicFormField field) async {
    final points = _signaturePoints[field.key];
    if (points == null || points.whereType<Offset>().isEmpty) return;

    await WidgetsBinding.instance.endOfFrame;
    final renderObject = _signatureKey(
      field.key,
    ).currentContext?.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) return;

    final image = await renderObject.toImage(pixelRatio: 3);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (byteData == null) return;

    widget.formData.setValue(field.key, byteData.buffer.asUint8List());
    setState(() => points.clear());
    _validateField(field);
    widget.onChanged?.call();
  }

  TextEditingController _getController(String key) {
    if (_controllers.containsKey(key)) {
      return _controllers[key]!;
    }

    final controller = TextEditingController(
      text: widget.formData.getValue(key)?.toString() ?? '',
    );
    _controllers[key] = controller;
    return controller;
  }

  void _validateField(DynamicFormField field) {
    if (widget.showValidationErrors) {
      FieldValidator.validateAndUpdate(field, widget.formData);
      setState(() {});
    }
  }

  // Mock lookup data - in production, this would come from a service
  List<String> _getLookupOptions(String? category) {
    switch (category) {
      case 'stations':
        return [
          'Lahore Railway Station',
          'Raiwind Junction',
          'Sahiwal Junction',
          'Multan Cantt',
          'Khanewal Junction',
        ];
      default:
        return [];
    }
  }
}

class _SignaturePainter extends CustomPainter {
  final List<Offset?> points;
  final Color color;

  const _SignaturePainter({required this.points, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (var index = 0; index < points.length - 1; index++) {
      final start = points[index];
      final end = points[index + 1];
      if (start != null && end != null) {
        canvas.drawLine(start, end, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}
