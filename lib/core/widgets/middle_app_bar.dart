import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';

/// A clean page header — back arrow + bold title on the green background.
class MiddleAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final bool automaticallyImplyLeading;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(48);

  const MiddleAppBar({
    super.key,
    this.title,
    this.automaticallyImplyLeading = true,
    this.onBackPressed,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);
    final showBack = automaticallyImplyLeading && canPop;

    return SizedBox(
      height: 48,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showBack) ...[
            _BackButton(
              onPressed: onBackPressed ?? () => Navigator.pop(context),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              title ?? '',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                fontFamily: 'DM Sans',
                letterSpacing: -0.4,
                height: 1.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ...?actions,
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _BackButton({required this.onPressed});

  @override
  Widget build(BuildContext context) => AppBackButton(onPressed: onPressed);
}
