import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/theme/app_theme.dart';
import 'core/config/firebase_config.dart';
import 'core/widgets/custom_loading_indicator.dart';
import 'features/auth/screens/google_signin_screen.dart';
import 'features/auth/screens/complete_profile_screen.dart';
import 'features/auth/screens/role_selection_screen.dart';
import 'features/customer/screens/customer_home_screen.dart';
import 'features/vendor/presentation/pages/vendor_shell_screen.dart';
import 'features/onboarding/screens/app_onboarding_screen.dart';
import 'providers/auth_provider.dart';
import 'core/constants/app_constants.dart';
import 'services/notification_service.dart';
import 'services/onboarding_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  runApp(const ProviderScope(child: MyApp()));

  // Initialize Firebase in background
  FirebaseConfig.initialize().then((_) async {
    // Set up FCM background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    // Initialize notification service
    await NotificationService().initialize();
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    // Show splash for minimum 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _showSplash = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Skill Connect',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: _showSplash
          ? SplashScreen(
              onInitializationComplete: () {
                if (mounted) {
                  setState(() {
                    _showSplash = false;
                  });
                }
              },
            )
          : const AuthWrapper(),
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check if app onboarding is completed
    return FutureBuilder<bool>(
      future: OnboardingService().isAppOnboardingCompleted(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: LoadingOverlay(message: 'Loading...'));
        }

        final onboardingCompleted = snapshot.data ?? false;

        // If onboarding not completed, show onboarding screen
        if (!onboardingCompleted) {
          return const AppOnboardingScreen();
        }

        // Onboarding completed, check auth state
        final authState = ref.watch(authStateProvider);

        return authState.when(
          data: (user) {
            if (user == null) {
              // Not logged in - show Google sign-in screen
              return const GoogleSignInScreen();
            }

            // Logged in - check if profile is complete
            return const ProfileCheckWrapper();
          },
          loading: () =>
              const Scaffold(body: LoadingOverlay(message: 'Initializing...')),
          error: (error, stack) => Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('Authentication Error'),
                  const SizedBox(height: 8),
                  Text(error.toString(), textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class ProfileCheckWrapper extends ConsumerWidget {
  const ProfileCheckWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = ref.read(authServiceProvider);
    final userId = authService.currentUserId;

    if (userId == null) {
      return const GoogleSignInScreen();
    }

    return FutureBuilder<bool>(
      future: authService.isProfileComplete(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: LoadingOverlay(message: 'Loading profile...'),
          );
        }

        final isComplete = snapshot.data ?? false;

        if (!isComplete) {
          // Profile not complete - show role selection screen
          return const RoleSelectionWrapper();
        }

        // Profile complete - show role-based home
        return const RoleBasedHome();
      },
    );
  }
}

class RoleBasedHome extends ConsumerWidget {
  const RoleBasedHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userDataAsync = ref.watch(currentUserProvider);

    return userDataAsync.when(
      data: (userData) {
        if (userData == null) {
          return const GoogleSignInScreen();
        }

        final role = userData.role.toLowerCase().trim();

        if (role == AppConstants.roleCustomer) {
          return const CustomerHomeScreen();
        } else if (role == AppConstants.roleVendor) {
          return const VendorShellScreen();
        } else {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 64,
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Unknown User Role',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Role: ${userData.role}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Expected: customer or vendor',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () async {
                        final authService = ref.read(authServiceProvider);
                        await authService.signOut();
                      },
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      },
      loading: () =>
          const Scaffold(body: LoadingOverlay(message: 'Loading profile...')),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 24),
                const Text(
                  'Error Loading Profile',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    final authService = ref.read(authServiceProvider);
                    await authService.signOut();
                  },
                  child: const Text('Sign Out'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RoleSelectionWrapper extends StatelessWidget {
  const RoleSelectionWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _showRoleSelection(context),
      builder: (context, snapshot) {
        // This will never actually show because we navigate immediately
        return const Scaffold(body: LoadingOverlay(message: 'Loading...'));
      },
    );
  }

  Future<String?> _showRoleSelection(BuildContext context) async {
    // Wait for the next frame to ensure context is ready
    await Future.delayed(Duration.zero);

    if (!context.mounted) return null;

    // Show role selection screen and wait for result
    final role = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
    );

    if (role != null && context.mounted) {
      // Navigate to complete profile screen with selected role
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => CompleteProfileScreen(role: role)),
      );
    }

    return role;
  }
}
