import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../shared/widgets/app_network_avatar.dart';
import '../models/unified_form_models.dart';
import '../utils/unified_form_field_utils.dart';

/// Photo control for entities whose `imageUrl` field is hidden from the text form.
class UnifiedEntityPhotoPicker extends StatelessWidget {
  final List<UnifiedFieldDto> fields;
  final File? pickedFile;
  final VoidCallback onPick;
  final double radius;

  const UnifiedEntityPhotoPicker({
    super.key,
    required this.fields,
    required this.pickedFile,
    required this.onPick,
    this.radius = 48,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPick,
      child: Center(
        child: pickedFile != null
            ? CircleAvatar(
                radius: radius,
                backgroundImage: FileImage(pickedFile!),
              )
            : AppNetworkAvatar(
                imageUrl: photoUrlFromFields(fields),
                radius: radius,
                placeholder: Icon(Icons.camera_alt, size: radius * 0.75),
              ),
      ),
    );
  }
}

Future<File?> pickUnifiedEntityPhoto() async {
  final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
  if (picked == null) return null;
  return File(picked.path);
}
