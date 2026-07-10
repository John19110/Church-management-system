import 'package:flutter/material.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../shared/widgets/detail_hero.dart';
import '../models/member_models.dart';

/// Member detail hero: photo from API image fields, not unified form metadata.
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

    final gender = member.gender?.trim();

    return DetailHero(
      title: title,
      initials: initial,
      imageUrl: member.displayImageUrl,
      eyebrow: l10n.memberDetails,
      debugTag: 'member-detail-${member.id}',
      chips: [
        if (gender != null && gender.isNotEmpty)
          HeroChip(label: gender, icon: Icons.person_outline),
      ],
    );
  }
}
