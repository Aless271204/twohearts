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

class AppRoutes {
  static const String initial = '/';
  static const String signUpLogin = '/sign-up-login-screen';
  static const String socialScreen = '/social-screen';
  static const String shopScreen = '/shop-screen';
  static const String homeScreen = '/home-screen';
  static const String memoriesScreen = '/memories-screen';
  static const String activitiesScreen = '/activities-screen';
  static const String pairingScreen = '/pairing-screen';
  static const String profileScreen = '/profile-screen';
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.initial,
  redirect: (context, state) {
    final session = Supabase.instance.client.auth.currentSession;
    final isLoggedIn = session != null;
    final isOnAuth =
        state.matchedLocation == AppRoutes.initial ||
        state.matchedLocation == AppRoutes.signUpLogin;

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
        // Branch 4: Actividades
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
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final dynamic _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
