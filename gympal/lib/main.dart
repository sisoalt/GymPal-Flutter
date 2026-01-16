import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data/services/hive_service.dart';
import 'providers/auth_provider.dart';
import 'providers/workout_provider.dart';
import 'providers/calorie_provider.dart';
import 'providers/progress_provider.dart'; // <--- 1. ADD THIS IMPORT
import 'providers/theme_provider.dart';
import 'data/services/notification_service.dart';
import 'screens/splash/splash_screen.dart';
// Note: `LoginScreen` and `MainLayout` are loaded by the splash screen when needed.

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.init();
  await NotificationService().init();
  runApp(const GymPalApp());
}

class GymPalApp extends StatelessWidget {
  const GymPalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..loadSession()),
        ChangeNotifierProvider(create: (_) => WorkoutProvider()..loadWorkouts()),
        ChangeNotifierProvider(create: (_) => CalorieProvider()..loadLogs(DateTime.now())),
        
        // <--- 2. ADD THIS LINE
        ChangeNotifierProvider(create: (_) => ProgressProvider()..loadLogs()), 
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer2<AuthProvider, ThemeProvider>(
        builder: (context, auth, themeProv, _) {
          return MaterialApp(
            title: 'GymPal',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              brightness: Brightness.light,
              primarySwatch: Colors.blue,
              useMaterial3: true,
              scaffoldBackgroundColor: const Color(0xFFF7F7F7),
            ),
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              primarySwatch: Colors.blue,
              useMaterial3: true,
            ),
            themeMode: themeProv.isDark ? ThemeMode.dark : ThemeMode.light,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}