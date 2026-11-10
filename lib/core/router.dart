import 'package:go_router/go_router.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/home/home_bengkel_screen.dart';
import '../features/home/home_pengguna_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/splash/splash_screen.dart';
import '../providers/auth_provider.dart';

String homePathFor(String role) =>
    role == 'bengkel' ? '/home/bengkel' : '/home/pengguna';

String _roleOf(GoRouterState s) =>
    s.uri.queryParameters['role'] == 'bengkel' ? 'bengkel' : 'pengguna';

GoRouter createRouter(AuthProvider auth) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: auth,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      // Halaman home hanya untuk yang sudah login
      if (!auth.isLoggedIn && loc.startsWith('/home')) return '/onboarding';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (c, s) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (c, s) => const OnboardingScreen()),
      GoRoute(path: '/login', builder: (c, s) => LoginScreen(role: _roleOf(s))),
      GoRoute(
          path: '/register',
          builder: (c, s) => RegisterScreen(role: _roleOf(s))),
      GoRoute(
          path: '/home/pengguna',
          builder: (c, s) => const HomePenggunaScreen()),
      GoRoute(
          path: '/home/bengkel', builder: (c, s) => const HomeBengkelScreen()),
    ],
  );
}
