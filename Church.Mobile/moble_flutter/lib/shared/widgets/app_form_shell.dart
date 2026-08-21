import 'package:flutter/material.dart';

import '../../core/theme/app_dimens.dart';

/// Dynamic [TextField.scrollPadding] used by all app inputs.
///
/// Flutter scrolls the focused field into view with this padding relative to the
/// **nearest scrollable viewport**. Combined with
/// [Scaffold.resizeToAvoidBottomInset] (Android `adjustResize`), that keeps the
/// field above the keyboard on any device size or keyboard height.
///
/// - When the scaffold has already resized and stripped bottom view insets from
///   the body, [MediaQuery.viewInsets.bottom] is `0` here — clearance comes from
///   the resized viewport plus the design-token gap.
/// - When insets remain (dialogs, sheets, or `resizeToAvoidBottomInset: false`),
///   the real keyboard height is included so [Scrollable.ensureVisible] still
///   clears it. Never hardcode a keyboard height.
EdgeInsets appFieldScrollPadding(BuildContext context) {
  final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
  return EdgeInsets.fromLTRB(
    AppSpacing.md,
    AppSpacing.md,
    AppSpacing.md,
    AppSpacing.xl + keyboardInset,
  );
}

/// Resolves form/list padding, optionally growing with remaining view insets.
///
/// Prefer this inside [AppFormScrollView] / [AppFormListView] so last fields and
/// bottom actions stay reachable after focus scrolls. Uses live
/// [MediaQuery.viewInsets] — never a fixed keyboard size.
EdgeInsets appFormPadding(
  BuildContext context, {
  EdgeInsets base = const EdgeInsets.all(AppSpacing.page),
  double extraBottom = AppSpacing.xl,
}) {
  final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
  return base.copyWith(bottom: base.bottom + keyboardInset + extraBottom);
}

EdgeInsets _resolveFormPadding(
  BuildContext context,
  EdgeInsetsGeometry? padding,
) {
  if (padding == null) return appFormPadding(context);
  final resolved = padding.resolve(Directionality.of(context));
  return appFormPadding(context, base: resolved);
}

/// Dismisses the soft keyboard when the user taps outside an input.
class AppKeyboardDismiss extends StatelessWidget {
  final Widget child;

  const AppKeyboardDismiss({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      // Tap-to-unfocus is not an accessibility action; including it in the
      // semantics tree wraps the whole subtree in a gesture handler and can
      // leave semantics parentData dirty (esp. with ReorderableListView).
      excludeFromSemantics: true,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: child,
    );
  }
}

/// Keyboard-aware scrollable form body for use inside [Scaffold.body].
///
/// Standard pattern for multi-field screens (and short centered forms):
/// ```dart
/// Scaffold(
///   resizeToAvoidBottomInset: true, // default — keep enabled
///   body: SafeArea(
///     child: AppFormScrollView(
///       child: Column(children: [ /* AppTextField… */ ]),
///     ),
///   ),
/// )
/// ```
///
/// Sets a viewport [minHeight] so short content can still scroll when the
/// keyboard shrinks the body, and so [MainAxisAlignment.center] works inside.
/// Do not wrap this in another [SingleChildScrollView].
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
    final resolvedPadding = _resolveFormPadding(context, padding);

    return AppKeyboardDismiss(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final minBodyHeight =
              (constraints.maxHeight - resolvedPadding.vertical)
                  .clamp(0.0, double.infinity)
                  .toDouble();

          return SingleChildScrollView(
            controller: controller,
            primary: controller == null ? primary : false,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: resolvedPadding,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: constraints.hasBoundedWidth
                    ? constraints.maxWidth
                    : 0,
                minHeight: constraints.hasBoundedHeight ? minBodyHeight : 0,
              ),
              child: crossAxisAlignment == CrossAxisAlignment.stretch
                  ? child
                  : Align(alignment: Alignment.topCenter, child: child),
            ),
          );
        },
      ),
    );
  }
}

/// Keyboard-aware [ListView] for form screens that already use list children.
///
/// Prefer this over a raw [ListView] for forms so padding tracks remaining
/// view insets and drag-to-dismiss matches [AppFormScrollView].
/// Do not nest inside [AppFormScrollView].
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
    final resolvedPadding = _resolveFormPadding(context, padding);

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

/// Scrollable dialog/sheet body that stays above the soft keyboard.
///
/// Dialogs often keep full view insets; padding uses live
/// [MediaQuery.viewInsets.bottom] so height adapts to any keyboard.
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

/// Thin [Scaffold] wrapper that documents/enforces keyboard-safe defaults.
///
/// New screens should prefer this (or a plain [Scaffold] with
/// `resizeToAvoidBottomInset: true`) and put forms in [AppFormScrollView] /
/// [AppFormListView] so focused fields stay visible automatically.
class AppScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Widget? bottomSheet;
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;
  final bool extendBody;
  final bool extendBodyBehindAppBar;
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  const AppScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.bottomSheet,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    this.floatingActionButtonLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: body,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: bottomNavigationBar,
      bottomSheet: bottomSheet,
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      extendBody: extendBody,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
    );
  }
}
