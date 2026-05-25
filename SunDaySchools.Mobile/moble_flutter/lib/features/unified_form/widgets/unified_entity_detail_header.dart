import 'package:flutter/material.dart';

import '../../../shared/widgets/app_network_avatar.dart';
import '../models/unified_form_models.dart';
import '../utils/unified_form_field_utils.dart';

/// Avatar + title derived from the same unified field list as detail rows.
class UnifiedEntityDetailHeader extends StatelessWidget {
  final String entityName;
  final List<UnifiedFieldDto> fields;
  final double avatarRadius;

  const UnifiedEntityDetailHeader({
    super.key,
    required this.entityName,
    required this.fields,
    this.avatarRadius = 48,
  });

  @override
  Widget build(BuildContext context) {
    final title = unifiedDisplayTitle(entityName, fields);
    final imageUrl = photoUrlFromFields(fields);

    return Column(
      children: [
        AppNetworkAvatar(
          imageUrl: imageUrl,
          radius: avatarRadius,
          backgroundColor: const Color(0xFF4299E1),
          placeholder: Text(
            unifiedDetailInitial(entityName, fields),
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
