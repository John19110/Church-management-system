import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Pops when a previous route exists; otherwise navigates to [fallbackRoute].
/// Keeps AppBar and Android system back consistent across the registration flow.
void popRegistrationOrGo(BuildContext context, String fallbackRoute) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(fallbackRoute);
  }
}

/// Intercepts system back and wires AppBar leading to the same handler.
Widget registrationBackScope({
  required BuildContext context,
  required String fallbackRoute,
  required Widget child,
}) {
  return PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (didPop) return;
      popRegistrationOrGo(context, fallbackRoute);
    },
    child: child,
  );
}

PreferredSizeWidget registrationAppBar({
  required BuildContext context,
  required String title,
  required String fallbackRoute,
}) {
  return AppBar(
    title: Text(title),
    leading: BackButton(
      onPressed: () => popRegistrationOrGo(context, fallbackRoute),
    ),
  );
}
