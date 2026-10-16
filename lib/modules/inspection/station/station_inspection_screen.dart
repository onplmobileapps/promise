import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/di/service_locator.dart';
import 'package:railway_hrms/core/face_verification/face_repository.dart';
import 'package:railway_hrms/core/location/current_location_service.dart';
import 'package:railway_hrms/core/network/api_endpoints.dart';
import 'package:railway_hrms/core/network/dio_client.dart';
import 'package:railway_hrms/core/storage/storage_service.dart';
import 'package:railway_hrms/core/utils/device_utils.dart';
import 'package:railway_hrms/modules/inspection/shared/inspection_colors.dart';
import 'package:railway_hrms/modules/inspection/station/controller.dart';
import 'package:railway_hrms/modules/inspection/station/models.dart';
import 'package:railway_hrms/modules/inspection/station/models/station_inspection_submit_model.dart';
import 'package:railway_hrms/modules/inspection/station/models/station_model.dart';
import 'package:railway_hrms/modules/inspection/station/section_data.dart';
import 'package:railway_hrms/modules/inspection/station/widgets/section_widgets.dart';

class StationInspectionScreen extends StatefulWidget {
  const StationInspectionScreen({super.key});

  @override
  State<StationInspectionScreen> createState() =>
      _StationInspectionScreenState();
}

