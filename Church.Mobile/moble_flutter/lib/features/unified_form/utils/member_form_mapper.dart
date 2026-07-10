import 'dart:convert';

import '../../member/models/member_models.dart';
import '../models/unified_form_models.dart';
import 'unified_form_controller.dart';

/// Maps unified field values to legacy Member DTOs for create (multipart path).
class MemberFormMapper {
  static MemberAddDto toAddDto(UnifiedFormController controller, List<UnifiedFieldDefinitionDto> fields) {
    UnifiedFieldDefinitionDto? find(String key) {
      for (final f in fields) {
        if (f.fieldKey == key) return f;
      }
      return null;
    }

    String? v(String key) {
      final field = find(key);
      if (field == null) return null;
      return controller.valueFor(field);
    }

    return MemberAddDto(
      name1: v('name1'),
      name2: v('name2'),
      name3: v('name3'),
      gender: v('gender'),
      address: v('address'),
      dateOfBirth: v('dateOfBirth'),
      joiningDate: v('joiningDate'),
      spiritualDateOfBirth: v('spiritualDateOfBirth'),
      haveBrothers: controller.boolFor('haveBrothers'),
      brothersNames: _parseStringList(v('brothersNames')),
      notes: _parseStringList(v('notes')),
      phoneNumbers: _parsePhones(v('phoneNumbers')),
    );
  }

  static List<String>? _parseStringList(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
    } catch (_) {
      return null;
    }
  }

  static List<MemberContactDto>? _parsePhones(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) {
        final m = e as Map<String, dynamic>;
        return MemberContactDto(
          relation: m['relation'] as String?,
          phoneNumber: m['phoneNumber'] as String?,
        );
      }).toList();
    } catch (_) {
      return null;
    }
  }
}
