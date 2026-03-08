import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/servants_providers.dart';
import '../../../shared/widgets/common_widgets.dart' as cw;

class ServantsListScreen extends ConsumerWidget {
  const ServantsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servantsAsync = ref.watch(servantsListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Servants')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push('/servants/add');
          ref.invalidate(servantsListProvider);
        },
        child: const Icon(Icons.add),
      ),
      body: servantsAsync.when(
        loading: () => const cw.LoadingWidget(),
        error: (e, _) => cw.AppErrorWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(servantsListProvider),
        ),
        data: (servants) {
          if (servants.isEmpty) {
            return const cw.EmptyWidget(
              message: 'No servants yet. Tap + to add one.',
              icon: Icons.people,
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(servantsListProvider),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: servants.length,
              itemBuilder: (context, index) {
                final servant = servants[index];
                return Card(
                  child: ListTile(
                    leading: servant.imageUrl != null
                        ? CircleAvatar(
                            backgroundImage: NetworkImage(servant.imageUrl!),
                          )
                        : CircleAvatar(
                            backgroundColor: const Color(0xFFED8936),
                            child: Text(
                              (servant.name?.isNotEmpty == true)
                                  ? servant.name![0].toUpperCase()
                                  : '?',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                    title: Text(servant.name ?? 'Unknown'),
                    subtitle: Text(servant.phoneNumber ?? ''),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      await context.push('/servants/${servant.id}');
                      ref.invalidate(servantsListProvider);
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
