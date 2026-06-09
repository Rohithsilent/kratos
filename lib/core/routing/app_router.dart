
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../features/welcome/welcome_screen.dart';
import '../../features/auth/sign_in_screen.dart';
import '../../features/auth/verify_email_screen.dart';
import '../../features/auth/forgot_password_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/auth/presentation/providers/auth_state_provider.dart';
import '../../features/workout/presentation/screens/workout_builder_screen.dart';
import '../../features/workout/presentation/screens/workout_detail_screen.dart';
import '../../features/workout/presentation/screens/workout_session_screen.dart';
import '../../features/workout/presentation/screens/workout_complete_screen.dart';
import '../../features/workout/domain/models/workout_model.dart';
import '../../features/daily_planner/presentation/screens/planner_day_detail_screen.dart';
import '../../features/subscription/presentation/subscription_screen.dart';
import 'router_notifier.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: '/welcome',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);

      // If we are still loading the auth state, don't redirect yet
      if (authState.isLoading) return null;

      final isLoggedIn = authState.value != null;
      final isGoingToAuthOrWelcome = state.uri.path == '/welcome' || 
                                     state.uri.path == '/signin' || 
                                     state.uri.path == '/onboarding' ||
                                     state.uri.path == '/forgot-password';

      if (isLoggedIn) {
        // Use currentUser directly as authState.value might have stale emailVerified property
        final user = FirebaseAuth.instance.currentUser;
        final isVerified = user?.emailVerified ?? false;
        
        if (!isVerified && state.uri.path != '/verify-email') {
          return '/verify-email';
        } else if (isVerified && (isGoingToAuthOrWelcome || state.uri.path == '/verify-email')) {
          return '/dashboard';
        }
      } else {
        if (!isGoingToAuthOrWelcome) {
          return '/welcome';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/welcome',
        builder: (context, state) => WelcomeScreen(),
      ),
      GoRoute(
        path: '/signin',
        builder: (context, state) => SignInScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/verify-email',
        builder: (context, state) => VerifyEmailScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => OnboardingScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => DashboardScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => ProfileScreen(),
      ),
      GoRoute(
        path: '/workout/create',
        builder: (context, state) {
          final id = state.uri.queryParameters['id'];
          return WorkoutBuilderScreen(editWorkoutId: id);
        },
      ),
      GoRoute(
        path: '/workout/detail/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return WorkoutDetailScreen(workoutId: id);
        },
      ),
      GoRoute(
        path: '/workout/session/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return WorkoutSessionScreen(workoutId: id);
        },
      ),
      GoRoute(
        path: '/workout/complete',
        builder: (context, state) {
          final session = state.extra as WorkoutSession;
          return WorkoutCompleteScreen(session: session);
        },
      ),
      GoRoute(
        path: '/planner/detail',
        builder: (context, state) {
          final date = state.extra as DateTime;
          return PlannerDayDetailScreen(date: date);
        },
      ),
      GoRoute(
        path: '/subscription',
        builder: (context, state) => SubscriptionScreen(),
      ),
    ],
  );
});

