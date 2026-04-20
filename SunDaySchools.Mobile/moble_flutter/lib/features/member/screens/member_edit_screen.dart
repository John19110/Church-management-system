import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/member_models.dart';
import '../providers/members_providers.dart';
import '../../../shared/widgets/app_form_fields.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../shared/widgets/endpoint_select_fields.dart';
import '../../../core/l10n/app_localizations.dart';

const _kValidGenders = ['Male', 'Female'];

class MemberEditScreen extends ConsumerStatefulWidget {
  final int id;
  const MemberEditScreen({super.key, required this.id});

  @override
  ConsumerState<MemberEditScreen> createState() => _MemberEditScreenState();
}

class _MemberEditScreenState extends ConsumerState<MemberEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name1Controller = TextEditingController();
  final _name2Controller = TextEditingController();
  final _name3Controller = TextEditingController();
  final _addressController = TextEditingController();
  final _dobController = TextEditingController();
  final _joiningController = TextEditingController();
  final _spiritualDobController = TextEditingController();
  final _lastAttendanceController = TextEditingController();
  final _totalDaysController = TextEditingController();
  int? _selectedClassroomId;
  String? _gender;
  bool _loading = false;
  bool _initialized = false;
  MemberReadDto? _snapshot;
  bool _isDiscipline = false;
  bool _haveBrothers = false;

  final List<TextEditingController> _phoneRelation = [];
  final List<TextEditingController> _phoneNumber = [];
  final List<TextEditingController> _brotherNames = [];
  final List<TextEditingController> _notes = [];

  @override
  void dispose() {
    _name1Controller.dispose();
    _name2Controller.dispose();
    _name3Controller.dispose();
    _addressController.dispose();
    _dobController.dispose();
    _joiningController.dispose();
    _spiritualDobController.dispose();
    _lastAttendanceController.dispose();
    _totalDaysController.dispose();
    for (final c in _phoneRelation) {
      c.dispose();
    }
    for (final c in _phoneNumber) {
      c.dispose();
    }
    for (final c in _brotherNames) {
      c.dispose();
    }
    for (final c in _notes) {
      c.dispose();
    }
    super.dispose();
  }

  void _initFromMember(MemberReadDto member) {
    if (_initialized) return;
    _initialized = true;
    _snapshot = member;
    _name1Controller.text = member.fullName ?? '';
    _name2Controller.text = '';
    _name3Controller.text = '';
    _addressController.text = member.address ?? '';
    _dobController.text = member.dateOfBirth ?? '';
    _joiningController.text = member.joiningDate ?? '';
    _spiritualDobController.text = member.spiritualDateOfBirth ?? '';
    _lastAttendanceController.text = member.lastAttendanceDate ?? '';
    _totalDaysController.text =
        member.totalNumberOfDaysAttended?.toString() ?? '';
    _selectedClassroomId = member.classroomId;
    _gender = _kValidGenders.contains(member.gender) ? member.gender : null;
    _isDiscipline = member.isDiscipline ?? false;
    _haveBrothers = member.haveBrothers ?? false;
    if (member.phoneNumbers != null) {
      for (final p in member.phoneNumbers!) {
        _phoneRelation.add(TextEditingController(text: p.relation ?? ''));
        _phoneNumber.add(TextEditingController(text: p.phoneNumber ?? ''));
      }
    }
    if (member.brothersNames != null) {
      for (final n in member.brothersNames!) {
        _brotherNames.add(TextEditingController(text: n));
      }
    }
    if (member.notes != null) {
      for (final n in member.notes!) {
        _notes.add(TextEditingController(text: n));
      }
    }
  }

  void _addPhoneRow() {
    setState(() {
      _phoneRelation.add(TextEditingController());
      _phoneNumber.add(TextEditingController());
    });
  }

  void _removePhoneRow(int index) {
    setState(() {
      _phoneRelation[index].dispose();
      _phoneNumber[index].dispose();
      _phoneRelation.removeAt(index);
      _phoneNumber.removeAt(index);
    });
  }

  void _addBrotherRow() {
    setState(() => _brotherNames.add(TextEditingController()));
  }

  void _removeBrotherRow(int index) {
    setState(() {
      _brotherNames[index].dispose();
      _brotherNames.removeAt(index);
    });
  }

  void _addNoteRow() {
    setState(() => _notes.add(TextEditingController()));
  }

  void _removeNoteRow(int index) {
    setState(() {
      _notes[index].dispose();
      _notes.removeAt(index);
    });
  }

  List<String> _nonEmptyLines(List<TextEditingController> ctrls) {
    return ctrls
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final l10n = AppLocalizations.of(context);
    try {
      final phones = List.generate(
        _phoneRelation.length,
        (i) => MemberContactDto(
          relation: _phoneRelation[i].text.trim(),
          phoneNumber: _phoneNumber[i].text.trim(),
        ),
      );
      final brothers = _nonEmptyLines(_brotherNames);
      final noteLines = _nonEmptyLines(_notes);
      String resolveLastAttendance() {
        final t = _lastAttendanceController.text.trim();
        if (t.isNotEmpty) return t;
        final snap = _snapshot?.lastAttendanceDate?.trim();
        if (snap != null && snap.isNotEmpty) return snap;
        return _dobController.text.trim();
      }

      final lastAtt = resolveLastAttendance();
      final totalDays = int.tryParse(_totalDaysController.text.trim()) ??
          _snapshot?.totalNumberOfDaysAttended ??
          0;
      await ref.read(membersRepositoryProvider).update(
            widget.id,
            MemberUpdateDto(
              id: widget.id,
              name1: _name1Controller.text.trim().nullIfEmpty,
              name2: _name2Controller.text.trim().nullIfEmpty,
              name3: _name3Controller.text.trim().nullIfEmpty,
              gender: _gender,
              address: _addressController.text.trim().nullIfEmpty,
              dateOfBirth: _dobController.text.trim().nullIfEmpty,
              joiningDate: _joiningController.text.trim().nullIfEmpty,
              spiritualDateOfBirth:
                  _spiritualDobController.text.trim().nullIfEmpty,
              lastAttendanceDate: lastAtt.nullIfEmpty,
              isDiscipline: _isDiscipline,
              totalNumberOfDaysAttended: totalDays,
              haveBrothers: _haveBrothers,
              brothersNames: brothers.isEmpty ? null : brothers,
              notes: noteLines.isEmpty ? null : noteLines,
              classroomId: _selectedClassroomId,
              phoneNumbers: phones.isEmpty ? null : phones,
            ),
          );
      if (mounted) {
        showSuccessSnackbar(context, l10n.memberUpdatedSuccessfully);
        context.pop();
      }
    } catch (e) {
      if (mounted) showErrorSnackbar(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (widget.id <= 0) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.editMember)),
        body: AppErrorWidget(
          message: 'Invalid member id.',
          onRetry: () {
            if (context.mounted) context.pop();
          },
        ),
      );
    }

    final memberAsync = ref.watch(memberDetailProvider(widget.id));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.editMember)),
      body: SafeArea(
        child: memberAsync.when(
          loading: () => const LoadingWidget(),
          error: (e, _) => AppErrorWidget(message: e.toString()),
          data: (member) {
            _initFromMember(member);
            return Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  AppTextField(
                    controller: _name1Controller,
                    label: l10n.firstName,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty)
                            ? l10n.firstNameRequired
                            : null,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _name2Controller,
                    label: l10n.middleName,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _name3Controller,
                    label: l10n.lastName,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _gender,
                    decoration: InputDecoration(labelText: l10n.gender),
                    items: [
                      DropdownMenuItem(value: 'Male', child: Text(l10n.male)),
                      DropdownMenuItem(
                          value: 'Female', child: Text(l10n.female)),
                    ],
                    onChanged: (v) => setState(() => _gender = v),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _addressController,
                    label: l10n.address,
                  ),
                  const SizedBox(height: 12),
                  AppDateField(
                    controller: _dobController,
                    label: l10n.dateOfBirth,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? l10n.dobRequired : null,
                  ),
                  const SizedBox(height: 12),
                  AppDateField(
                    controller: _joiningController,
                    label: l10n.joiningDate,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? l10n.joiningDateRequired : null,
                  ),
                  const SizedBox(height: 12),
                  AppDateField(
                    controller: _spiritualDobController,
                    label: l10n.spiritualDateOfBirth,
                  ),
                  const SizedBox(height: 12),
                  AppDateField(
                    controller: _lastAttendanceController,
                    label: l10n.lastAttendanceDate,
                    validator: (v) {
                      final t = v?.trim() ?? '';
                      if (t.isNotEmpty) return null;
                      final snap = _snapshot?.lastAttendanceDate?.trim();
                      if (snap != null && snap.isNotEmpty) return null;
                      if (_dobController.text.trim().isNotEmpty) return null;
                      return l10n.required;
                    },
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _totalDaysController,
                    label: l10n.totalDaysAttended,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: Text(l10n.discipline),
                    value: _isDiscipline,
                    onChanged: (v) => setState(() => _isDiscipline = v),
                  ),
                  const SizedBox(height: 12),
                  EndpointSelectDropdown(
                    endpoint: SelectionEndpoints.classrooms,
                    label: l10n.classroomId,
                    hintText: l10n.classroomId,
                    value: _selectedClassroomId,
                    onChanged: (v) => setState(() => _selectedClassroomId = v),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: Text(l10n.haveBrothersInProgram),
                    value: _haveBrothers,
                    onChanged: (v) => setState(() => _haveBrothers = v),
                  ),
                  if (_haveBrothers) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(l10n.brothersNamesSection,
                            style: Theme.of(context).textTheme.titleSmall),
                        IconButton(
                          icon: const Icon(Icons.add_circle,
                              color: Color(0xFF2B6CB0)),
                          onPressed: _addBrotherRow,
                          tooltip: l10n.addBrotherName,
                        ),
                      ],
                    ),
                    ..._brotherNames.asMap().entries.map((e) {
                      final i = e.key;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: AppTextField(
                                controller: _brotherNames[i],
                                label: l10n.brotherName,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_circle,
                                  color: Colors.red),
                              onPressed: () => _removeBrotherRow(i),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.memberNotesSection,
                          style: Theme.of(context).textTheme.titleSmall),
                      IconButton(
                        icon: const Icon(Icons.add_circle,
                            color: Color(0xFF2B6CB0)),
                        onPressed: _addNoteRow,
                        tooltip: l10n.addNoteLine,
                      ),
                    ],
                  ),
                  ..._notes.asMap().entries.map((e) {
                    final i = e.key;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              controller: _notes[i],
                              label: l10n.noteLine,
                              maxLines: 2,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle,
                                color: Colors.red),
                            onPressed: () => _removeNoteRow(i),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.phoneNumbers,
                          style: Theme.of(context).textTheme.titleSmall),
                      IconButton(
                        icon: const Icon(Icons.add_circle,
                            color: Color(0xFF2B6CB0)),
                        onPressed: _addPhoneRow,
                      ),
                    ],
                  ),
                  ..._phoneRelation.asMap().entries.map((entry) {
                    final i = entry.key;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              controller: _phoneRelation[i],
                              label: l10n.relation,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: AppTextField(
                              controller: _phoneNumber[i],
                              label: l10n.phone,
                              keyboardType: TextInputType.phone,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle,
                                color: Colors.red),
                            onPressed: () => _removePhoneRow(i),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                  _loading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _submit,
                          child: Text(l10n.save),
                        ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

extension _StringExt on String {
  String? get nullIfEmpty => isEmpty ? null : this;
}
