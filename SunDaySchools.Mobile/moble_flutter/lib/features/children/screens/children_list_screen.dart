import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/children_providers.dart';
import '../../../shared/widgets/common_widgets.dart' as cw;
import '../../../core/l10n/app_localizations.dart';

class ChildrenListScreen extends ConsumerWidget {
  const ChildrenListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final childrenAsync = ref.watch(childrenListProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.children)),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push('/children/add');
          ref.invalidate(childrenListProvider);
        },
        child: const Icon(Icons.add),
      ),
      body: childrenAsync.when(
        loading: () => const cw.LoadingWidget(),
        error: (e, _) => cw.AppErrorWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(childrenListProvider),
        ),
        data: (children) {
          if (children.isEmpty) {
            return cw.EmptyWidget(
              message: l10n.noChildren,
              icon: Icons.child_care,
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(childrenListProvider),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: children.length,
              itemBuilder: (context, index) {
                final child = children[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF4299E1),
                      child: Text(
                        (child.fullName?.isNotEmpty == true)
                            ? child.fullName![0].toUpperCase()
                            : '?',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(child.fullName ?? 'Unknown'),
                    subtitle: Text(child.gender ?? ''),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      await context.push('/children/${child.id}');
                      ref.invalidate(childrenListProvider);
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
