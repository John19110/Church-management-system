import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bumped when admin changes custom field definitions for an entity type.
final customFieldDefinitionsRevisionProvider =
    StateProvider.family<int, String>((ref, entity) => 0);
