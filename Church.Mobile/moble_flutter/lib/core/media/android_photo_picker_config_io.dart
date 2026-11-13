import 'dart:io' show Platform;

import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

/// Enables Android Photo Picker so gallery selection does not need READ_MEDIA_*.
///
/// On Android 13+ image_picker already uses Photo Picker; this also enables the
/// backport path on Android 12 and below.
void configureAndroidPhotoPicker() {
  if (!Platform.isAndroid) return;
  final implementation = ImagePickerPlatform.instance;
  if (implementation is ImagePickerAndroid) {
    implementation.useAndroidPhotoPicker = true;
  }
}
