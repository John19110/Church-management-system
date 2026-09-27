import 'package:dio/dio.dart';

import '../../../core/api/dio_client.dart';
import '../../../core/constants/app_constants.dart';
import '../models/language_settings.dart';

class LanguageSettingsRepository {
  final Dio _dio;

  LanguageSettingsRepository(this._dio);

  Future<ChurchLanguages> getOrganizationLanguages(String publicId) {
    return apiCall(() async {
      final response = await _dio.get(
        AppConstants.organizationLanguagesEndpoint,
        queryParameters: {'publicId': publicId},
      );
      return ChurchLanguages.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    });
  }

  Future<LanguageProfile> getLanguageProfile() {
    return apiCall(() async {
      final response = await _dio.get(AppConstants.languageProfileEndpoint);
      return LanguageProfile.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    });
  }

  Future<void> updatePreferredLanguage(String language) {
    return apiCall(() async {
      await _dio.put(
        AppConstants.preferredLanguageEndpoint,
        data: {'preferredLanguage': language},
      );
    });
  }

  Future<ChurchLanguages> getChurch(int churchId) {
    return apiCall(() async {
      final response = await _dio.get(
        '${AppConstants.churchEndpoint}/$churchId',
      );
      return ChurchLanguages.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    });
  }

  Future<void> updateChurchLanguages({
    required int churchId,
    required List<String> supportedLanguages,
    required String defaultLanguage,
  }) {
    return apiCall(() async {
      await _dio.put(
        '${AppConstants.churchEndpoint}/$churchId/languages',
        data: {
          'supportedLanguages': supportedLanguages,
          'defaultLanguage': defaultLanguage,
        },
      );
    });
  }
}
