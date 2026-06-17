import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/l10n/locale_format.dart';
import '../../../shared/widgets/app_form_fields.dart';
import '../../../shared/widgets/app_network_avatar.dart';
import '../utils/member_form_controller.dart';
import '../utils/member_form_validator.dart';
import '../utils/member_phone_relations.dart';
import 'member_form_section_card.dart';

/// Native member form with section cards (personal, dates, phones, etc.).
class MemberForm extends StatelessWidget {
  final MemberFormController controller;
  final File? pickedImage;
  final VoidCallback onPickImage;
  final bool showLastAttendanceDate;
  final VoidCallback onChanged;

  const MemberForm({
    super.key,
    required this.controller,
    required this.pickedImage,
    required this.onPickImage,
    required this.onChanged,
    this.showLastAttendanceDate = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MemberFormSectionCard(
          title: l10n.memberSectionPersonal,
          initiallyExpanded: true,
          child: _PersonalSection(
            controller: controller,
            pickedImage: pickedImage,
            onPickImage: onPickImage,
            onChanged: onChanged,
          ),
        ),
        MemberFormSectionCard(
          title: l10n.address,
          showOptionalBadge: true,
          initiallyExpanded: false,
          child: AppTextField(
            controller: controller.addressController,
            label: l10n.address,
            maxLines: 3,
          ),
        ),
        MemberFormSectionCard(
          title: l10n.memberSectionDates,
          showOptionalBadge: true,
          initiallyExpanded: false,
          child: _DatesSection(
            controller: controller,
            showLastAttendanceDate: showLastAttendanceDate,
            onChanged: onChanged,
          ),
        ),
        MemberFormSectionCard(
          title: l10n.disciplineStatus,
          showOptionalBadge: true,
          initiallyExpanded: false,
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.disciplineStatus),
            subtitle: Text(l10n.disciplineStatusHint),
            value: controller.isDiscipline,
            onChanged: (v) {
              controller.isDiscipline = v;
              onChanged();
            },
          ),
        ),
        MemberFormSectionCard(
          title: l10n.phoneNumbers,
          showOptionalBadge: true,
          initiallyExpanded: false,
          child: _PhonesSection(
            controller: controller,
            onChanged: onChanged,
          ),
        ),
        MemberFormSectionCard(
          title: l10n.brothersNamesSection,
          showOptionalBadge: true,
          initiallyExpanded: false,
          child: _BrothersSection(
            controller: controller,
            onChanged: onChanged,
          ),
        ),
        MemberFormSectionCard(
          title: l10n.memberNotesSection,
          showOptionalBadge: true,
          initiallyExpanded: false,
          child: _NotesSection(
            controller: controller,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _PersonalSection extends StatelessWidget {
  final MemberFormController controller;
  final File? pickedImage;
  final VoidCallback onPickImage;
  final VoidCallback onChanged;

  const _PersonalSection({
    required this.controller,
    required this.pickedImage,
    required this.onPickImage,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: onPickImage,
          child: Center(
            child: pickedImage != null
                ? CircleAvatar(
                    radius: 52,
                    backgroundImage: FileImage(pickedImage!),
                  )
                : AppNetworkAvatar(
                    imageUrl: controller.existingImageUrl,
                    debugTag: 'member-form-existing',
                    radius: 52,
                    placeholder: Icon(
                      Icons.camera_alt,
                      size: 40,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.tapToChangePhoto,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        AppTextField(
          controller: controller.name1Controller,
          label: '${l10n.firstName} *',
          validator: (v) => MemberFormValidator.validateFirstName(v, l10n),
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: controller.name2Controller,
          label: l10n.fatherName,
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: controller.name3Controller,
          label: l10n.familyName,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.fullNameComputedHint,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 16),
        Text(l10n.gender, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          emptySelectionAllowed: true,
          segments: [
            ButtonSegment(
              value: MemberGenderValues.male,
              label: Text(l10n.male),
            ),
            ButtonSegment(
              value: MemberGenderValues.female,
              label: Text(l10n.female),
            ),
          ],
          selected: controller.gender == null ? {} : {controller.gender!},
          onSelectionChanged: (values) {
            controller.gender = values.isEmpty ? null : values.first;
            onChanged();
          },
        ),
      ],
    );
  }
}

class _DatesSection extends StatelessWidget {
  final MemberFormController controller;
  final bool showLastAttendanceDate;
  final VoidCallback onChanged;

  const _DatesSection({
    required this.controller,
    required this.showLastAttendanceDate,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();

    return Column(
      children: [
        _OptionalDateTile(
          label: l10n.dateOfBirth,
          value: controller.dateOfBirth,
          firstDate: DateTime(1900),
          lastDate: now,
          onChanged: (d) {
            controller.dateOfBirth = d;
            onChanged();
          },
        ),
        const SizedBox(height: 8),
        _OptionalDateTile(
          label: l10n.joiningDate,
          value: controller.joiningDate,
          firstDate: DateTime(1900),
          lastDate: DateTime(now.year + 1),
          onChanged: (d) {
            controller.joiningDate = d;
            onChanged();
          },
        ),
        if (showLastAttendanceDate) ...[
          const SizedBox(height: 8),
          _OptionalDateTile(
            label: l10n.lastAttendanceDate,
            value: controller.lastAttendanceDate,
            firstDate: DateTime(1900),
            lastDate: DateTime(now.year + 1),
            onChanged: (d) {
              controller.lastAttendanceDate = d;
              onChanged();
            },
          ),
        ],
        const SizedBox(height: 8),
        _OptionalDateTile(
          label: l10n.spiritualDateOfBirth,
          value: controller.spiritualDateOfBirth,
          firstDate: DateTime(1900),
          lastDate: DateTime(now.year + 1),
          onChanged: (d) {
            controller.spiritualDateOfBirth = d;
            onChanged();
          },
        ),
      ],
    );
  }
}

class _OptionalDateTile extends StatelessWidget {
  final String label;
  final DateTime? value;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime?> onChanged;

  const _OptionalDateTile({
    required this.label,
    required this.value,
    required this.firstDate,
    required this.lastDate,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final display = value == null
        ? l10n.notAvailable
        : LocaleFormat.dateYmd(value!, l10n.locale);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(display),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value != null)
            IconButton(
              icon: const Icon(Icons.clear),
              tooltip: l10n.clearLabel,
              onPressed: () => onChanged(null),
            ),
          const Icon(Icons.calendar_today),
        ],
      ),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: firstDate,
          lastDate: lastDate,
        );
        if (picked != null) onChanged(picked);
      },
    );
  }
}

class _PhonesSection extends StatelessWidget {
  final MemberFormController controller;
  final VoidCallback onChanged;

