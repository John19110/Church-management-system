import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../models/language_settings.dart';
import '../repositories/language_settings_repository.dart';

final languageSettingsRepositoryProvider = Provider((ref) {
  return LanguageSettingsRepository(ref.watch(dioProvider));
});

final languageProfileProvider = FutureProvider<LanguageProfile?>((ref) async {
  ref.watch(authSessionEpochProvider);
  if (!await hasStoredAuthToken()) return null;
  return ref.watch(languageSettingsRepositoryProvider).getLanguageProfile();
});

final churchLanguagesProvider = FutureProvider<ChurchLanguages>((ref) async {
  final profile = await ref.watch(languageProfileProvider.future);
  return profile?.church ?? ChurchLanguages.bilingual();
});
