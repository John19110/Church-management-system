import 'package:flutter/material.dart';

import '../models/member_models.dart';
import 'member_phone_relations.dart';

class MemberPhoneEntry {
  String? relation;
  final TextEditingController phoneController;

  MemberPhoneEntry({
    this.relation,
    String? phone,
  }) : phoneController = TextEditingController(text: phone ?? '');

  void dispose() => phoneController.dispose();
}

/// Holds editable state for the native member form (add / edit).
class MemberFormController {
  final TextEditingController name1Controller = TextEditingController();
  final TextEditingController name2Controller = TextEditingController();
  final TextEditingController name3Controller = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  String? gender;
  DateTime? dateOfBirth;
  DateTime? joiningDate;
  DateTime? lastAttendanceDate;
  DateTime? spiritualDateOfBirth;
  bool isDiscipline = false;
  bool haveBrothers = false;

  final List<MemberPhoneEntry> phones = [];
  final List<TextEditingController> brotherNameControllers = [];
  final List<TextEditingController> noteControllers = [];

  String? existingImageUrl;

  void loadFromMember(MemberReadDto member) {
    var name1 = member.name1 ?? '';
    var name2 = member.name2 ?? '';
    var name3 = member.name3 ?? '';
    if (name1.isEmpty && (member.fullName?.trim().isNotEmpty ?? false)) {
      final parts = member.fullName!.trim().split(RegExp(r'\s+'));
      if (parts.isNotEmpty) name1 = parts.first;
      if (parts.length > 1) name2 = parts[1];
      if (parts.length > 2) name3 = parts.sublist(2).join(' ');
    }
    name1Controller.text = name1;
    name2Controller.text = name2;
    name3Controller.text = name3;
    addressController.text = member.address ?? '';

    gender = _normalizeGender(member.gender);
    dateOfBirth = _parseDate(member.dateOfBirth);
    joiningDate = _parseDate(member.joiningDate);
    lastAttendanceDate = _parseDate(member.lastAttendanceDate);
    spiritualDateOfBirth = _parseDate(member.spiritualDateOfBirth);
    isDiscipline = member.isDiscipline ?? false;
    haveBrothers = member.haveBrothers ?? false;
    existingImageUrl = member.displayImageUrl;

    _clearDynamicLists();
    for (final phone in member.phoneNumbers ?? const <MemberContactDto>[]) {
      phones.add(MemberPhoneEntry(
        relation: phone.relation,
        phone: phone.phoneNumber,
      ));
    }
    for (final name in member.brothersNames ?? const <String>[]) {
      brotherNameControllers.add(TextEditingController(text: name));
    }
    for (final note in member.notes ?? const <String>[]) {
      noteControllers.add(TextEditingController(text: note));
    }
  }

  void _clearDynamicLists() {
    for (final p in phones) {
      p.dispose();
    }
    phones.clear();
    for (final c in brotherNameControllers) {
      c.dispose();
    }
    brotherNameControllers.clear();
    for (final c in noteControllers) {
      c.dispose();
    }
    noteControllers.clear();
  }

  void addPhone() => phones.add(MemberPhoneEntry());

  void removePhone(int index) {
    phones[index].dispose();
    phones.removeAt(index);
  }

  void addBrother() =>
      brotherNameControllers.add(TextEditingController());

  void removeBrother(int index) {
    brotherNameControllers[index].dispose();
    brotherNameControllers.removeAt(index);
  }

  void addNote() => noteControllers.add(TextEditingController());

  void removeNote(int index) {
    noteControllers[index].dispose();
    noteControllers.removeAt(index);
  }

  void setHaveBrothers(bool value) {
    haveBrothers = value;
    if (!value) {
      for (final c in brotherNameControllers) {
        c.dispose();
      }
      brotherNameControllers.clear();
    }
  }

  void dispose() {
    name1Controller.dispose();
    name2Controller.dispose();
    name3Controller.dispose();
    addressController.dispose();
    _clearDynamicLists();
  }

  static DateTime? _parseDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final value = raw.trim();
    return DateTime.tryParse(value) ?? DateTime.tryParse('${value}T00:00:00');
  }

  static String? _normalizeGender(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final lower = raw.trim().toLowerCase();
    if (lower == 'male' || lower == 'm') return MemberGenderValues.male;
    if (lower == 'female' || lower == 'f') return MemberGenderValues.female;
    return raw.trim();
  }
}
