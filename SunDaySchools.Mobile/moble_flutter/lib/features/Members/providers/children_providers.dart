import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_providers.dart';
import '../models/child_models.dart';
import '../repositories/children_repository.dart';

final childrenRepositoryProvider = Provider((ref) {
  return ChildrenRepository(ref.watch(dioProvider));
});

final childrenListProvider = FutureProvider<List<ChildReadDto>>((ref) async {
  return ref.watch(childrenRepositoryProvider).getAll();
});

final childDetailProvider = FutureProvider.family<ChildReadDto, int>((ref, id) async {
  return ref.watch(childrenRepositoryProvider).getById(id);
});
