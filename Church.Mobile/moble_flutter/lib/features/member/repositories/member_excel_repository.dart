import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/dio_client.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/providers/auth_providers.dart';
import '../models/member_excel_models.dart';

final memberExcelRepositoryProvider = Provider((ref) {
  return MemberExcelRepository(ref.watch(dioProvider));
});

class MemberExcelRepository {
  final Dio _dio;

  MemberExcelRepository(this._dio);

  String _culture(String languageCode) =>
      languageCode.toLowerCase().startsWith('ar') ? 'ar' : 'en';

  String _meetingBase(int meetingId) =>
      '${AppConstants.meetingEndpoint}/$meetingId/members/excel';

  String get _churchBase => '/api/church/members/excel';

  Future<List<MemberExcelExportFieldDto>> getExportFields({
    required bool churchWide,
    int? meetingId,
    required String languageCode,
  }) {
    return apiCall(() async {
      final path = churchWide
          ? '$_churchBase/columns'
          : '${_meetingBase(meetingId!)}/columns';
      final response = await _dio.get(
        path,
        queryParameters: {'culture': _culture(languageCode)},
      );
      final list = response.data as List<dynamic>;
      return list
          .whereType<Map<String, dynamic>>()
          .map(MemberExcelExportFieldDto.fromJson)
          .toList();
    });
  }

  Future<({List<int> bytes, String fileName})> downloadTemplate({
    required bool churchWide,
    int? meetingId,
    required String languageCode,
  }) {
    return apiCall(() async {
      final path = churchWide
          ? '$_churchBase/template'
          : '${_meetingBase(meetingId!)}/template';
      final response = await _dio.get<List<int>>(
        path,
        queryParameters: {'culture': _culture(languageCode)},
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = _asBytes(response.data);
      final fileName = _fileNameFromHeaders(response.headers) ??
          (churchWide
              ? 'members-template-church.xlsx'
              : 'members-template-meeting.xlsx');
      return (bytes: bytes, fileName: fileName);
    });
  }

  Future<MemberExcelPreviewDto> previewImport({
    required bool churchWide,
    int? meetingId,
    required String languageCode,
    required String fileName,
    required List<int> bytes,
  }) {
    return apiCall(() async {
      final path = churchWide
          ? '$_churchBase/preview'
          : '${_meetingBase(meetingId!)}/preview';
      final form = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: fileName),
      });
      final response = await _dio.post(
        path,
        data: form,
        queryParameters: {'culture': _culture(languageCode)},
      );
      return MemberExcelPreviewDto.fromJson(
        response.data as Map<String, dynamic>,
      );
    });
  }

  Future<MemberExcelImportResultDto> importMembers({
    required bool churchWide,
    int? meetingId,
    required String languageCode,
    required String fileName,
    required List<int> bytes,
    required String duplicateMode,
  }) {
    return apiCall(() async {
      final path = churchWide
          ? '$_churchBase/import'
          : '${_meetingBase(meetingId!)}/import';
      final form = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: fileName),
      });
      final response = await _dio.post(
        path,
        data: form,
        queryParameters: {
          'culture': _culture(languageCode),
          'duplicateMode': duplicateMode,
        },
      );
      return MemberExcelImportResultDto.fromJson(
        response.data as Map<String, dynamic>,
      );
    });
  }

  Future<({List<int> bytes, String fileName})> exportMembers({
    required bool churchWide,
    int? meetingId,
    required String languageCode,
    required List<String> fields,
  }) {
    return apiCall(() async {
      final path = churchWide
          ? '$_churchBase/export'
          : '${_meetingBase(meetingId!)}/export';
      final response = await _dio.get<List<int>>(
        path,
        queryParameters: {
          'culture': _culture(languageCode),
          if (fields.isNotEmpty) 'fields': fields.join(','),
        },
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = _asBytes(response.data);
      final fileName = _fileNameFromHeaders(response.headers) ??
          (churchWide
              ? 'members-export-church.xlsx'
              : 'members-export-meeting.xlsx');
      return (bytes: bytes, fileName: fileName);
    });
  }

  String? _fileNameFromHeaders(Headers headers) {
    final disposition = headers.value('content-disposition');
    if (disposition == null) return null;
    // filename*=UTF-8''name.xlsx
    final star = RegExp(
      r"filename\*\s*=\s*(?:UTF-8''|utf-8'')([^;]+)",
      caseSensitive: false,
    ).firstMatch(disposition);
    if (star != null) {
      final raw = star.group(1)?.trim();
      if (raw != null && raw.isNotEmpty) {
        try {
          return Uri.decodeComponent(raw.replaceAll('"', ''));
        } catch (_) {
          return raw.replaceAll('"', '');
        }
      }
    }
    final match = RegExp(
      r'filename\s*=\s*"([^"]+)"|filename\s*=\s*([^;]+)',
      caseSensitive: false,
    ).firstMatch(disposition);
    final name = (match?.group(1) ?? match?.group(2))?.trim();
    if (name == null || name.isEmpty) return null;
    return name.replaceAll('"', '');
  }

  List<int> _asBytes(dynamic data) {
    if (data == null) return const <int>[];
    if (data is List<int>) return data;
    if (data is List) return List<int>.from(data);
    throw StateError('Unexpected binary response type: ${data.runtimeType}');
  }
}