import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../theme/app_colors.dart';

/// Swipe-down refresh for a page's scrollable content. A failed reload
/// (server down, no network) shows its message instead of failing silently.
///
/// [child] must scroll even when its content is short, so give lists
/// `AlwaysScrollableScrollPhysics`, and wrap non-scrolling placeholders
/// (empty states) in [PullToRefresh.fillViewport].
class PullToRefresh extends StatelessWidget {
  const PullToRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  final Future<void> Function() onRefresh;
  final Widget child;

  /// Makes a non-scrolling [child] pullable while keeping it centred in
  /// the available height.
  static Widget fillViewport(Widget child) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(height: constraints.maxHeight, child: child),
        );
      },
    );
  }

  Future<void> _refresh(BuildContext context) async {
    try {
      await onRefresh();
    } catch (error) {
      // Parallel loads wrap the ApiException in a ParallelWaitError, so
      // anything that isn't an ApiException gets a generic message.
      final String message = error is ApiException
          ? error.message
          : 'Gagal memuat data, coba lagi';
      if (context.mounted) {
        ScaffoldMessenger.maybeOf(
          context,
        )?.showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => _refresh(context),
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      child: child,
    );
  }
}
