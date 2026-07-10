import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/l10n/locale_format.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/locale_date_text.dart';
import '../../../shared/widgets/status_chip.dart';
import '../models/unified_form_models.dart';
import '../utils/unified_form_controller.dart';
import '../utils/unified_form_field_utils.dart';
import 'entity_fields_empty_state.dart';
import 'unified_form_field_widget.dart';

/// Single form renderer: iterates one field list (built-in + custom).
class UnifiedEntityForm extends ConsumerStatefulWidget {
  final List<UnifiedFieldDefinitionDto> fields;
  final UnifiedFormController controller;
  final bool readOnly;
  final List<Widget>? leading;
  final List<Widget>? trailing;
  final String? entityName;
  final String? configurationHint;
  final bool canManageDefinitions;
  /// Keys rendered outside the form (e.g. photo picker for `imageUrl`).
  final Set<String> excludeFieldKeys;

  const UnifiedEntityForm({
    super.key,
    required this.fields,
    required this.controller,
    this.readOnly = false,
    this.leading,
    this.trailing,
    this.entityName,
    this.configurationHint,
    this.canManageDefinitions = false,
    this.excludeFieldKeys = kUnifiedPhotoFieldKeys,
  });

  @override
  ConsumerState<UnifiedEntityForm> createState() => _UnifiedEntityFormState();
}

class _UnifiedEntityFormState extends ConsumerState<UnifiedEntityForm> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final visible = visibleUnifiedFields(
      widget.fields,
      excludeFieldKeys: widget.excludeFieldKeys,
      entityName: widget.entityName,
      l10n: l10n,
    );

    if (visible.isEmpty && widget.entityName != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.leading != null) ...widget.leading!,
          EntityFieldsEmptyState(
            entityName: widget.entityName!,
            configurationHint: widget.configurationHint,
            canManageDefinitions: widget.canManageDefinitions,
          ),
          if (widget.trailing != null) ...widget.trailing!,
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.leading != null) ...widget.leading!,
        ...visible.map(
          (field) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: UnifiedFormFieldWidget(
              field: field,
              controller: widget.controller,
              readOnly: widget.readOnly,
              entityName: widget.entityName,
            ),
          ),
        ),
        if (widget.trailing != null) ...widget.trailing!,
      ],
    );
  }
}

/// Servant profile fields managed elsewhere or not user-editable.
const kServantProfileReadOnlyFieldKeys = <String>{
  'classroomId',
  'churchId',
  'meetingId',
  'imageUrl',
};

/// Read-only detail rows from the same unified field list.
class UnifiedEntityDetailFields extends StatelessWidget {
  final List<UnifiedFieldDto> fields; // built-in + custom values from form-data API
  final String? entityName;
  final Set<String> excludeFieldKeys;

  const UnifiedEntityDetailFields({
    super.key,
    required this.fields,
    this.entityName,
    this.excludeFieldKeys = const {},
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final visible = visibleUnifiedFields(
      fields,
      excludeFieldKeys: {
        ...kUnifiedPhotoFieldKeys,
        ...excludeFieldKeys,
      },
      entityName: entityName,
      l10n: l10n,
    );

    if (visible.isEmpty) return const SizedBox.shrink();

    final palette = context.palette;

    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < visible.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                indent: 52,
                color: palette.border,
              ),
            _DetailFieldRow(
              field: visible[i],
              entityName: entityName,
              valueBuilder: _buildDetailValue,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailValue(BuildContext context, UnifiedFieldDto f) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    final valueStyle = Theme.of(context)
        .textTheme
        .bodyLarge
        ?.copyWith(fontWeight: FontWeight.w600);

    if (f.value == null || f.value!.trim().isEmpty) {
      return Text(
        l10n.notAvailable,
        style: Theme.of(context)
            .textTheme
            .bodyLarge
            ?.copyWith(color: palette.textTertiary),
      );
    }
    if (f.dataType == UnifiedFieldDataType.date) {
      return LocaleDateText(
        value: f.value,
        locale: l10n.locale,
        style: valueStyle,
      );
    }
    if (f.dataType == UnifiedFieldDataType.dateTime) {
      return LocaleDateText(
        value: f.value,
        locale: l10n.locale,
        includeTime: true,
        style: valueStyle,
      );
    }
    if (f.dataType == UnifiedFieldDataType.boolean) {
      final isTrue = f.value!.toLowerCase() == 'true';
      return Align(
        alignment: AlignmentDirectional.centerStart,
        child: StatusChip(
          label: isTrue ? l10n.yes : l10n.no,
          tone: isTrue ? StatusTone.success : StatusTone.neutral,
          icon: isTrue ? Icons.check : Icons.remove,
        ),
      );
    }
    if (f.dataType == UnifiedFieldDataType.singleSelect ||
        f.dataType == UnifiedFieldDataType.multiSelect) {
      final labels = _selectLabels(f, l10n);
      if (labels.isEmpty) {
        return Text(l10n.notAvailable, style: valueStyle);
      }
      return Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xxs,
        children: [
          for (final label in labels)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: palette.infoSoft,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: palette.info,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
        ],
      );
    }
    return Text(_formatValue(f, context), style: valueStyle);
  }

