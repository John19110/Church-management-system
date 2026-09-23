import 'package:flutter/material.dart';

/// Shared icon language. Prefer these over mixing filled/outlined variants.
class AppIcons {
  AppIcons._();

  static const IconData home = Icons.home_outlined;
  static const IconData homeSelected = Icons.home;
  static const IconData notifications = Icons.notifications_outlined;
  static const IconData notificationsSelected = Icons.notifications;
  static const IconData servants = Icons.people_outline;
  static const IconData servantsSelected = Icons.people;
  static const IconData approvals = Icons.pending_actions_outlined;
  static const IconData approvalsSelected = Icons.pending_actions;
  static const IconData profile = Icons.person_outline;
  static const IconData profileSelected = Icons.person;
  static const IconData settings = Icons.settings_outlined;
  static const IconData edit = Icons.edit_outlined;
  static const IconData delete = Icons.delete_outline;
  static const IconData add = Icons.add;
  static const IconData search = Icons.search;
  static const IconData logout = Icons.logout;
  static const IconData close = Icons.close;

  /// Forward chevron that flips in RTL.
  static Icon chevronForward(BuildContext context, {Color? color, double? size}) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Icon(
      rtl ? Icons.chevron_left : Icons.chevron_right,
      color: color,
      size: size,
    );
  }
}
