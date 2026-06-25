import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medisync/core/di/injection_container.dart';
import 'package:medisync/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:medisync/features/auth/presentation/views/login_view.dart';
import 'package:medisync/features/auth/presentation/views/profile_selector_view.dart';
import 'package:medisync/features/auth/presentation/views/recover_password_view.dart';
import 'package:medisync/features/auth/presentation/views/register_view.dart';
import 'package:medisync/features/auth/presentation/views/splash_view.dart';
import 'package:medisync/features/device/presentation/views/device_scan_view.dart';
import 'package:medisync/features/home/presentation/views/home_placeholder_view.dart';
import 'package:medisync/features/user_profile/presentation/viewmodels/links_viewmodel.dart';
import 'package:medisync/features/user_profile/presentation/viewmodels/profile_viewmodel.dart';
import 'package:medisync/features/user_profile/presentation/views/links_view.dart';
import 'package:medisync/features/user_profile/presentation/views/profile_view.dart';
import 'package:provider/provider.dart';

abstract final class AppRoutes {
  static const splash = '/';
  static const login = '/auth/login';
  static const register = '/auth/register';
  static const profileSelector = '/auth/profile-selector';
  static const recoverPassword = '/auth/recover-password';
  static const home = '/home';
  static const profile = '/profile';
  static const links = '/links';
  static const device = '/device';
}

abstract final class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: sl<AuthViewModel>(),
    redirect: _redirect,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, _) => const SplashView(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, _) => const LoginView(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, _) => const RegisterView(),
      ),
      GoRoute(
        path: AppRoutes.profileSelector,
        builder: (_, _) => const ProfileSelectorView(),
      ),
      GoRoute(
        path: AppRoutes.recoverPassword,
        builder: (_, _) => const RecoverPasswordView(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (_, _) => const HomeShellView(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (_, _) => ChangeNotifierProvider.value(
          value: sl<ProfileViewModel>(),
          child: const ProfileView(),
        ),
      ),
      GoRoute(
        path: AppRoutes.links,
        builder: (_, _) => ChangeNotifierProvider.value(
          value: sl<LinksViewModel>(),
          child: const LinksView(),
        ),
      ),
      GoRoute(
        path: AppRoutes.device,
        builder: (_, _) => const DeviceScanView(),
      ),
    ],
  );

  static String? _redirect(BuildContext context, GoRouterState state) {
    final isLoggedIn = sl<AuthViewModel>().state.user != null;
    final loc = state.matchedLocation;

    if (loc == AppRoutes.splash) return null;

    final isAuthRoute = loc.startsWith('/auth');
    if (!isLoggedIn && !isAuthRoute) return AppRoutes.login;
    if (isLoggedIn && isAuthRoute) return AppRoutes.home;
    return null;
  }
}
