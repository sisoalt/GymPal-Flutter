import 'package:flutter/material.dart';
import 'dashboard/home_screen.dart';
import 'workouts/workout_list_screen.dart';
import 'calories/calorie_tracker_screen.dart';
import 'progress/progress_screen.dart'; // <--- 1. Import this
import 'profile/profile_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  // <--- 2. Add ProgressScreen to this list
  final List<Widget> _screens = [
    const HomeScreen(),
    const WorkoutListScreen(),
    const CalorieTrackerScreen(),
    const ProgressScreen(), // <--- NEW SCREEN
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: Theme.of(context).colorScheme.surface,
        indicatorColor: Theme.of(context).colorScheme.primary.withAlpha((0.1 * 255).round()),
        elevation: 0,
        shadowColor: Colors.black.withAlpha((0.05 * 255).round()),
        surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
        // <--- 3. Add the Navigation Button here
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.fitness_center_outlined),
            selectedIcon: Icon(Icons.fitness_center),
            label: 'Workouts',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_fire_department_outlined),
            selectedIcon: Icon(Icons.local_fire_department),
            label: 'Calories',
          ),
          NavigationDestination(
            icon: Icon(Icons.show_chart),
            selectedIcon: Icon(Icons.stacked_line_chart),
            label: 'Progress',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
