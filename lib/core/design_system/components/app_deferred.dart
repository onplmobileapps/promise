import 'package:flutter/widgets.dart';
import 'package:railway_hrms/core/design_system/components/app_loader.dart';

/// Builds a heavy page a frame late, showing the app's loader until then,
/// so the tap that opened it answers at once instead of the screen
/// freezing while it is built.
class AppDeferred extends StatefulWidget {
  const AppDeferred({super.key, required this.builder});

  final WidgetBuilder builder;

  @override
  State<AppDeferred> createState() => _AppDeferredState();
}

class _AppDeferredState extends State<AppDeferred> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) =>
      _ready ? widget.builder(context) : AppLoader.page();
}
