import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/children_providers.dart';
import '../../../shared/widgets/common_widgets.dart' as cw;
import '../../../core/l10n/app_localizations.dart';

class ChildDetailScreen extends ConsumerWidget {
  final int id;
  const ChildDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final childAsync = ref.watch(childDetailProvider(id));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.childDetails),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              await context.push('/children/$id/edit');
              ref.invalidate(childDetailProvider(id));
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () async {
              final confirmed = await cw.showConfirmDialog(
                context,
                title: l10n.deleteChild,
                content: l10n.confirmDeleteChild,
              );
              if (!confirmed) return;
              try {
                await ref.read(childrenRepositoryProvider).delete(id);
                if (context.mounted) {
                  cw.showSuccessSnackbar(context, l10n.childDeletedSuccessfully);
                  context.pop();
                }
              } catch (e) {
                if (context.mounted) cw.showErrorSnackbar(context, e.toString());
              }
            },
          ),
        ],
      ),
      body: childAsync.when(
        loading: () => const cw.LoadingWidget(),
        error: (e, _) => cw.AppErrorWidget(message: e.toString()),
        data: (child) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: const Color(0xFF4299E1),
                  child: Text(
                    (child.fullName?.isNotEmpty == true)
                        ? child.fullName![0].toUpperCase()
                        : '?',
                    style: const TextStyle(fontSize: 36, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  child.fullName ?? 'Unknown',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 24),
              _InfoTile(label: l10n.gender, value: child.gender),
              _InfoTile(label: l10n.address, value: child.address),
              _InfoTile(label: l10n.dateOfBirth, value: child.dateOfBirth),
              _InfoTile(label: l10n.joiningDate, value: child.joiningDate),
              _InfoTile(
                label: 'Last Attendance',
                value: child.lastAttendanceDate,
              ),
              _InfoTile(
                label: 'Days Attended',
                value: child.totalNumberOfDaysAttended?.toString(),
              ),
              _InfoTile(
                  label: l10n.classroomId,
                  value: child.classroomId?.toString()),
              if (child.phoneNumbers != null &&
                  child.phoneNumbers!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(l10n.phoneNumbers,
                    style: Theme.of(context).textTheme.titleMedium),
                ...child.phoneNumbers!.map((p) => Padding(
                      padding: const EdgeInsets.only(left: 8, top: 4),
                      child: Text('${p.relation ?? ''}: ${p.phoneNumber ?? ''}'),
                    )),
              ],
              if (child.notes != null && child.notes!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(l10n.notes,
                    style: Theme.of(context).textTheme.titleMedium),
                ...child.notes!.map((n) => Padding(
                      padding: const EdgeInsets.only(left: 8, top: 4),
                      child: Text('• $n'),
                    )),
              ],
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
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
