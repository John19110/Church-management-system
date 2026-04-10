import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/app_router.dart';

class AppSectionBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final String homeRoute;

  const AppSectionBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.homeRoute,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) {
        if (index == currentIndex) return;
        switch (index) {
          case 0:
            context.go(homeRoute);
            break;
          case 1:
            context.go(AppRoutes.member);
            break;
          case 2:
            context.go(AppRoutes.servants);
            break;
          case 3:
            context.go(AppRoutes.attendanceTake);
            break;
        }
      },
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.group_outlined), label: 'Members'),
        NavigationDestination(
          icon: Icon(Icons.people_outline),
          label: 'Servants',
        ),
        NavigationDestination(
          icon: Icon(Icons.fact_check_outlined),
          label: 'Attendance',
        ),
      ],
    );
  }
}
