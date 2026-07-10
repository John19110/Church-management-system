import 'package:flutter/material.dart';

import '../models/member_models.dart';
import 'member_form_controller.dart';

/// Maps native member form state to backend DTOs.
abstract final class MemberNativeFormMapper {
  static String? _trimOrNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  static String? _dateToIso(DateTime? date) {
    if (date == null) return null;
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static List<String>? _stringListOrNull(
    List<TextEditingController> controllers,
  ) {
    final values = <String>[];
    for (final controller in controllers) {
      final value = controller.text.trim();
      if (value.isNotEmpty) values.add(value);
    }
    return values.isEmpty ? null : values;
  }

  static List<MemberContactDto>? _phonesOrNull(MemberFormController form) {
    final contacts = <MemberContactDto>[];
    for (final entry in form.phones) {
      final phone = entry.phoneController.text.trim();
      final relation = _trimOrNull(entry.relation);
      if (phone.isEmpty && relation == null) continue;
      contacts.add(MemberContactDto(
        relation: relation,
        phoneNumber: phone.isEmpty ? null : phone,
      ));
    }
    return contacts.isEmpty ? null : contacts;
  }

  static MemberAddDto toAddDto(MemberFormController form) {
    return MemberAddDto(
      name1: _trimOrNull(form.name1Controller.text),
      name2: _trimOrNull(form.name2Controller.text),
      name3: _trimOrNull(form.name3Controller.text),
      gender: _trimOrNull(form.gender),
      address: _trimOrNull(form.addressController.text),
      dateOfBirth: _dateToIso(form.dateOfBirth),
      joiningDate: _dateToIso(form.joiningDate),
      spiritualDateOfBirth: _dateToIso(form.spiritualDateOfBirth),
      haveBrothers: form.haveBrothers ? true : false,
      brothersNames: form.haveBrothers
          ? _stringListOrNull(form.brotherNameControllers)
          : null,
      notes: _stringListOrNull(form.noteControllers),
      phoneNumbers: _phonesOrNull(form),
    );
  }

  static MemberUpdateDto toUpdateDto(MemberFormController form, int id) {
    return MemberUpdateDto(
      id: id,
      name1: _trimOrNull(form.name1Controller.text),
      name2: _trimOrNull(form.name2Controller.text),
      name3: _trimOrNull(form.name3Controller.text),
      gender: _trimOrNull(form.gender),
      address: _trimOrNull(form.addressController.text),
      dateOfBirth: _dateToIso(form.dateOfBirth),
      joiningDate: _dateToIso(form.joiningDate),
      lastAttendanceDate: _dateToIso(form.lastAttendanceDate),
      spiritualDateOfBirth: _dateToIso(form.spiritualDateOfBirth),
      isDiscipline: form.isDiscipline,
      haveBrothers: form.haveBrothers ? true : false,
      brothersNames: form.haveBrothers
          ? _stringListOrNull(form.brotherNameControllers)
          : null,
      notes: _stringListOrNull(form.noteControllers),
      phoneNumbers: _phonesOrNull(form),
    );
  }
}
