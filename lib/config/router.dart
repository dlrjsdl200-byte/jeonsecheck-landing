import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/login_screen.dart';
import '../screens/phone_verify_screen.dart';
import '../screens/home_screen.dart';
import '../screens/upload_screen.dart';
import '../screens/analyzing_screen.dart';
import '../screens/result_screen.dart';

final router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final session = Supabase.instance.client.auth.currentSession;
    final isLoggedIn = session != null;
    final isLoginRoute = state.matchedLocation == '/login';

    if (!isLoggedIn && !isLoginRoute) return '/login';
    if (isLoggedIn && isLoginRoute) return '/';
    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/phone-verify',
      builder: (context, state) => const PhoneVerifyScreen(),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/upload',
      builder: (context, state) => const UploadScreen(),
    ),
    GoRoute(
      path: '/analyzing',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return AnalyzingScreen(uploadedFiles: extra);
      },
    ),
    GoRoute(
      path: '/result/:id',
      builder: (context, state) => ResultScreen(
        analysisId: state.pathParameters['id']!,
      ),
    ),
  ],
);
