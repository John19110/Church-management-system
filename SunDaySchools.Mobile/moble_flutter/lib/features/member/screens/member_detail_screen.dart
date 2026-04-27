import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/members_providers.dart';
import '../../../shared/widgets/common_widgets.dart' as cw;
import '../../../core/l10n/app_localizations.dart';
import '../../../shared/widgets/app_network_avatar.dart';

class MemberDetailScreen extends ConsumerWidget {
  final int id;
  const MemberDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    if (id <= 0) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.memberDetails)),
        body: cw.AppErrorWidget(
          message:
              'Invalid member id. Open this screen from the list after the API returns real ids.',
          onRetry: () {
            if (context.mounted) context.pop();
          },
        ),
      );
    }

    final memberAsync = ref.watch(memberDetailProvider(id));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.memberDetails),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              await context.push('/member/$id/edit');
              ref.invalidate(memberDetailProvider(id));
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () async {
              final confirmed = await cw.showConfirmDialog(
                context,
                title: l10n.deleteMember,
                content: l10n.confirmDeleteMember,
              );
              if (!confirmed) return;
              try {
                await ref.read(membersRepositoryProvider).delete(id);
                if (context.mounted) {
                  cw.showSuccessSnackbar(context, l10n.memberDeletedSuccessfully);
                  context.pop();
                }
              } catch (e) {
                if (context.mounted) cw.showErrorSnackbar(context, e.toString());
              }
            },
          ),
        ],
      ),
      body: memberAsync.when(
        loading: () => const cw.LoadingWidget(),
        error: (e, _) => cw.AppErrorWidget(message: e.toString()),
        data: (member) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: AppNetworkAvatar(
                  imageUrl: member.imageUrl,
                  radius: 48,
                  backgroundColor: const Color(0xFF4299E1),
                  placeholder: Text(
                    (member.fullName?.isNotEmpty == true)
                        ? member.fullName![0].toUpperCase()
                        : '?',
                    style: const TextStyle(fontSize: 36, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  member.fullName ?? 'Unknown',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 24),
              _InfoTile(label: l10n.gender, value: member.gender),
              _InfoTile(label: l10n.address, value: member.address),
              _InfoTile(label: l10n.dateOfBirth, value: member.dateOfBirth),
              _InfoTile(label: l10n.joiningDate, value: member.joiningDate),
              _InfoTile(
                label: 'Last Attendance',
                value: member.lastAttendanceDate,
              ),
              _InfoTile(
                label: 'Days Attended',
                value: member.totalNumberOfDaysAttended?.toString(),
              ),
              _InfoTile(
                  label: l10n.classroomId,
                  value: member.classroomId?.toString()),
              if (member.phoneNumbers != null &&
                  member.phoneNumbers!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(l10n.phoneNumbers,
                    style: Theme.of(context).textTheme.titleMedium),
                ...member.phoneNumbers!.map((p) => Padding(
                      padding: const EdgeInsets.only(left: 8, top: 4),
                      child: Text('${p.relation ?? ''}: ${p.phoneNumber ?? ''}'),
                    )),
              ],
              if (member.notes != null && member.notes!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(l10n.notes,
                    style: Theme.of(context).textTheme.titleMedium),
                ...member.notes!.map((n) => Padding(
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
