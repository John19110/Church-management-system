import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../models/custom_field_models.dart';
import '../providers/custom_field_providers.dart';
import 'dynamic_custom_field_widget.dart';

/// Stateful holder for dynamic field controllers (used by parent forms).
class DynamicCustomFieldsController {
  final Map<int, TextEditingController> _textControllers = {};
  final Map<int, bool> _boolValues = {};
  final Map<int, List<String>> _multiValues = {};

  void dispose() {
    for (final c in _textControllers.values) {
      c.dispose();
    }
  }

  void initialize(
    List<CustomFieldDefinitionReadDto> definitions,
    EntityCustomFieldsReadDto? existing,
  ) {
    for (final def in definitions) {
      if (def.isHidden) continue;

      final existingValue = existing?.valueForDefinition(def.id) ??
          def.defaultValue;

      if (def.dataType == CustomFieldDataType.boolean) {
        _boolValues[def.id] = _parseBool(existingValue);
      } else if (def.dataType == CustomFieldDataType.multiSelect) {
        _multiValues[def.id] = _parseMulti(existingValue);
        _textControllers.putIfAbsent(def.id, TextEditingController.new);
      } else {
        final c = _textControllers.putIfAbsent(def.id, TextEditingController.new);
        c.text = existingValue ?? '';
      }
    }
  }

  List<CustomFieldValueItemDto> buildPayload(
    List<CustomFieldDefinitionReadDto> definitions,
  ) {
    final items = <CustomFieldValueItemDto>[];
    for (final def in definitions) {
      if (def.isHidden || def.isReadOnly) continue;

      String? value;
      if (def.dataType == CustomFieldDataType.boolean) {
        value = (_boolValues[def.id] ?? false) ? 'true' : 'false';
      } else if (def.dataType == CustomFieldDataType.multiSelect) {
        final selected = _multiValues[def.id] ?? [];
        value = selected.isEmpty ? null : jsonEncode(selected);
      } else {
        final text = _textControllers[def.id]?.text.trim();
        value = text == null || text.isEmpty ? null : text;
      }

      items.add(CustomFieldValueItemDto(
        customFieldDefinitionId: def.id,
        value: value,
      ));
    }
    return items;
  }

  TextEditingController? textController(int definitionId) =>
      _textControllers[definitionId];

  bool? boolValue(int definitionId) => _boolValues[definitionId];

  void setBool(int definitionId, bool value) => _boolValues[definitionId] = value;

  List<String> multiValue(int definitionId) =>
      _multiValues[definitionId] ?? [];

  void setMulti(int definitionId, List<String> values) =>
      _multiValues[definitionId] = values;

  static bool _parseBool(String? raw) {
    if (raw == null) return false;
    return raw.toLowerCase() == 'true' ||
        raw == '1' ||
        raw.toLowerCase() == 'yes';
  }

  static List<String> _parseMulti(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    if (raw.startsWith('[')) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        return list.map((e) => e.toString()).toList();
      } catch (_) {
        return [];
      }
    }
    return raw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
  }
}

/// Embeddable form section that loads definitions and renders inputs.
class DynamicCustomFieldsForm extends ConsumerStatefulWidget {
  final String entityName;
  final int? entityId;
  final DynamicCustomFieldsController controller;
  final bool readOnly;
  final EntityCustomFieldsReadDto? prefetched;

  const DynamicCustomFieldsForm({
    super.key,
    required this.entityName,
    required this.controller,
    this.entityId,
    this.readOnly = false,
    this.prefetched,
  });

  @override
  ConsumerState<DynamicCustomFieldsForm> createState() =>
      _DynamicCustomFieldsFormState();
}

class _DynamicCustomFieldsFormState extends ConsumerState<DynamicCustomFieldsForm> {
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    if (widget.prefetched != null) {
      return _buildFields(widget.prefetched!.definitions, widget.prefetched);
    }

    if (widget.entityId != null) {
      final async = ref.watch(
        entityCustomFieldsProvider((
          entity: widget.entityName,
          id: widget.entityId!,
        )),
      );
      return async.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) {
          final l10n = AppLocalizations.of(context);
          return Padding(
            padding: const EdgeInsets.all(8),
            child: Text('${l10n.failedToLoadCustomFields} $e'),
          );
        },
        data: (data) => _buildFields(data.definitions, data),
      );
    }

    final defsAsync = ref.watch(
      customFieldDefinitionsProvider((
        entityName: widget.entityName,
        includeInactive: false,
      )),
    );
    return defsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (defs) => _buildFields(defs, null),
    );
  }

  Widget _buildFields(
    List<CustomFieldDefinitionReadDto> definitions,
    EntityCustomFieldsReadDto? existing,
  ) {
    if (!_initialized) {
      widget.controller.initialize(definitions, existing);
      _initialized = true;
    }

    final visible = definitions.where((d) => !d.isHidden).toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          AppLocalizations.of(context).additionalFields,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ...visible.map((def) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DynamicCustomFieldWidget(
              definition: def,
              readOnly: widget.readOnly,
              controller: widget.controller.textController(def.id) ??
                  TextEditingController(),
              boolValue: widget.controller.boolValue(def.id),
              onBoolChanged: (v) =>
                  widget.controller.setBool(def.id, v ?? false),
              multiSelected: widget.controller.multiValue(def.id),
              onMultiChanged: (v) => widget.controller.setMulti(def.id, v),
            ),
          );
        }),
      ],
    );
  }
}

/// Saves custom field values after the parent entity is persisted.
Future<void> saveCustomFieldsForEntity({
  required WidgetRef ref,
  required String entityName,
  required int entityId,
  required DynamicCustomFieldsController controller,
  List<CustomFieldDefinitionReadDto>? definitions,
}) async {
  definitions ??= await ref
      .read(customFieldRepositoryProvider)
      .getDefinitions(entityName);

  final payload = controller.buildPayload(definitions);
  if (payload.isEmpty) return;

  await ref.read(customFieldRepositoryProvider).saveValues(
        entityName: entityName,
        entityId: entityId,
        values: payload,
      );
}
