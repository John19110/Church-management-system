import 'package:flutter/material.dart';

import '../../core/theme/app_dimens.dart';

/// Extra space kept below a focused field so the keyboard never covers it.
const EdgeInsets kAppFieldScrollPadding = EdgeInsets.fromLTRB(
  AppSpacing.md,
  AppSpacing.md,
  AppSpacing.md,
  120,
);

/// Dismisses the soft keyboard when the user taps outside an input.
class AppKeyboardDismiss extends StatelessWidget {
  final Widget child;

  const AppKeyboardDismiss({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: child,
    );
  }
}

/// Page padding that grows with the keyboard so bottom actions stay reachable.
EdgeInsets appFormPadding(
  BuildContext context, {
  EdgeInsets base = const EdgeInsets.all(AppSpacing.page),
  double extraBottom = AppSpacing.xl,
}) {
  final keyboard = MediaQuery.viewInsetsOf(context).bottom;
  return base.copyWith(bottom: base.bottom + keyboard + extraBottom);
}

/// Scrollable form body with keyboard-aware padding and drag-to-dismiss.
///
/// Use inside [Scaffold.body] for any multi-field form. Preserves the existing
/// visual language while fixing covered inputs and unreachable bottom buttons.
class AppFormScrollView extends StatelessWidget {
  final Widget child;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;
  final bool primary;
  final CrossAxisAlignment crossAxisAlignment;

  const AppFormScrollView({
    super.key,
    required this.child,
    this.controller,
    this.padding,
    this.primary = true,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedPadding = padding is EdgeInsets
        ? appFormPadding(context, base: padding as EdgeInsets)
        : appFormPadding(context);

    return AppKeyboardDismiss(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            controller: controller,
            primary: controller == null ? primary : false,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: resolvedPadding,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: child,
            ),
          );
        },
      ),
    );
  }
}

/// ListView padding helper for form screens that already use [ListView].
class AppFormListView extends StatelessWidget {
  final List<Widget> children;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const AppFormListView({
    super.key,
    required this.children,
    this.controller,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedPadding = padding is EdgeInsets
        ? appFormPadding(context, base: padding as EdgeInsets)
        : appFormPadding(context);

    return AppKeyboardDismiss(
      child: ListView(
        controller: controller,
        shrinkWrap: shrinkWrap,
        physics: physics,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: resolvedPadding,
        children: children,
      ),
    );
  }
}

/// Scrollable dialog body that stays above the soft keyboard.
class AppDialogFormBody extends StatelessWidget {
  final Widget child;

  const AppDialogFormBody({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return AppKeyboardDismiss(
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.only(bottom: bottomInset),
        child: child,
      ),
    );
  }
}
