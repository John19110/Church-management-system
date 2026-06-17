import 'package:flutter/material.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../shared/widgets/app_network_avatar.dart';
import '../models/member_models.dart';

/// Member detail header: photo from API image fields, not unified form metadata.
class MemberDetailHeader extends StatelessWidget {
  final MemberReadDto member;
  final double avatarRadius;

  const MemberDetailHeader({
    super.key,
    required this.member,
    this.avatarRadius = 52,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = member.fullName?.trim().isNotEmpty == true
        ? member.fullName!.trim()
        : l10n.notAvailable;

    member.debugLogImage('member-detail');

    final initial = title != l10n.notAvailable && title.isNotEmpty
        ? title[0].toUpperCase()
        : '?';

    return Column(
      children: [
        AppNetworkAvatar(
          imageUrl: member.displayImageUrl,
          debugTag: 'member-detail-${member.id}',
          radius: avatarRadius,
          backgroundColor: const Color(0xFF4299E1),
          placeholder: Text(
            initial,
            style: TextStyle(
              fontSize: avatarRadius * 0.75,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
