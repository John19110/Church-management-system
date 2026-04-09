import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/member_models.dart';
import '../providers/members_providers.dart';
import '../../../shared/widgets/app_form_fields.dart';
import '../../../shared/widgets/common_widgets.dart';
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
  final _classroomController = TextEditingController();
  String? _gender;
  bool _haveBrothers = false;
  bool _loading = false;
  bool _initialized = false;

  final List<TextEditingController> _phoneRelation = [];
  final List<TextEditingController> _phoneNumber = [];
  final List<TextEditingController> _notes = [];
  final List<TextEditingController> _brothers = [];

  @override
  void dispose() {
    _name1Controller.dispose();
    _name2Controller.dispose();
    _name3Controller.dispose();
    _addressController.dispose();
    _dobController.dispose();
    _joiningController.dispose();
    _spiritualDobController.dispose();
    _classroomController.dispose();
    for (final c in _phoneRelation) c.dispose();
    for (final c in _phoneNumber) c.dispose();
    for (final c in _notes) c.dispose();
    for (final c in _brothers) c.dispose();
    super.dispose();
  }

  void _initFromMember(MemberReadDto member) {
    if (_initialized) return;
    _initialized = true;
    _name1Controller.text = member.fullName ?? '';
    _addressController.text = member.address ?? '';
    _dobController.text = member.dateOfBirth ?? '';
    _joiningController.text = member.joiningDate ?? '';
    _spiritualDobController.text = member.spiritualDateOfBirth ?? '';
    _classroomController.text = member.classroomId?.toString() ?? '';
    _gender = _kValidGenders.contains(member.gender) ? member.gender : null;
    _haveBrothers = member.haveBrothers ?? false;
    if (member.phoneNumbers != null) {
      for (final p in member.phoneNumbers!) {
        _phoneRelation.add(TextEditingController(text: p.relation ?? ''));
        _phoneNumber.add(TextEditingController(text: p.phoneNumber ?? ''));
      }
    }
    if (member.notes != null) {
      for (final n in member.notes!) {
        _notes.add(TextEditingController(text: n));
      }
    }
    if (member.brothersNames != null) {
      for (final b in member.brothersNames!) {
        _brothers.add(TextEditingController(text: b));
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

  void _addNoteRow() {
    setState(() => _notes.add(TextEditingController()));
  }

  void _removeNoteRow(int index) {
    setState(() {
      _notes[index].dispose();
      _notes.removeAt(index);
    });
  }

  void _addBrotherRow() {
    setState(() => _brothers.add(TextEditingController()));
  }

  void _removeBrotherRow(int index) {
    setState(() {
      _brothers[index].dispose();
      _brothers.removeAt(index);
    });
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
      final notesList = _notes
          .map((c) => c.text.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      final brothersList = _brothers
          .map((c) => c.text.trim())
          .where((s) => s.isNotEmpty)
          .toList();
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
              haveBrothers: _haveBrothers,
              brothersNames: brothersList.isEmpty ? null : brothersList,
              notes: notesList.isEmpty ? null : notesList,
              classroomId: int.tryParse(_classroomController.text.trim()),
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

  Widget _sectionHeader(BuildContext context, String title,
      {VoidCallback? onAdd}) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ),
          if (onAdd != null)
            IconButton(
              icon: Icon(Icons.add_circle,
                  color: Theme.of(context).colorScheme.primary),
              onPressed: onAdd,
              tooltip: title,
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                children: [
                  // ── Name fields ────────────────────────────────────────
                  _sectionHeader(context, l10n.fullName),
                  AppTextField(
                    controller: _name1Controller,
                    label: l10n.firstName,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? l10n.nameRequired
                        : null,
                  ),
                  const SizedBox(height: 10),
                  AppTextField(
                    controller: _name2Controller,
                    label: l10n.middleName,
                  ),
                  const SizedBox(height: 10),
                  AppTextField(
                    controller: _name3Controller,
                    label: l10n.lastName,
                  ),
                  const SizedBox(height: 14),

                  // ── Basic info ─────────────────────────────────────────
                  _sectionHeader(context, l10n.gender),
                  DropdownButtonFormField<String>(
                    value: _gender,
                    decoration: InputDecoration(labelText: l10n.gender),
                    items: [
                      DropdownMenuItem(
                          value: 'Male', child: Text(l10n.male)),
                      DropdownMenuItem(
                          value: 'Female', child: Text(l10n.female)),
                    ],
                    onChanged: (v) => setState(() => _gender = v),
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: _addressController,
                    label: l10n.address,
                  ),
                  const SizedBox(height: 14),

                  // ── Dates ──────────────────────────────────────────────
                  _sectionHeader(context, l10n.dateOfBirth),
                  AppDateField(
                    controller: _dobController,
                    label: l10n.dateOfBirth,
                  ),
                  const SizedBox(height: 10),
                  AppDateField(
                    controller: _joiningController,
                    label: l10n.joiningDate,
                  ),
                  const SizedBox(height: 10),
                  AppDateField(
                    controller: _spiritualDobController,
                    label: l10n.spiritualDateOfBirth,
                  ),
                  const SizedBox(height: 14),

                  // ── Classroom ──────────────────────────────────────────
                  AppTextField(
                    controller: _classroomController,
                    label: l10n.classroomId,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 14),

                  // ── Phone numbers ──────────────────────────────────────
                  _sectionHeader(context, l10n.phoneNumbers,
                      onAdd: _addPhoneRow),
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
                  const SizedBox(height: 6),

                  // ── Brothers / Sisters ─────────────────────────────────
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.haveBrothers),
                    value: _haveBrothers,
                    onChanged: (v) {
                      setState(() {
                        _haveBrothers = v;
                        if (!v) {
                          for (final c in _brothers) c.dispose();
                          _brothers.clear();
                        }
                      });
                    },
                  ),
                  if (_haveBrothers) ...[
                    _sectionHeader(context, l10n.brothersNames,
                        onAdd: _addBrotherRow),
                    ..._brothers.asMap().entries.map((entry) {
                      final i = entry.key;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: AppTextField(
                                controller: _brothers[i],
                                label: '${l10n.brotherName} ${i + 1}',
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
                  const SizedBox(height: 6),

                  // ── Notes ──────────────────────────────────────────────
                  _sectionHeader(context, l10n.notes, onAdd: _addNoteRow),
                  ..._notes.asMap().entries.map((entry) {
                    final i = entry.key;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              controller: _notes[i],
                              label: '${l10n.note} ${i + 1}',
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
                  const SizedBox(height: 24),

                  // ── Submit ─────────────────────────────────────────────
                  _loading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton.icon(
                          onPressed: _submit,
                          icon: const Icon(Icons.save),
                          label: Text(l10n.save),
                        ),
                  const SizedBox(height: 16),
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