  const _PhonesSection({
    required this.controller,
    required this.onChanged,
  });

  String _relationLabel(AppLocalizations l10n, String value) {
    switch (value) {
      case MemberPhoneRelations.member:
        return l10n.phoneRelationMember;
      case MemberPhoneRelations.father:
        return l10n.phoneRelationFather;
      case MemberPhoneRelations.mother:
        return l10n.phoneRelationMother;
      case MemberPhoneRelations.brother:
        return l10n.phoneRelationBrother;
      case MemberPhoneRelations.sister:
        return l10n.phoneRelationSister;
      case MemberPhoneRelations.guardian:
        return l10n.phoneRelationGuardian;
      case MemberPhoneRelations.other:
        return l10n.phoneRelationOther;
      default:
        return value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...List.generate(controller.phones.length, (index) {
          final entry = controller.phones[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              margin: EdgeInsets.zero,
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${l10n.phone} ${index + 1}',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          tooltip: l10n.removePhoneNumber,
                          onPressed: () {
                            controller.removePhone(index);
                            onChanged();
                          },
                        ),
                      ],
                    ),
                    DropdownButtonFormField<String>(
                      value: entry.relation,
                      decoration: InputDecoration(labelText: l10n.relation),
                      items: MemberPhoneRelations.all
                          .map(
                            (r) => DropdownMenuItem(
                              value: r,
                              child: Text(_relationLabel(l10n, r)),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        entry.relation = v;
                        onChanged();
                      },
                      validator: (_) => MemberFormValidator.validateRelation(
                        entry.relation,
                        entry.phoneController.text,
                        l10n,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: entry.phoneController,
                      decoration: InputDecoration(labelText: l10n.phone),
                      keyboardType: TextInputType.phone,
                      validator: (v) =>
                          MemberFormValidator.validatePhone(v, l10n),
                      onChanged: (_) => onChanged(),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        OutlinedButton.icon(
          onPressed: () {
            controller.addPhone();
            onChanged();
          },
          icon: const Icon(Icons.add),
          label: Text(l10n.addPhoneNumber),
        ),
      ],
    );
  }
}

class _BrothersSection extends StatelessWidget {
  final MemberFormController controller;
  final VoidCallback onChanged;

  const _BrothersSection({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.haveBrothersQuestion, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 8),
        SegmentedButton<bool>(
          segments: [
            ButtonSegment(value: false, label: Text(l10n.no)),
            ButtonSegment(value: true, label: Text(l10n.yes)),
          ],
          selected: {controller.haveBrothers},
          onSelectionChanged: (values) {
            controller.setHaveBrothers(values.first);
            onChanged();
          },
        ),
        if (controller.haveBrothers) ...[
          const SizedBox(height: 16),
          ...List.generate(controller.brotherNameControllers.length, (index) {
            final field = controller.brotherNameControllers[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: field,
                      decoration: InputDecoration(
                        labelText: l10n.brotherName,
                      ),
                      onChanged: (_) => onChanged(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    tooltip: l10n.removeBrother,
                    onPressed: () {
                      controller.removeBrother(index);
                      onChanged();
                    },
                  ),
                ],
              ),
            );
          }),
          OutlinedButton.icon(
            onPressed: () {
              controller.addBrother();
              onChanged();
            },
            icon: const Icon(Icons.person_add_outlined),
            label: Text(l10n.addBrotherName),
          ),
        ],
      ],
    );
  }
}

class _NotesSection extends StatelessWidget {
  final MemberFormController controller;
  final VoidCallback onChanged;

  const _NotesSection({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...List.generate(controller.noteControllers.length, (index) {
          final field = controller.noteControllers[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: field,
                    decoration: InputDecoration(
                      labelText: '${l10n.noteLine} ${index + 1}',
                    ),
                    maxLines: 3,
                    onChanged: (_) => onChanged(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: l10n.removeNote,
                  onPressed: () {
                    controller.removeNote(index);
                    onChanged();
                  },
                ),
              ],
            ),
          );
        }),
        OutlinedButton.icon(
          onPressed: () {
            controller.addNote();
            onChanged();
          },
          icon: const Icon(Icons.note_add_outlined),
          label: Text(l10n.addNoteLine),
        ),
      ],
    );
  }
}
