import 'package:flutter/material.dart';
import 'config/app_config.dart';
import 'screens/auth/google_login_screen.dart';
import 'screens/auth/profile_setup_screen.dart';
import 'screens/home/home_screen.dart';
import 'services/buddy_repository.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env configs safely
  await AppConfig.init();

  // Initialize Auth & Database Repositories
  await BuddyRepository.instance.init();

  runApp(const BuddyApp());
}

class BuddyApp extends StatelessWidget {
  const BuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Buddy - Hire a Buddy or Become One',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthGate(),
    );
  }
}

/// Authentication Gateway:
/// Enforces mandatory Google Sign-In as the very first screen for new or logged-out users.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = BuddyRepository.instance;

    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) {
        if (!repo.isAuthenticated) {
          return const GoogleLoginScreen();
        }

        final user = repo.currentUser!;
        // Mandatory profile completion gate:
        // If a user has logged in but has not saved their mandatory profile details,
        // stay on ProfileSetupScreen across browser refreshes or app re-launches.
        if (!user.isProfileComplete) {
          return ProfileSetupScreen(
            initialProfile: user,
            isInitialSetup: true,
          );
        }

        return const HomeScreen();
      },
    );
  }
}
