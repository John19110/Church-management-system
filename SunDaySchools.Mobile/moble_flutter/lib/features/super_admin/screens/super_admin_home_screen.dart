import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../meetings/models/meeting_models.dart';
import '../../meetings/providers/meeting_providers.dart';
import '../providers/super_admin_providers.dart';

class SuperAdminHomeScreen extends ConsumerWidget {
  const SuperAdminHomeScreen({super.key});

  Future<void> _showAddMeetingDialog(BuildContext context, WidgetRef ref) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final weeklyController = TextEditingController();
    var isSubmitting = false;

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (dialogBuilderContext, setState) {
              return AlertDialog(
                title: const Text('Add Meeting'),
                content: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Meeting Name',
                          hintText: 'Enter meeting name',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Meeting name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: weeklyController,
                        decoration: const InputDecoration(
                          labelText: 'Weekly Appointment',
                          hintText: 'YYYY-MM-DDTHH:MM:SS',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Weekly appointment is required';
                          }
                          if (DateTime.tryParse(value.trim()) == null) {
                            return 'Enter a valid ISO date/time';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: isSubmitting
                        ? null
                        : () => Navigator.of(dialogContext).pop(),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            setState(() => isSubmitting = true);
                          try {
                              final weekly = DateTime.tryParse(
                                weeklyController.text.trim(),
                              );
                              if (weekly == null) {
                                throw const FormatException(
                                  'Invalid weekly appointment format.',
                                );
                              }
                              await ref
                                  .read(superAdminRepositoryProvider)
                                  .addMeeting(
                                    MeetingAddDto(
                                      name: nameController.text.trim(),
                                      weeklyAppointment: weekly,
                                    ),
                                  );
                              ref.invalidate(visibleMeetingsProvider);
                              if (context.mounted) {
                                Navigator.of(dialogContext).pop();
                                showSuccessSnackbar(
                                  context,
                                  'Meeting added successfully.',
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                showErrorSnackbar(context, e.toString());
                              }
                            } finally {
                              if (dialogBuilderContext.mounted) {
                                setState(() => isSubmitting = false);
                              }
                            }
                          },
                    child: isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Add'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      nameController.dispose();
      weeklyController.dispose();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final meetingsAsync = ref.watch(visibleMeetingsProvider);
    final pendingAdminsAsync = ref.watch(pendingAdminsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Meeting',
            onPressed: () => _showAddMeetingDialog(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await TokenStorage.deleteToken();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(visibleMeetingsProvider);
          ref.invalidate(pendingAdminsProvider);
          await ref.read(visibleMeetingsProvider.future);
          await ref.read(pendingAdminsProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Pending Admins card ───────────────────────────────────────
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor:
                          Theme.of(context).colorScheme.secondaryContainer,
                      child: Icon(
                        Icons.admin_panel_settings,
                        color: Theme.of(context)
                            .colorScheme
                            .onSecondaryContainer,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.pendingAdmins,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          pendingAdminsAsync.when(
                            data: (list) => Text(
                              '${list.length} pending',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: list.isNotEmpty
                                        ? Theme.of(context).colorScheme.error
                                        : Theme.of(context)
                                            .colorScheme
                                            .secondary,
                                  ),
                            ),
                            loading: () => const Text('Loading...'),
                            error: (e, _) => Text('Error: $e'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Meetings section ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(Icons.groups, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    l10n.visibleMeetings,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            meetingsAsync.when(
              data: (meetings) {
                if (meetings.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(Icons.groups_outlined,
                              size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 8),
                          Text(
                            l10n.noMeetings,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return Column(
                  children: meetings
                      .map(
                        (m) => Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              child: Icon(
                                Icons.groups,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                              ),
                            ),
                            title: Text(
                              m.name ?? '-',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              'Servants: ${m.servantsCount} • Members: ${m.membersCount}',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => context.push(
                              AppRoutes.meetingDetail,
                              extra: m,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => AppErrorWidget(
                message: e.toString(),
                onRetry: () => ref.invalidate(visibleMeetingsProvider),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
