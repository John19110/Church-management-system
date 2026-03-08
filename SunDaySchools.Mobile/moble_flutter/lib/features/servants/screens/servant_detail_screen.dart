import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/servants_providers.dart';
import '../../../shared/widgets/common_widgets.dart' as cw;

class ServantDetailScreen extends ConsumerWidget {
  final int id;
  const ServantDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servantAsync = ref.watch(servantDetailProvider(id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Servant Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              await context.push('/servants/$id/edit');
              ref.invalidate(servantDetailProvider(id));
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () async {
              final confirmed = await cw.showConfirmDialog(
                context,
                title: 'Delete Servant',
                content: 'Are you sure you want to delete this servant?',
              );
              if (!confirmed) return;
              try {
                await ref.read(servantsRepositoryProvider).delete(id);
                if (context.mounted) {
                  cw.showSuccessSnackbar(context, 'Servant deleted');
                  context.pop();
                }
              } catch (e) {
                if (context.mounted) cw.showErrorSnackbar(context, e.toString());
              }
            },
          ),
        ],
      ),
      body: servantAsync.when(
        loading: () => const cw.LoadingWidget(),
        error: (e, _) => cw.AppErrorWidget(message: e.toString()),
        data: (servant) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: servant.imageUrl != null
                    ? CircleAvatar(
                        radius: 56,
                        backgroundImage: NetworkImage(servant.imageUrl!),
                      )
                    : CircleAvatar(
                        radius: 56,
                        backgroundColor: const Color(0xFFED8936),
                        child: Text(
                          (servant.name?.isNotEmpty == true)
                              ? servant.name![0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              fontSize: 40, color: Colors.white),
                        ),
                      ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  servant.name ?? 'Unknown',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 24),
              _InfoTile(label: 'Phone', value: servant.phoneNumber),
              _InfoTile(label: 'Birth Date', value: servant.birthDate),
              _InfoTile(label: 'Joining Date', value: servant.joiningDate),
              _InfoTile(label: 'Classroom', value: servant.classroomId?.toString()),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String? value;

  const _InfoTile({required this.label, this.value});

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value!)),
        ],
      ),
    );
  }
}
