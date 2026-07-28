import 'package:flutter/material.dart';

import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_palette.dart';

/// Soft shimmer placeholder used instead of abrupt full-screen spinners.
class AppSkeleton extends StatefulWidget {
  final double height;
  final double? width;
  final BorderRadius borderRadius;

  const AppSkeleton({
    super.key,
    this.height = 16,
    this.width,
    this.borderRadius = AppRadius.mdAll,
  });

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = context.palette.neutralSoft;
    final highlight = Theme.of(context).colorScheme.surface;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            gradient: LinearGradient(
              begin: Alignment(-1.0 - _controller.value, 0),
              end: Alignment(1.0 + _controller.value, 0),
              colors: [base, highlight, base],
              stops: const [0.25, 0.5, 0.75],
            ),
          ),
        );
      },
    );
  }
}

/// Common list loading placeholder that avoids layout jumps.
class AppSkeletonList extends StatelessWidget {
  final int itemCount;
  final EdgeInsetsGeometry padding;

  const AppSkeletonList({
    super.key,
    this.itemCount = 6,
    this.padding = const EdgeInsets.all(AppSpacing.page),
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: padding,
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, __) => const AppCardSkeleton(),
    );
  }
}

class AppCardSkeleton extends StatelessWidget {
  const AppCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppRadius.lgAll,
        boxShadow: AppElevation.card(context),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSkeleton(height: 18, width: 160),
          SizedBox(height: AppSpacing.sm),
          AppSkeleton(height: 14),
          SizedBox(height: AppSpacing.xs),
          AppSkeleton(height: 14, width: 220),
        ],
      ),
    );
  }
}
