import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_router.dart';
import '../../../shared/widgets/common_widgets.dart' as cw;
import '../../../shared/widgets/app_section_bottom_navigation_bar.dart';
import '../providers/servants_providers.dart';

class ProfileScreen extends ConsumerWidget {
  final bool showAppBar;

  const ProfileScreen({super.key, this.showAppBar = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(servantProfileProvider);

    return Scaffold(
      appBar: showAppBar ? AppBar(title: const Text('Profile')) : null,
      bottomNavigationBar: const AppSectionBottomNavigationBar(
        currentIndex: 3,
        homeRoute: AppRoutes.servantHome,
      ),
      body: profileAsync.when(
        loading: () => const cw.LoadingWidget(),
        error: (e, _) => cw.AppErrorWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(servantProfileProvider),
        ),
        data: (p) {
          final church = p.church?.name ?? '-';
          final meeting = p.meeting?.name ?? '-';
          final classrooms = p.classrooms.isEmpty
              ? '-'
              : p.classrooms.map((c) => c.name ?? '#${c.id}').join(', ');

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(servantProfileProvider),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 56,
                    backgroundColor: const Color(0xFFED8936),
                    backgroundImage:
                        p.imageUrl != null ? NetworkImage(p.imageUrl!) : null,
                    child: p.imageUrl == null
                        ? Text(
                            (p.name?.isNotEmpty == true)
                                ? p.name![0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 32,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    p.name ?? '-',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 4),
                Center(child: Text(p.phoneNumber ?? '-')),
                const SizedBox(height: 16),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.church_outlined),
                        title: const Text('Church'),
                        subtitle: Text(church),
                      ),
                      const Divider(height: 0),
                      ListTile(
                        leading: const Icon(Icons.groups_outlined),
                        title: const Text('Meeting'),
                        subtitle: Text(meeting),
                      ),
                      const Divider(height: 0),
                      ListTile(
                        leading: const Icon(Icons.class_outlined),
                        title: const Text('Classrooms'),
                        subtitle: Text(classrooms),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.cake_outlined),
                        title: const Text('Birth date'),
                        subtitle: Text(p.birthDate ?? '-'),
                      ),
                      const Divider(height: 0),
                      ListTile(
                        leading: const Icon(Icons.event_available_outlined),
                        title: const Text('Joining date'),
                        subtitle: Text(p.joiningDate ?? '-'),
                      ),
                      const Divider(height: 0),
                      ListTile(
                        leading: const Icon(Icons.auto_awesome_outlined),
                        title: const Text('Spiritual birth date'),
                        subtitle: Text(p.spiritualBirthDate ?? '-'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    await context.push(AppRoutes.profileEdit);
                    ref.invalidate(servantProfileProvider);
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

