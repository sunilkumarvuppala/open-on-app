import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openon_app/core/models/models.dart';
import 'package:openon_app/core/providers/providers.dart';
import 'package:openon_app/features/auth/welcome_screen.dart';
import 'package:openon_app/features/auth/login_screen.dart';
import 'package:openon_app/features/auth/signup_screen.dart';
import 'package:openon_app/features/home/home_screen.dart';
import 'package:openon_app/features/receiver/receiver_home_screen.dart';
import 'package:openon_app/features/navigation/main_navigation.dart';
import 'package:openon_app/features/recipients/add_recipient_screen.dart';
import 'package:openon_app/features/recipients/recipients_screen.dart';
import 'package:openon_app/features/create_capsule/create_capsule_screen.dart';
import 'package:openon_app/features/capsule/locked_capsule_screen.dart';
import 'package:openon_app/features/capsule/opening_animation_screen.dart';
import 'package:openon_app/features/capsule/opened_letter_screen.dart';
import 'package:openon_app/features/profile/profile_screen.dart';
import 'package:openon_app/features/profile/edit_profile_screen.dart';
import 'package:openon_app/features/profile/color_scheme_screen.dart';
import 'package:openon_app/features/drafts/drafts_screen.dart';
import 'package:openon_app/features/drafts/draft_letter_screen.dart';
import 'package:openon_app/features/connections/add_connection_screen.dart';
import 'package:openon_app/features/connections/requests_screen.dart';
import 'package:openon_app/features/connections/connections_screen.dart';
import 'package:openon_app/features/connections/connection_detail_screen.dart';
import 'package:openon_app/features/people/people_screen.dart';
import 'package:openon_app/features/self_letters/create_self_letter_screen.dart';
import 'package:openon_app/features/self_letters/self_letters_screen.dart';
import 'package:openon_app/features/self_letters/open_self_letter_screen.dart';

/// Route names
class Routes {
  static const welcome = '/';
  static const login = '/login';
  static const signup = '/signup';
  static const home = '/home';
  static const receiverHome = '/inbox';
  static const recipients = '/recipients';
  static const addRecipient = '/recipients/add';
  static const createCapsule = '/create-capsule';
  static const lockedCapsule = '/capsule/:id';
  static const openingAnimation = '/capsule/:id/opening';
  static const openedLetter = '/capsule/:id/opened';
  static const profile = '/profile';
  static const editProfile = '/profile/edit';
  static const colorScheme = '/profile/color-scheme';
  static const drafts = '/drafts';
  static const draftNew = '/draft/new';
  static String draftById(String draftId) => '/draft/$draftId';
  static const connections = '/connections';
  static const addConnection = '/connections/add';
  static const connectionRequests = '/connections/requests';
  static const connectionDetail = '/connection/:connectionId';
  static const people = '/people';
  static const selfLetters = '/self-letters';
  static const createSelfLetter = '/self-letters/create';
  static String openSelfLetter(String id) => '/self-letters/$id/open';
  static String selfLetterDetail(String id) => '/self-letters/$id';
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
      
      // Redirect to inbox (new home) if authenticated and trying to access auth screens
      if (isAuth && isGoingToAuth) {
        return Routes.receiverHome;
      }
      
      // Redirect to welcome if not authenticated and trying to access protected screens
      // Exclude auth routes from protection check
      final isProtectedRoute = !isGoingToAuth;
      if (!isAuth && isProtectedRoute) {
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
      
      // Main app routes with bottom navigation
      ShellRoute(
        builder: (context, state, child) {
          return MainNavigation(
            location: state.matchedLocation,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: Routes.receiverHome,
            builder: (context, state) => const ReceiverHomeScreen(),
          ),
          GoRoute(
            path: Routes.home,
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: Routes.people,
            builder: (context, state) => const PeopleScreen(),
          ),
        ],
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
        builder: (context, state) {
          final draftData = state.extra as DraftNavigationData?;
          return CreateCapsuleScreen(draftData: draftData);
        },
      ),
      GoRoute(
        path: '/capsule/:id',
        builder: (context, state) {
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
      GoRoute(
        path: Routes.editProfile,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: Routes.colorScheme,
        builder: (context, state) => const ColorSchemeScreen(),
      ),
      GoRoute(
        path: Routes.drafts,
        builder: (context, state) => const DraftsScreen(),
      ),
      GoRoute(
        path: Routes.draftNew,
        builder: (context, state) => const DraftLetterScreen(),
      ),
      GoRoute(
        path: '/draft/:draftId',
        builder: (context, state) {
          final draftId = state.pathParameters['draftId']!;
          return DraftLetterScreen(draftId: draftId);
        },
      ),
      GoRoute(
        path: Routes.connections,
        builder: (context, state) => const ConnectionsScreen(),
      ),
      GoRoute(
        path: Routes.addConnection,
        builder: (context, state) => const AddConnectionScreen(),
      ),
      GoRoute(
        path: Routes.connectionRequests,
        builder: (context, state) => const RequestsScreen(),
      ),
      GoRoute(
        path: Routes.connectionDetail,
        builder: (context, state) {
          final connectionId = state.pathParameters['connectionId']!;
          return ConnectionDetailScreen(connectionId: connectionId);
        },
      ),
      GoRoute(
        path: Routes.selfLetters,
        builder: (context, state) => const SelfLettersScreen(),
      ),
      GoRoute(
        path: Routes.createSelfLetter,
        builder: (context, state) => const CreateSelfLetterScreen(),
      ),
      GoRoute(
        path: '/self-letters/:id/open',
        builder: (context, state) {
          final letterId = state.pathParameters['id']!;
          return OpenSelfLetterScreen(letterId: letterId);
        },
      ),
      GoRoute(
        path: '/self-letters/:id',
        builder: (context, state) {
          final letterId = state.pathParameters['id']!;
          return OpenSelfLetterScreen(letterId: letterId);
        },
      ),
    ],
  );
});
