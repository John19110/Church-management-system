import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/api/select_api.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/cache/cache_manager.dart';
import '../models/member_models.dart';
import '../../../core/models/select_option.dart';

class MembersRepository {
  final Dio _dio;
  final CacheManager _cache;

  MembersRepository(this._dio, this._cache);

  static String _fileName(String path) {
    final normalized = path.replaceAll('\\', '/');
    final index = normalized.lastIndexOf('/');
    return index >= 0 ? normalized.substring(index + 1) : normalized;
  }

  void _requireMemberId(int id) {
    if (id <= 0) {
      throw ArgumentError.value(
        id,
        'id',
        'Member id must be a positive integer',
      );
    }
  }

  Future<List<MemberReadDto>> getAll() async {
    return apiCall(() async {
      final response = await _dio.get(AppConstants.membersEndpoint);
      final list = response.data as List<dynamic>;
      final members = list
          .map((e) => MemberReadDto.fromJson(e as Map<String, dynamic>))
          .toList();
      if (kDebugMode) {
        for (final m in members) {
          m.debugLogImage('api-getAll');
        }
      }
      return members;
    });
  }

  Stream<List<MemberReadDto>> watchAllCacheFirst({
    required int tenantId,
    required String role,
  }) {
    final key = _cache.tenantRoleKey(tenantId, role, 'member_list_all');
    return _cache.cacheFirstStream<List<MemberReadDto>>(
      key: key,
      ttl: const Duration(minutes: 5),
      fetch: getAll,
      toJson: (value) => {
        'items': value.map((e) => e.toJson()).toList(),
      },
      fromJson: (json) {
        final items = (json['items'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(MemberReadDto.fromJson)
            .toList();
        return items;
      },
    );
  }

  Future<List<MemberReadDto>> getByClassroom(int classroomId) async {
    return apiCall(() async {
      final response = await _dio.get(
        '${AppConstants.membersEndpoint}/classroom/$classroomId',
      );
      final list = response.data as List<dynamic>;
      final members = list
          .map((e) => MemberReadDto.fromJson(e as Map<String, dynamic>))
          .toList();
      if (kDebugMode) {
        for (final m in members) {
          m.debugLogImage('api-classroom-$classroomId');
        }
      }
      return members;
    });
  }

  Stream<List<MemberReadDto>> watchByClassroomCacheFirst({
    required int tenantId,
    required String role,
    required int classroomId,
  }) {
    final key =
        _cache.tenantRoleKey(tenantId, role, 'member_list_classroom_$classroomId');
    return _cache.cacheFirstStream<List<MemberReadDto>>(
      key: key,
      ttl: const Duration(minutes: 5),
      fetch: () => getByClassroom(classroomId),
      toJson: (value) => {
        'items': value.map((e) => e.toJson()).toList(),
      },
      fromJson: (json) {
        final items = (json['items'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(MemberReadDto.fromJson)
            .toList();
        return items;
      },
    );
  }

  Future<MemberReadDto> getById(int id) async {
    _requireMemberId(id);
    return apiCall(() async {
      final response = await _dio.get('${AppConstants.membersEndpoint}/$id');
      final member =
          MemberReadDto.fromJson(response.data as Map<String, dynamic>);
      member.debugLogImage('api-getById-$id');
      return member;
    });
  }

  Stream<MemberReadDto> watchByIdCacheFirst({
    required int tenantId,
    required int memberId,
  }) {
    final key = _cache.tenantKey(tenantId, 'members_$memberId');
    return _cache.cacheFirstStream<MemberReadDto>(
      key: key,
      ttl: const Duration(minutes: 5),
      fetch: () => getById(memberId),
      toJson: (value) => value.toJson(),
      fromJson: MemberReadDto.fromJson,
    );
  }

  /// Create member: POST /api/classrooms/{classroomId}/members (multipart/form-data)
  /// [classroomId] is passed as a URL path parameter.
  Future<int> create(int classroomId, MemberAddDto dto, {File? image}) async {
    return apiCall(() async {
      final map = <String, dynamic>{
        if (dto.name1 != null) 'Name1': dto.name1,
        if (dto.name2 != null) 'Name2': dto.name2,
        if (dto.name3 != null) 'Name3': dto.name3,
        if (dto.gender != null) 'Gender': dto.gender,
        if (dto.address != null) 'Address': dto.address,
        if (dto.dateOfBirth != null) 'DateOfBirth': dto.dateOfBirth,
        if (dto.joiningDate != null) 'JoiningDate': dto.joiningDate,
        if (dto.spiritualDateOfBirth != null)
          'SpiritualDateOfBirth': dto.spiritualDateOfBirth,
        if (dto.haveBrothers != null)
          'HaveBrothers': dto.haveBrothers.toString(),
        if (image != null)
          'Image': await MultipartFile.fromFile(
            image.path,
            filename: _fileName(image.path),
          ),
      };
      _appendCollections(map, dto);
      final response = await _dio.post(
        '${AppConstants.classroomMembersBasePath}/$classroomId/members',
        data: FormData.fromMap(map),
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final id = data['id'] ?? data['Id'];
        if (id is int) return id;
        if (id is num) return id.toInt();
      }
      throw const FormatException('Create member response did not include id.');
    });
  }

  /// Update member: JSON when no new image; multipart form when image is provided.
  Future<void> updateMember(
    int id,
    MemberUpdateDto dto, {
    File? image,
  }) async {
    _requireMemberId(id);
    if (image != null) {
      return _updateViaForm(id, dto, image: image);
    }
    return apiCall(() async {
      await _dio.put('${AppConstants.membersEndpoint}/$id', data: dto.toJson());
    });
  }

  /// Legacy helper kept for callers that always upload an image.
  Future<void> updateWithImage(
    int id,
    MemberUpdateDto dto, {
    required File image,
  }) =>
      updateMember(id, dto, image: image);

  Future<void> _updateViaForm(
    int id,
    MemberUpdateDto dto, {
    required File image,
  }) async {
    return apiCall(() async {
      final map = _memberFormMap(dto, id: id);
      map['Image'] = await MultipartFile.fromFile(
        image.path,
        filename: _fileName(image.path),
      );
      await _dio.put(
        '${AppConstants.membersEndpoint}/$id/form',
        data: FormData.fromMap(map),
      );
    });
  }

  Map<String, dynamic> _memberFormMap(MemberUpdateDto dto, {required int id}) {
    final map = <String, dynamic>{
      'Id': id.toString(),
      if (dto.name1 != null) 'Name1': dto.name1,
      if (dto.name2 != null) 'Name2': dto.name2,
      if (dto.name3 != null) 'Name3': dto.name3,
      if (dto.gender != null) 'Gender': dto.gender,
      if (dto.address != null) 'Address': dto.address,
      if (dto.dateOfBirth != null) 'DateOfBirth': dto.dateOfBirth,
      if (dto.joiningDate != null) 'JoiningDate': dto.joiningDate,
      if (dto.spiritualDateOfBirth != null)
        'SpiritualDateOfBirth': dto.spiritualDateOfBirth,
      if (dto.lastAttendanceDate != null)
        'LastAttendanceDate': dto.lastAttendanceDate,
      if (dto.isDiscipline != null)
        'IsDiscipline': dto.isDiscipline.toString(),
      if (dto.classroomId != null) 'ClassroomId': dto.classroomId.toString(),
      if (dto.haveBrothers != null) 'HaveBrothers': dto.haveBrothers.toString(),
    };
    _appendCollections(map, dto);
    return map;
  }

  void _appendCollections(Map<String, dynamic> map, MemberAddDto dto) {
    if (dto.notes != null) {
      for (var i = 0; i < dto.notes!.length; i++) {
        map['Notes[$i]'] = dto.notes![i];
      }
    }
    if (dto.brothersNames != null) {
      for (var i = 0; i < dto.brothersNames!.length; i++) {
        map['BrothersNames[$i]'] = dto.brothersNames![i];
      }
    }
    if (dto.phoneNumbers != null) {
      for (var i = 0; i < dto.phoneNumbers!.length; i++) {
        map['PhoneNumbers[$i].Relation'] =
            dto.phoneNumbers![i].relation ?? '';
        map['PhoneNumbers[$i].PhoneNumber'] =
            dto.phoneNumbers![i].phoneNumber ?? '';
      }
    }
  }

  Future<void> delete(int id) async {
    _requireMemberId(id);
    return apiCall(() async {
      await _dio.delete('${AppConstants.membersEndpoint}/$id');
    });
  }

  /// GET /api/Meeting/{meetingId}/members — members belonging to a specific meeting.
  Future<List<MemberReadDto>> getByMeeting(int meetingId) async {
    return apiCall(() async {
      final response =
          await _dio.get(AppConstants.meetingMembersEndpoint(meetingId));
      final list = response.data as List<dynamic>;
      return list
          .map((e) => MemberReadDto.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  Stream<List<MemberReadDto>> watchByMeetingCacheFirst({
    required int tenantId,
    required String role,
    required int meetingId,
  }) {
    final key =
        _cache.tenantRoleKey(tenantId, role, 'member_list_meeting_$meetingId');
    return _cache.cacheFirstStream<List<MemberReadDto>>(
      key: key,
      ttl: const Duration(minutes: 5),
      fetch: () => getByMeeting(meetingId),
      toJson: (value) => {
        'items': value.map((e) => e.toJson()).toList(),
      },
      fromJson: (json) {
        final items = (json['items'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(MemberReadDto.fromJson)
            .toList();
        return items;
      },
    );
  }

  /// GET /api/Members/select — get members for selection dropdown
  Future<List<SelectOption>> getForSelection() async {
    return fetchSelectOptions(_dio, AppConstants.membersSelectEndpoint);
  }
}