class _StationInspectionScreenState extends State<StationInspectionScreen> {
  late final StationInspectionController _controller =
      StationInspectionController();
  final ScrollController _stepperScrollController = ScrollController();
  final ScrollController _contentScrollController = ScrollController();
  final List<GlobalKey> _stepKeys = List.generate(
    kInspectionSections.length,
    (_) => GlobalKey(),
  );

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChange);
  }

  @override
  void dispose() {
    _controller.removeListener(_onChange);
    _stepperScrollController.dispose();
    _contentScrollController.dispose();
    super.dispose();
  }

  void _onChange() => setState(() {});

  void _goToStep(int index) {
    if (index < 0 || index >= kInspectionSections.length) return;

    if (_contentScrollController.hasClients) {
      _contentScrollController.jumpTo(0);
    }

    setState(() => _controller.currentStep = index);
    _controller.saveDraftToDisk();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final stepContext = _stepKeys[index].currentContext;
      if (stepContext != null) {
        Scrollable.ensureVisible(
          stepContext,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
          alignment: 0.5,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final progress = _controller.overallProgress(kInspectionSections);

    if (!_controller.isStarted) {
      return _PreparationView(controller: _controller);
    }

    final activeIndex = _controller.currentStep;
    final activeSection = kInspectionSections[activeIndex];
    final isLast = activeIndex == kInspectionSections.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Signaling and Telecom'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 4,
            backgroundColor: const Color(0xFFE2E8F0),
            valueColor: AlwaysStoppedAnimation(
              progress == 1.0 ? InspectionColors.success : scheme.primary,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _TopMeta(controller: _controller),
            _HorizontalStepper(
              controller: _controller,
              scrollController: _stepperScrollController,
              stepKeys: _stepKeys,
              onStepTap: _goToStep,
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: _contentScrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                physics: const BouncingScrollPhysics(),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.03),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: _StepContentCard(
                    key: ValueKey(activeIndex),
                    index: activeIndex,
                    section: activeSection,
                    isFirst: activeIndex == 0,
                    isLast: isLast,
                    controller: _controller,
                    onContinue: () => _goToStep(activeIndex + 1),
                    onPrevious: () => _goToStep(activeIndex - 1),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontally-scrolling stepper bar: circles + labels connected by
/// short horizontal lines. Auto-centers the active step.
class _HorizontalStepper extends StatelessWidget {
  final StationInspectionController controller;
  final ScrollController scrollController;
  final List<GlobalKey> stepKeys;
  final ValueChanged<int> onStepTap;

  const _HorizontalStepper({
    required this.controller,
    required this.scrollController,
    required this.stepKeys,
    required this.onStepTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.only(top: 14, bottom: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: SingleChildScrollView(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: kInspectionSections.asMap().entries.map((entry) {
            final index = entry.key;
            final section = entry.value;
            final isLastItem = index == kInspectionSections.length - 1;
            final isActive = controller.currentStep == index;
            final (filled, total) = controller.sectionFillProgress(section);
            final isComplete = total > 0 && filled == total;

            return Padding(
              key: stepKeys[index],
              padding: EdgeInsets.zero,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => onStepTap(index),
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox(
                      width: 84,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? scheme.primary
                                  : (isComplete
                                        ? InspectionColors.success
                                        : Colors.white),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isActive
                                    ? scheme.primary
                                    : (isComplete
                                          ? InspectionColors.success
                                          : const Color(0xFFCBD5E1)),
                                width: 2,
                              ),
                              boxShadow: isActive
                                  ? [
                                      BoxShadow(
                                        color: scheme.primary.withValues(
                                          alpha: 0.3,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Center(
                              child: isComplete && !isActive
                                  ? const Icon(
                                      Icons.check,
                                      size: 18,
                                      color: Colors.white,
                                    )
                                  : Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        color: isActive
                                            ? Colors.white
                                            : const Color(0xFF64748B),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            section.title.toUpperCase(),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
                              color: isActive
                                  ? scheme.primary
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!isLastItem)
                    Padding(
                      padding: const EdgeInsets.only(top: 17),
                      child: Container(
                        width: 24,
                        height: 2,
                        color: isComplete
                            ? InspectionColors.success.withValues(alpha: 0.5)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// The panel + nav buttons for whichever step is currently active.
class _StepContentCard extends StatelessWidget {
  final int index;
  final InspectionSection section;
  final bool isFirst;
  final bool isLast;
  final StationInspectionController controller;
  final VoidCallback onContinue;
  final VoidCallback onPrevious;

  const _StepContentCard({
    super.key,
    required this.index,
    required this.section,
    required this.isFirst,
    required this.isLast,
    required this.controller,
    required this.onContinue,
    required this.onPrevious,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),

            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: _SectionPanel(
            section: section,
            index: index,
            controller: controller,
            onPrev: null,
            onNext: null,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Row(
            children: [
              if (!isFirst)
                TextButton.icon(
                  onPressed: onPrevious,
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: const Text('PREVIOUS'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF64748B),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              if (!isFirst) const SizedBox(width: 12),
              if (!isLast)
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onContinue,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    label: const Text('PROCEED TO NEXT'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionPanel extends StatelessWidget {
  final InspectionSection section;
  final int index;
  final StationInspectionController controller;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  const _SectionPanel({
    required this.section,
    required this.index,
    required this.controller,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (section.isSignals)
            SignalsSectionBody(controller: controller)
          else if (section.isRepeatSection)
            RepeatSectionBody(type: section.repeatType!, controller: controller)
          else if (section.isReview)
            _ReviewBody(section: section, controller: controller)
          else
            FixedSectionBody(section: section, controller: controller),
        ],
      ),
    );
  }
}

class _TopMeta extends StatelessWidget {
  final StationInspectionController controller;
  const _TopMeta({required this.controller});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final stationName = controller.station == 'Other'
        ? controller.stationOther
        : (controller.station ?? '');

    return Container(
      decoration: const BoxDecoration(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          AppBackButton(onPressed: () => _confirmExit(context)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: 18,
                      color: scheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        stationName,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: scheme.primary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.event_note_rounded,
                        size: 14,
                        color: scheme.secondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Inspection Date: ',
                        style: textTheme.labelSmall?.copyWith(
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        '${controller.inspDate.day}/${controller.inspDate.month}/${controller.inspDate.year} ${controller.inspDate.hour.toString().padLeft(2, '0')}:${controller.inspDate.minute.toString().padLeft(2, '0')}',
                        style: textTheme.labelSmall?.copyWith(
                          color: const Color(0xFF1E293B),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmExit(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Exit Inspection?'),
        content: const Text(
          'Would you like to save your progress as a draft or discard all changes?',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await controller.clearDraftFromDisk();
              controller.resetInspection();
              if (dialogContext.mounted) Navigator.pop(dialogContext);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Discard', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF5CA38E),
            ),
            onPressed: () async {
              await controller.saveDraftToDisk();
              controller.isStarted = false;
              if (dialogContext.mounted) Navigator.pop(dialogContext);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save as Draft'),
          ),
        ],
      ),
    );
  }
}

/// Helper method to capture face selfie and verify against server API.
Future<({bool success, String? imagePath})> _verifyFaceWithApi(
  BuildContext context,
) async {
  final result = await DeviceUtils.performFaceVerification(context);
  if (result == null || result.images.isEmpty) {
    return (success: false, imagePath: null);
  }

  final imagePath = result.images.first.path;

  if (!context.mounted) return (success: false, imagePath: null);

  // Show Loading Dialog while verifying with backend
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppLoader(size: AppSizes.loaderSmall),
              SizedBox(height: 16),
              Text(
                'Verifying face with server...',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  try {
    final user = await StorageService.getUser();
    final employeeId = user?.user?.empid.toString() ?? '';
    final position = await CurrentLocationService.getCurrentLocation();

    final latitude = position?.latitude ?? 0.0;
    final longitude = position?.longitude ?? 0.0;

    final List<MultipartFile> multipartImages = [];
    for (var img in result.images) {
      multipartImages.add(
        await MultipartFile.fromFile(img.path, filename: img.name),
      );
    }

    final repo = sl<FaceRepository>();
    final responseEither = await repo.verifyFace(
      employeeId,
      multipartImages,
      result.embeddings,
      latitude,
      longitude,
    );

    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    bool isVerified = false;
    String errorMessage = 'Face verification failed.';

    responseEither.fold(
      (failure) {
        isVerified = false;
        errorMessage = failure.message.isNotEmpty
            ? failure.message
            : 'Face verification server error.';
      },
      (response) {
        final verifyData = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : null;

        final status = verifyData?['status'] as String?;
        final message =
            verifyData?['message'] as String? ??
            verifyData?['detail'] as String?;

        if (status == 'matched' || status == 'success') {
          isVerified = true;
        } else if (status == 'not_matched') {
          isVerified = false;
          errorMessage = 'Face verification failed: Profile does not match.';
        } else {
          isVerified = false;
          errorMessage = message ?? 'Face verification failed.';
        }
      },
    );

    if (isVerified) {
      if (context.mounted) {
        showAppMessage(
          context,
          'Face verification successful! ✓',
          tone: AppDialogTone.success,
        );
      }
      return (success: true, imagePath: imagePath);
    } else {
      if (context.mounted) {
        showAppMessage(context, errorMessage, tone: AppDialogTone.error);
      }
      return (success: false, imagePath: null);
    }
  } catch (e) {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      showAppMessage(
        context,
        'Error verifying face: $e',
        tone: AppDialogTone.error,
      );
    }
    return (success: false, imagePath: null);
  }
}

class _PreparationView extends StatefulWidget {
  final StationInspectionController controller;
  const _PreparationView({required this.controller});

  @override
  State<_PreparationView> createState() => _PreparationViewState();
}

class _PreparationViewState extends State<_PreparationView> {
  final _formKey = GlobalKey<FormState>();

  StationInspectionController get controller => widget.controller;

  List<StationItem> _inspectionStations = [];
  StationItem? _selectedStation;
  bool _isLoadingStations = false;

  @override
  void initState() {
    super.initState();
    _checkDraftAndStations();
  }

  Future<void> _checkDraftAndStations() async {
    controller.isFaceVerified = false;
    controller.faceImagePath = null;
    await _loadInspectionStations();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadInspectionStations() async {
    if (!mounted) return;
    setState(() {
      _isLoadingStations = true;
    });

    try {
      final user = await StorageService.getUser();
      final token = await StorageService.getAccessToken();

      int? sectionId;
      if (user != null) {
        sectionId = user.user?.section;
      }

      final dio = sl<DioClient>();

      final response = await dio.get(
        ApiEndpoints.userStations,
        queryParameters: {'section': sectionId},
        options: Options(
          headers: {
            if (token != null && token.isNotEmpty)
              'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        List<StationItem> parsedStations = [];

        void extractFromList(List list) {
          for (var item in list) {
            if (item is Map) {
              parsedStations.add(
                StationItem.fromJson(Map<String, dynamic>.from(item)),
              );
            } else if (item != null && item.toString().trim().isNotEmpty) {
              final str = item.toString().trim();
              parsedStations.add(StationItem(id: 0, name: str, code: ''));
            }
          }
        }

        if (data is List) {
          extractFromList(data);
        } else if (data is Map) {
          final list =
              data['stations'] ??
              data['data'] ??
              data['results'] ??
              data['user_stations'];
          if (list is List) {
            extractFromList(list);
          }
        }

        if (parsedStations.isNotEmpty) {
          if (mounted) {
            setState(() {
              _inspectionStations = parsedStations;
              if (controller.station != null &&
                  controller.station!.isNotEmpty) {
                final matched = parsedStations.firstWhere(
                  (s) =>
                      s.displayLabel == controller.station ||
                      s.name == controller.station,
                  orElse: () => parsedStations.first,
                );
                _selectedStation = matched;
              } else {
                _selectedStation = parsedStations.first;
                controller.setStation(parsedStations.first.displayLabel);
              }
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading inspection stations in Preparation view: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingStations = false;
        });
      }
    }
  }

  void _showStationPickerBottomSheet(FormFieldState<String> fieldState) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _StationPickerBottomSheet(
          stations: _inspectionStations,
          selectedStation: _selectedStation,
          onStationSelected: (station) {
            setState(() {
              _selectedStation = station;
              controller.setStation(station.displayLabel);
              fieldState.didChange(station.displayLabel);
            });
            Navigator.pop(sheetContext);
          },
        );
      },
    );
  }

  void _handleStartInspection() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    if (!controller.isFaceVerified) {
      final res = await _verifyFaceWithApi(context);
      if (!res.success) {
        return;
      }
      if (mounted) {
        setState(() {
          controller.setFaceVerified(true, res.imagePath);
        });
      }
    }

    controller.startInspection();
    await controller.saveDraftToDisk();

    final recordId = 'station_${controller.station ?? 'general'}'
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '_');
    await StorageService.saveInspectionRecord({
      'id': recordId,
      'train': 'Station Inspection (${controller.station ?? 'General'})',
      'date': DateTime.now().toIso8601String(),
      'status': 'in_progress',
      'payload': {
        'type': 'station',
        'title': 'Station Inspection',
        'stationName': controller.station,
      },
    });

    if (controller.currentStep > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final parentState = context
            .findAncestorStateOfType<_StationInspectionScreenState>();
        parentState?._goToStep(controller.currentStep);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final bool hasDraft =
        controller.fields.isNotEmpty || controller.station != null;
    final double screenHeight = MediaQuery.of(context).size.height;

    const brandGreen = Color(0xFF5CA38E);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // ── 1. Top Background Image Header ──────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: screenHeight * 0.32,
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                brandGreen.withValues(alpha: 0.20),
                BlendMode.darken,
              ),
              child: Image.asset('assets/bg_railway.webp', fit: BoxFit.cover),
            ),
          ),

          // ── 2. Top App Bar & Header Content ───────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const AppBackButton(),
                        const Spacer(),
                        // Most of the room is the pill's, so its logo fits
                        // even on a folding phone's cover screen.
                        Flexible(
                          flex: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  'assets/logo.webp',
                                  width: 28,
                                  height: 28,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(
                                        Icons.train_rounded,
                                        color: brandGreen,
                                        size: 22,
                                      ),
                                ),
                                const SizedBox(width: 8),
                                const Flexible(
                                  child: Text(
                                    'PROMISE HRMS',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF1E293B),
                                      fontSize: 13,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── 3. Bottom Sheet Style Card Container ────────────────────────
          Positioned.fill(
            top: screenHeight * 0.18,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(36),
                  topRight: Radius.circular(36),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(36),
                  topRight: Radius.circular(36),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                  child: Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Drag handle / Title Header
                        Center(
                          child: Container(
                            width: 48,
                            height: 5,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF1FDF9),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.location_on_rounded,
                                color: brandGreen,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Inspection Stations',
                                    style: textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF0F172A),
                                      fontSize: 20,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Signaling & Telecom Station Inspection',
                                    style: TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),
                        const Text(
                          'Select Station',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // --- Station Selector (Modal Bottom Sheet) ---
                        FormField<String>(
                          initialValue: controller.station,
                          validator: (_) {
                            if (controller.station == null ||
                                controller.station!.isEmpty) {
                              return 'Please select a station';
                            }
                            return null;
                          },
                          builder: (fieldState) {
                            if (_isLoadingStations) {
                              return Container(
                                height: 56,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: const Color(0xFFCBD5E1),
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Row(
                                  children: [
                                    SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: brandGreen,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Flexible(
                                      child: Text(
                                        'Loading inspection stations...',
                                        style: TextStyle(
                                          color: Color(0xFF64748B),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            final hasError = fieldState.hasError;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                InkWell(
                                  onTap: () =>
                                      _showStationPickerBottomSheet(fieldState),
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: hasError
                                            ? colorScheme.error
                                            : const Color(0xFFCBD5E1),
                                        width: hasError ? 1.5 : 1.0,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.business_rounded,
                                          color: brandGreen,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _selectedStation != null
                                              ? Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        _selectedStation!.name,
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          fontSize: 13,
                                                          color: Color(
                                                            0xFF0F172A,
                                                          ),
                                                        ),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                    if (_selectedStation!
                                                        .code
                                                        .isNotEmpty) ...[
                                                      const SizedBox(width: 6),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 7,
                                                              vertical: 2,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: const Color(
                                                            0xFFF1FDF9,
                                                          ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                6,
                                                              ),
                                                          border: Border.all(
                                                            color: brandGreen
                                                                .withValues(
                                                                  alpha: 0.3,
                                                                ),
                                                          ),
                                                        ),
                                                        child: Text(
                                                          _selectedStation!
                                                              .code,
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 10,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w800,
                                                                color:
                                                                    brandGreen,
                                                              ),
                                                        ),
                                                      ),
                                                    ],
                                                    if (_selectedStation!.id >
                                                        0) ...[
                                                      const SizedBox(width: 6),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 6,
                                                              vertical: 2,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: const Color(
                                                            0xFFF1F5F9,
                                                          ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                6,
                                                              ),
                                                        ),
                                                        child: Text(
                                                          'ID: ${_selectedStation!.id}',
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 10,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color: Color(
                                                                  0xFF64748B,
                                                                ),
                                                              ),
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                )
                                              : const Text(
                                                  'Select Inspection Station',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Color(0xFF94A3B8),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          color: Color(0xFF64748B),
                                          size: 24,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (hasError)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      top: 6,
                                      left: 12,
                                    ),
                                    child: Text(
                                      fieldState.errorText!,
                                      style: TextStyle(
                                        color: colorScheme.error,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 20),
                        const Text(
                          'Inspection Date',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // --- Date Field ---
                        FormField<DateTime>(
                          initialValue: controller.inspDate,
                          builder: (fieldState) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFFCBD5E1),
                                ),
                                color: const Color(0xFFF8FAFC),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today_outlined,
                                    color: brandGreen,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '${controller.inspDate.day.toString().padLeft(2, '0')}/'
                                    '${controller.inspDate.month.toString().padLeft(2, '0')}/'
                                    '${controller.inspDate.year}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 20),
                        const Text(
                          'Face Verification',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // --- Face Auth Card ---
                        FormField<bool>(
                          initialValue: controller.isFaceVerified,
                          validator: (_) {
                            if (!controller.isFaceVerified) {
                              return 'Please complete face authentication to continue';
                            }
                            return null;
                          },
                          builder: (fieldState) {
                            final hasError = fieldState.hasError;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(
                                      width: hasError ? 1.5 : 1.0,
                                      color: hasError
                                          ? colorScheme.error
                                          : const Color(0xFFCBD5E1),
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () async {
                                      final res = await _verifyFaceWithApi(
                                        context,
                                      );
                                      if (res.success) {
                                        if (mounted) {
                                          setState(() {
                                            controller.setFaceVerified(
                                              true,
                                              res.imagePath,
                                            );
                                            fieldState.didChange(true);
                                          });
                                        }
                                      } else {
                                        if (mounted) {
                                          setState(() {
                                            controller.setFaceVerified(
                                              false,
                                              null,
                                            );
                                            fieldState.didChange(false);
                                          });
                                        }
                                      }
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: const BoxDecoration(
                                              color: Color(0xFFF1FDF9),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              controller.isFaceVerified
                                                  ? Icons.check_circle_rounded
                                                  : Icons.face_rounded,
                                              color: controller.isFaceVerified
                                                  ? InspectionColors.success
                                                  : brandGreen,
                                              size: 26,
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'Face Authentication',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                    color: Color(0xFF0F172A),
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  controller.isFaceVerified
                                                      ? 'Identity Verified ✓'
                                                      : 'Tap to take a selfie for verification',
                                                  style: TextStyle(
                                                    color:
                                                        controller
                                                            .isFaceVerified
                                                        ? InspectionColors
                                                              .success
                                                        : const Color(
                                                            0xFF64748B,
                                                          ),
                                                    fontSize: 12,
                                                    fontWeight:
                                                        controller
                                                            .isFaceVerified
                                                        ? FontWeight.w700
                                                        : FontWeight.normal,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const Icon(
                                            Icons.chevron_right_rounded,
                                            color: Color(0xFF94A3B8),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                if (hasError)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      top: 6,
                                      left: 12,
                                    ),
                                    child: Text(
                                      fieldState.errorText!,
                                      style: TextStyle(
                                        color: colorScheme.error,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 32),

                        // --- Start Button ---
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: brandGreen,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 2,
                            ),
                            onPressed: _handleStartInspection,
                            child: Text(
                              hasDraft
                                  ? 'RESUME INSPECTION'
                                  : 'START INSPECTION',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewBody extends StatefulWidget {
  final InspectionSection section;
  final StationInspectionController controller;
  const _ReviewBody({required this.section, required this.controller});
  @override
  State<_ReviewBody> createState() => _ReviewBodyState();
}

class _ReviewBodyState extends State<_ReviewBody> {
  String? _summary;
  bool _isSubmitting = false;

  Future<void> _handleAction() async {
    if (_summary == null) {
      setState(() {
        _summary = widget.controller.buildSummaryText(kInspectionSections);
      });
    } else {
      final res = await _verifyFaceWithApi(context);
      if (res.success) {
        if (mounted) {
          _submitInspectionToApi();
        }
      }
    }
  }

  Future<void> _submitInspectionToApi() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final user = await StorageService.getUser();
      final token = await StorageService.getAccessToken();

      final submitModel = StationInspectionSubmitModel.fromController(
        widget.controller,
        user: user,
      );

      final dio = sl<DioClient>();

      await dio.post(
        ApiEndpoints.submitStationInspectionComplete,
        data: submitModel.toJson(),
        options: Options(
          headers: {
            if (token != null && token.isNotEmpty)
              'Authorization': 'Bearer $token',
          },
        ),
      );

      await widget.controller.clearDraftFromDisk();

      if (mounted) {
        _showSuccessAndFinish();
      }
    } catch (e) {
      debugPrint('Error submitting station inspection: $e');
      if (mounted) {
        showAppMessage(
          context,
          'Submission Error: $e',
          tone: AppDialogTone.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showSuccessAndFinish() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Column(
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              color: InspectionColors.success,
              size: 64,
            ),
            SizedBox(height: 16),
            Text('Inspection Submitted'),
          ],
        ),
        content: const Text(
          'Your station inspection report has been successfully submitted and verified.',
          textAlign: TextAlign.center,
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                Navigator.pop(context);
                widget.controller.resetInspection();
              },
              child: const Text('DONE'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isSummaryGenerated = _summary != null;

    return Column(
      children: [
        FixedSectionBody(
          section: widget.section,
          controller: widget.controller,
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: FilledButton.icon(
            onPressed: _isSubmitting ? null : _handleAction,
            icon: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    isSummaryGenerated
                        ? Icons.send_rounded
                        : Icons.summarize_rounded,
                  ),
            label: Text(
              _isSubmitting
                  ? 'SUBMITTING...'
                  : (isSummaryGenerated ? 'SUBMIT' : 'GENERATE SUMMARY'),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: isSummaryGenerated
                  ? InspectionColors.success
                  : scheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        if (isSummaryGenerated) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F3FB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.description_outlined,
                      size: 16,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'REPORT PREVIEW',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Text(
                  _summary!,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    height: 1.5,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _StationPickerBottomSheet extends StatefulWidget {
  final List<StationItem> stations;
  final StationItem? selectedStation;
  final ValueChanged<StationItem> onStationSelected;

  const _StationPickerBottomSheet({
    required this.stations,
    required this.selectedStation,
    required this.onStationSelected,
  });

  @override
  State<_StationPickerBottomSheet> createState() =>
      _StationPickerBottomSheetState();
}

class _StationPickerBottomSheetState extends State<_StationPickerBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const brandGreen = Color(0xFF5CA38E);

    final filteredStations = widget.stations.where((station) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final nameMatch = station.name.toLowerCase().contains(q);
      final codeMatch = station.code.toLowerCase().contains(q);
      final idMatch = station.id.toString().contains(q);
      return nameMatch || codeMatch || idMatch;
    }).toList();

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.82,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF1FDF9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.business_rounded,
                      color: brandGreen,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Select Station',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          '${widget.stations.length} stations available',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFF1F5F9),
                      foregroundColor: const Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            if (widget.stations.length > 3)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.trim();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search station by name, code or ID...',
                    hintStyle: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 13,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: brandGreen,
                      size: 20,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear_rounded,
                              size: 18,
                              color: Color(0xFF64748B),
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: brandGreen,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),

            Expanded(
              child: filteredStations.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.search_off_rounded,
                              size: 48,
                              color: Color(0xFFCBD5E1),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No stations matching "$_searchQuery"',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      itemCount: filteredStations.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final station = filteredStations[index];
                        final isSelected =
                            widget.selectedStation?.id == station.id &&
                            widget.selectedStation?.name == station.name;

                        return Material(
                          color: isSelected
                              ? const Color(0xFFF1FDF9)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            onTap: () => widget.onStationSelected(station),
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected
                                      ? brandGreen
                                      : const Color(0xFFE2E8F0),
                                  width: isSelected ? 1.5 : 1.0,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected
                                        ? Icons.radio_button_checked_rounded
                                        : Icons.radio_button_off_rounded,
                                    color: isSelected
                                        ? brandGreen
                                        : const Color(0xFF94A3B8),
                                    size: 22,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          station.name,
                                          style: TextStyle(
                                            fontWeight: isSelected
                                                ? FontWeight.w900
                                                : FontWeight.w700,
                                            fontSize: 14,
                                            color: const Color(0xFF0F172A),
                                          ),
                                        ),
                                        if (station.code.isNotEmpty ||
                                            station.id > 0) ...[
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              if (station.code.isNotEmpty) ...[
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: isSelected
                                                        ? brandGreen.withValues(
                                                            alpha: 0.15,
                                                          )
                                                        : const Color(
                                                            0xFFE2E8F0,
                                                          ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    station.code,
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: isSelected
                                                          ? brandGreen
                                                          : const Color(
                                                              0xFF475569,
                                                            ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                              ],
                                              if (station.id > 0)
                                                Text(
                                                  'ID: ${station.id}',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w500,
                                                    color: Color(0xFF64748B),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: brandGreen,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text(
                    'CLOSE',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF475569),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
