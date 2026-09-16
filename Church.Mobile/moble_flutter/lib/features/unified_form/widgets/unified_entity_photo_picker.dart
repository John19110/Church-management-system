import 'package:flutter/material.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/media/picked_image.dart';
import '../../../shared/widgets/app_network_avatar.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../models/unified_form_models.dart';
import '../utils/unified_form_field_utils.dart';

/// Photo control for entities whose `imageUrl` field is hidden from the text form.
class UnifiedEntityPhotoPicker extends StatelessWidget {
  final List<UnifiedFieldDto> fields;
  final PickedImage? pickedImage;
  final VoidCallback onPick;
  final double radius;
  final String? imageUrl;

  const UnifiedEntityPhotoPicker({
    super.key,
    required this.fields,
    required this.pickedImage,
    required this.onPick,
    this.radius = 48,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        GestureDetector(
          onTap: onPick,
          child: Center(
            child: pickedImage != null
                ? CircleAvatar(
                    radius: radius,
                    backgroundImage: pickedImage!.memoryImage,
                  )
                : AppNetworkAvatar(
                    imageUrl: imageUrl ?? photoUrlFromFields(fields),
                    debugTag: 'entity-photo-picker',
                    radius: radius,
                    placeholder: Icon(Icons.camera_alt, size: radius * 0.75),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.tapToChangePhoto,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Gallery picker used by entity photo screens. Returns `null` on cancel.
Future<PickedImage?> pickUnifiedEntityPhoto(BuildContext context) async {
  try {
    return await pickImageFromGallery();
  } catch (e, st) {
    debugPrint('pickUnifiedEntityPhoto: $e\n$st');
    if (context.mounted) {
      showErrorSnackbar(
        context,
        userFriendlyMessage(e, AppLocalizations.of(context)),
      );
    }
    return null;
  }
}