  List<String> _selectLabels(UnifiedFieldDto f, AppLocalizations l10n) {
    final raw = f.value?.trim() ?? '';
    if (raw.isEmpty) return const [];
    final List<String> parts;
    if (f.dataType == UnifiedFieldDataType.multiSelect) {
      parts = parseMultiSelectValues(raw);
    } else {
      parts = (raw.contains(',') || raw.startsWith('['))
          ? parseMultiSelectValues(raw)
          : <String>[raw];
    }
    return parts.map((part) {
      for (final option in f.options) {
        if (option.value == part) {
          return l10n.formatDigitsIn(option.displayText);
        }
      }
      return LocaleFormat.formatNumericString(part, l10n.locale);
    }).toList();
  }

  String _formatValue(UnifiedFieldDto f, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (f.value == null || f.value!.trim().isEmpty) {
      return l10n.notAvailable;
    }
    if (f.dataType == UnifiedFieldDataType.boolean) {
      return f.value!.toLowerCase() == 'true' ? l10n.yes : l10n.no;
    }
    if (f.dataType == UnifiedFieldDataType.singleSelect) {
      final raw = f.value!.trim();
      final parts = raw.contains(',') || raw.startsWith('[')
          ? UnifiedEntityDetailFields.parseMultiSelectValues(raw)
          : <String>[raw];
      if (parts.length > 1) {
        final labels = parts
            .map((part) {
              for (final option in f.options) {
                if (option.value == part) {
                  return l10n.formatDigitsIn(option.displayText);
                }
              }
              return LocaleFormat.formatNumericString(part, l10n.locale);
            })
            .toList();
        return labels.isEmpty ? l10n.notAvailable : labels.join(', ');
      }
      for (final option in f.options) {
        if (option.value == raw) {
          return l10n.formatDigitsIn(option.displayText);
        }
      }
      return LocaleFormat.formatNumericString(raw, l10n.locale);
    }
    if (f.dataType == UnifiedFieldDataType.multiSelect) {
      final labels = UnifiedEntityDetailFields.parseMultiSelectValues(f.value!)
          .map((part) {
            for (final option in f.options) {
              if (option.value == part) {
                return l10n.formatDigitsIn(option.displayText);
              }
            }
            return LocaleFormat.formatNumericString(part, l10n.locale);
          })
          .toList();
      return labels.isEmpty ? l10n.notAvailable : labels.join(', ');
    }
    if (f.dataType == UnifiedFieldDataType.number ||
        f.dataType == UnifiedFieldDataType.decimal) {
      return LocaleFormat.formatNumericString(f.value!, l10n.locale);
    }
    return l10n.formatDigitsIn(f.value!);
  }

  static List<String> parseMultiSelectValues(String raw) {
    final trimmed = raw.trim();
    if (trimmed.startsWith('[')) {
      try {
        final decoded = jsonDecode(trimmed) as List<dynamic>;
        return decoded
            .map((e) => e.toString().trim())
            .where((part) => part.isNotEmpty)
            .toList();
      } catch (_) {
        return const [];
      }
    }
    return trimmed
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
  }
}

/// A single premium detail row: icon badge + label + emphasized value.
class _DetailFieldRow extends StatelessWidget {
  final UnifiedFieldDto field;
  final String? entityName;
  final Widget Function(BuildContext, UnifiedFieldDto) valueBuilder;

  const _DetailFieldRow({
    required this.field,
    required this.entityName,
    required this.valueBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.10),
              borderRadius: AppRadius.smAll,
            ),
            child: Icon(
              _iconForField(field),
              size: 20,
              color: scheme.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  unifiedFieldLabel(field, entityName: entityName, l10n: l10n),
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(color: palette.textSecondary),
                ),
                const SizedBox(height: 3),
                valueBuilder(context, field),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForField(UnifiedFieldDto f) {
    final key = f.fieldKey.toLowerCase();
    if (key.contains('name')) return Icons.badge_outlined;
    if (key.contains('phone') || key.contains('mobile')) {
      return Icons.phone_outlined;
    }
    if (key.contains('email')) return Icons.email_outlined;
    if (key.contains('address') || key.contains('location')) {
      return Icons.location_on_outlined;
    }
    if (key.contains('birth') || key.contains('dob')) {
      return Icons.cake_outlined;
    }
    if (key.contains('gender')) return Icons.person_outline;
    if (key.contains('note') || key.contains('comment')) {
      return Icons.notes_outlined;
    }
    if (key.contains('church')) return Icons.church_outlined;
    if (key.contains('meeting')) return Icons.groups_outlined;
    if (key.contains('class')) return Icons.class_outlined;

    switch (f.dataType) {
      case UnifiedFieldDataType.date:
        return Icons.event_outlined;
      case UnifiedFieldDataType.dateTime:
        return Icons.schedule_outlined;
      case UnifiedFieldDataType.boolean:
        return Icons.check_circle_outline;
      case UnifiedFieldDataType.number:
      case UnifiedFieldDataType.decimal:
        return Icons.tag_outlined;
      case UnifiedFieldDataType.singleSelect:
      case UnifiedFieldDataType.multiSelect:
        return Icons.list_alt_outlined;
      case UnifiedFieldDataType.longText:
        return Icons.notes_outlined;
      default:
        return Icons.info_outline;
    }
  }
}
