import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openon_app/core/models/models.dart';
import 'package:openon_app/core/providers/providers.dart';
import 'package:openon_app/features/auth/screens/welcome_screen.dart';
import 'package:openon_app/features/auth/screens/login_screen.dart';
import 'package:openon_app/features/auth/screens/signup_screen.dart';
import 'package:openon_app/features/home/screens/home_screen.dart';
import 'package:openon_app/features/recipients/screens/recipients_screen.dart';
import 'package:openon_app/features/recipients/screens/add_recipient_screen.dart';
import 'package:openon_app/features/create_capsule/screens/create_capsule_screen.dart';
import 'package:openon_app/features/capsule/screens/locked_capsule_screen.dart';
import 'package:openon_app/features/capsule/screens/opening_animation_screen.dart';
import 'package:openon_app/features/capsule/screens/opened_letter_screen.dart';
import 'package:openon_app/features/profile/screens/profile_screen.dart';

/// Route names
class Routes {
  static const welcome = '/';
  static const login = '/login';
  static const signup = '/signup';
  static const home = '/home';
  static const recipients = '/recipients';
  static const addRecipient = '/recipients/add';
  static const createCapsule = '/create-capsule';
  static const lockedCapsule = '/capsule/:id';
  static const openingAnimation = '/capsule/:id/opening';
  static const openedLetter = '/capsule/:id/opened';
  static const profile = '/profile';
}

final goRouterProvider = Provider<GoRouter>((ref) {
  final isAuthenticated = ref.watch(isAuthenticatedProvider);
  
  return GoRouter(
    initialLocation: Routes.welcome,
    redirect: (context, state) {
      final isAuth = isAuthenticated;
      final isGoingToAuth = state.matchedLocation == Routes.welcome ||
          state.matchedLocation == Routes.login ||
          state.matchedLocation == Routes.signup;
      
      // Redirect to home if authenticated and trying to access auth screens
      if (isAuth && isGoingToAuth) {
        return Routes.home;
      }
      
      // Redirect to welcome if not authenticated and trying to access protected screens
      if (!isAuth && !isGoingToAuth) {
        return Routes.welcome;
      }
      
      return null;
    },
    routes: [
      // Auth routes
      GoRoute(
        path: Routes.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: Routes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: Routes.signup,
        builder: (context, state) => const SignupScreen(),
      ),
      
      // Main app routes
      GoRoute(
        path: Routes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: Routes.recipients,
        builder: (context, state) => const RecipientsScreen(),
      ),
      GoRoute(
        path: Routes.addRecipient,
        builder: (context, state) {
          final recipient = state.extra as Recipient?;
          return AddRecipientScreen(recipient: recipient);
        },
      ),
      GoRoute(
        path: Routes.createCapsule,
        builder: (context, state) => const CreateCapsuleScreen(),
      ),
      GoRoute(
        path: '/capsule/:id',
        builder: (context, state) {
          final capsuleId = state.pathParameters['id']!;
          final capsule = state.extra as Capsule;
          return LockedCapsuleScreen(capsule: capsule);
        },
      ),
      GoRoute(
        path: '/capsule/:id/opening',
        builder: (context, state) {
          final capsule = state.extra as Capsule;
          return OpeningAnimationScreen(capsule: capsule);
        },
      ),
      GoRoute(
        path: '/capsule/:id/opened',
        builder: (context, state) {
          final capsule = state.extra as Capsule;
          return OpenedLetterScreen(capsule: capsule);
        },
      ),
      GoRoute(
        path: Routes.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
});
