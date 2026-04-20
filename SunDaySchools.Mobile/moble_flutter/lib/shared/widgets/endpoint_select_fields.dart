import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/selection_service.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/select_option.dart';
import '../../features/auth/providers/auth_providers.dart';
import 'select_option_fields.dart';

class EndpointSelectDropdown extends ConsumerStatefulWidget {
  final String endpoint;
  final String label;
  final String? hintText;
  final int? value;
  final bool enabled;
  final void Function(int?) onChanged;
  final String? Function(int?)? validator;

  const EndpointSelectDropdown({
    super.key,
    required this.endpoint,
    required this.label,
    required this.value,
    required this.onChanged,
    this.hintText,
    this.enabled = true,
    this.validator,
  });

  @override
  ConsumerState<EndpointSelectDropdown> createState() =>
      _EndpointSelectDropdownState();
}

class _EndpointSelectDropdownState extends ConsumerState<EndpointSelectDropdown> {
  late Future<List<SelectOption>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant EndpointSelectDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.endpoint != widget.endpoint) {
      _future = _load();
    }
  }

  Future<List<SelectOption>> _load() {
    final dio = ref.read(dioProvider);
    final service = SelectionService(dio);
    return service.fetchSelection(widget.endpoint);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SelectOption>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(),
          );
        }
        if (snapshot.hasError) {
          final msg = snapshot.error.toString();
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('Failed to load options: $msg'),
          );
        }
        final options = snapshot.data ?? const <SelectOption>[];
        return SelectOptionDropdown(
          label: widget.label,
          hintText: widget.hintText,
          options: options,
          value: widget.value,
          enabled: widget.enabled,
          onChanged: widget.onChanged,
          validator: widget.validator,
        );
      },
    );
  }
}

class EndpointMultiSelectField extends ConsumerStatefulWidget {
  final String endpoint;
  final String label;
  final String? hintText;
  final List<int> selectedIds;
  final void Function(List<int>) onChanged;

  const EndpointMultiSelectField({
    super.key,
    required this.endpoint,
    required this.label,
    required this.selectedIds,
    required this.onChanged,
    this.hintText,
  });

  @override
  ConsumerState<EndpointMultiSelectField> createState() =>
      _EndpointMultiSelectFieldState();
}

class _EndpointMultiSelectFieldState extends ConsumerState<EndpointMultiSelectField> {
  late Future<List<SelectOption>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant EndpointMultiSelectField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.endpoint != widget.endpoint) {
      _future = _load();
    }
  }

  Future<List<SelectOption>> _load() {
    final dio = ref.read(dioProvider);
    final service = SelectionService(dio);
    return service.fetchSelection(widget.endpoint);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SelectOption>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(),
          );
        }
        if (snapshot.hasError) {
          final msg = snapshot.error.toString();
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('Failed to load options: $msg'),
          );
        }
        final options = snapshot.data ?? const <SelectOption>[];
        return SelectOptionMultiSelectField(
          label: widget.label,
          hintText: widget.hintText,
          options: options,
          selectedIds: widget.selectedIds,
          onChanged: widget.onChanged,
        );
      },
    );
  }
}

/// Convenience constants to prevent typos in screens.
class SelectionEndpoints {
  static const classrooms = AppConstants.classroomsSelectEndpoint;
  static const meetings = AppConstants.meetingsSelectEndpoint;
  static const servants = AppConstants.servantsSelectEndpoint;
  static const members = AppConstants.membersSelectEndpoint;
}

