import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../presentation/home_screen/home_screen.dart';
import '../presentation/memories_screen/memories_screen.dart';
import '../presentation/sign_up_login_screen/sign_up_login_screen.dart';
import '../presentation/social_screen/social_screen.dart';
import '../presentation/shop_screen/shop_screen.dart';
import '../presentation/activities_screen/activities_screen.dart';
import '../presentation/pairing_screen/pairing_screen.dart';
import '../presentation/profile_screen/profile_screen.dart';
import '../widgets/app_scaffold.dart';
import '../services/scene_audio_policy.dart';
import '../services/login_welcome_session.dart';
import '../presentation/sign_up_login_screen/nido_welcome_screen.dart';

class AppRoutes {
  static const String initial = '/';
  static const String signUpLogin = '/sign-up-login-screen';
  static const String welcomeScreen = '/welcome-screen';
  static const String socialScreen = '/social-screen';
  static const String shopScreen = '/shop-screen';
  static const String homeScreen = '/home-screen';
  static const String memoriesScreen = '/memories-screen';
  static const String activitiesScreen = '/activities-screen';
  static const String pairingScreen = '/pairing-screen';
  static const String profileScreen = '/profile-screen';
}

final GoRouter appRouter = GoRouter(
  observers: [SceneAudioRouteObserver()],
  initialLocation: AppRoutes.initial,
  redirect: (context, state) {
    final session = Supabase.instance.client.auth.currentSession;
    final isLoggedIn = session != null;
    final isOnAuth =
        state.matchedLocation == AppRoutes.initial ||
        state.matchedLocation == AppRoutes.signUpLogin;

    final welcomeDone = session?.user.userMetadata?['nido_welcome_complete'] == true;
    if (isLoggedIn && state.matchedLocation == AppRoutes.welcomeScreen &&
        (welcomeDone || !LoginWelcomeSession.instance.needsWelcome(session.user.id))) {
      return AppRoutes.memoriesScreen;
    }
    if (isLoggedIn && !welcomeDone && LoginWelcomeSession.instance.needsWelcome(session.user.id) &&
        state.matchedLocation != AppRoutes.welcomeScreen) {
      final next = isOnAuth ? AppRoutes.memoriesScreen : state.uri.toString();
      return Uri(path: AppRoutes.welcomeScreen, queryParameters: {'next': next}).toString();
    }

    if (isLoggedIn && isOnAuth) {
      // Memories is now the home/center tab
      return AppRoutes.memoriesScreen;
    }
    if (!isLoggedIn && !isOnAuth) {
      return AppRoutes.initial;
    }
    return null;
  },
  refreshListenable: GoRouterRefreshStream(
    Supabase.instance.client.auth.onAuthStateChange,
  ),
  routes: [
    GoRoute(
      path: AppRoutes.welcomeScreen,
      builder: (context, state) => NidoWelcomeScreen(onFinished: () async {
        final user = Supabase.instance.client.auth.currentUser;
        if (user == null) {context.go(AppRoutes.initial); return;}
        await LoginWelcomeSession.instance.complete(user.id);
        // Onboarding is presentation state, never an authorization claim.
        unawaited(Supabase.instance.client.auth.updateUser(UserAttributes(
          data: {'nido_welcome_complete': true},
        )).then((_) {}).catchError((Object _) {}));
        if (!context.mounted) return;
        final next = state.uri.queryParameters['next'];
        const allowed = [AppRoutes.socialScreen, AppRoutes.shopScreen,
          AppRoutes.memoriesScreen, AppRoutes.homeScreen, AppRoutes.activitiesScreen,
          AppRoutes.profileScreen, AppRoutes.pairingScreen];
        final target = next == null ? null : Uri.tryParse(next);
        context.go(target != null && !target.hasScheme && !target.hasAuthority && allowed.contains(target.path)
          ? target.toString() : AppRoutes.memoriesScreen);
      }),
    ),
    GoRoute(
      path: AppRoutes.initial,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const SignUpLoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 280),
      ),
    ),
    GoRoute(
      path: AppRoutes.signUpLogin,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const SignUpLoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 280),
      ),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppScaffold(navigationShell: navigationShell);
      },
      branches: [
        // Branch 0: Social
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.socialScreen,
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: SocialScreen()),
            ),
          ],
        ),
        // Branch 1: Tienda
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.shopScreen,
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: ShopScreen()),
            ),
          ],
        ),
        // Branch 2: Recuerdos — CENTER
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.memoriesScreen,
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: MemoriesScreen()),
            ),
          ],
        ),
        // Branch 3: Mascota
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.homeScreen,
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: HomeScreen()),
            ),
          ],
        ),
        // Branch 4: Juegos (keeps the existing route for saved links)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.activitiesScreen,
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: ActivitiesScreen()),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.pairingScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const PairingScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                .animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ),
    GoRoute(
      path: AppRoutes.profileScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const ProfileScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                .animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ),
  ],
);

/// Converts Supabase auth stream to a Listenable for GoRouter refresh
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<AuthState> stream) {
    notifyListeners();
    _subscription = stream.listen((state) {
      if (state.event == AuthChangeEvent.signedOut) LoginWelcomeSession.instance.reset();
      notifyListeners();
    });
  }

  late final StreamSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
