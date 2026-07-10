import 'package:flutter/material.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../shared/widgets/detail_hero.dart';
import '../models/unified_form_models.dart';
import '../utils/unified_form_field_utils.dart';

/// Premium gradient hero derived from the unified field list.
///
/// Kept API-compatible with callers ([avatarRadius] retained but presentation is
/// now driven by [DetailHero]).
class UnifiedEntityDetailHeader extends StatelessWidget {
  final String entityName;
  final List<UnifiedFieldDto> fields;
  final double avatarRadius;
  final String? imageUrl;
  final String? eyebrow;

  const UnifiedEntityDetailHeader({
    super.key,
    required this.entityName,
    required this.fields,
    this.avatarRadius = 48,
    this.imageUrl,
    this.eyebrow,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = unifiedDisplayTitle(entityName, fields, l10n: l10n);
    final resolvedImageUrl = imageUrl?.trim().isNotEmpty == true
        ? imageUrl!.trim()
        : photoUrlFromFields(fields);

    return DetailHero(
      title: title,
      initials: unifiedDetailInitial(entityName, fields, l10n: l10n),
      imageUrl: resolvedImageUrl,
      eyebrow: eyebrow,
      debugTag: 'entity-detail-$entityName',
    );
  }
}
