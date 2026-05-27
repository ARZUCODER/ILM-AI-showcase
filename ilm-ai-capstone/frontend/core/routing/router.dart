import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../features/admin/ui/admin_dashboard_page.dart';
import '../../features/admin/ui/admin_login_page.dart';
import '../../features/auth/ui/auth_page.dart';
import '../../features/chat/ui/chat_page.dart';
import '../../features/landing/ui/landing_page.dart';
import '../../features/landing/ui/terms_page.dart';
import '../../features/landing/ui/privacy_page.dart';
import '../../features/landing/ui/delete_account_web_page.dart';
import '../../features/quiz/ui/flashcards_page.dart';
import '../../features/premium/ui/premium_page.dart';
import '../ui/app_shell.dart';
import '../ui/responsive_demo_wrapper.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('role');

    final user = FirebaseAuth.instance.currentUser;
    final loggedIn = user != null;

    final path = state.matchedLocation;

    if (path == '/terms' || path == '/privacy' || path == '/delete-account') {
      return null;
    }

    if (path.startsWith('/admin')) {
      if (path == '/admin' && role == 'admin') return '/admin/dashboard';
      if (path == '/admin' && role != 'admin') return null;
      if (path == '/admin/dashboard' && role != 'admin') return '/admin';
      return null;
    }

    if (!kIsWeb && path == '/') {
      return loggedIn ? '/app' : '/auth';
    }

    if (path == '/') return null;
    if (!loggedIn && path != '/auth') return '/auth';
    if (loggedIn && path == '/auth') {
      if (role == 'admin') return '/admin/dashboard';
      return '/app';
    }
    return null;
  },
  routes: [
    GoRoute(path: '/', builder: (context, state) => const LandingPage()),
    GoRoute(path: '/terms', builder: (context, state) => const TermsPage()),
    GoRoute(path: '/privacy', builder: (context, state) => const PrivacyPage()),
    GoRoute(path: '/delete-account', builder: (context, state) => const DeleteAccountWebPage()),
    GoRoute(path: '/auth', builder: (context, state) => const ResponsiveDemoWrapper(child: AuthPage())),
    GoRoute(path: '/app', builder: (context, state) => const ResponsiveDemoWrapper(child: AppShell())),
    GoRoute(path: '/chat', builder: (context, state) => const ResponsiveDemoWrapper(child: ChatPage())),
    GoRoute(path: '/flashcards', builder: (context, state) => const ResponsiveDemoWrapper(child: FlashcardsPage())),
    GoRoute(path: '/premium', builder: (context, state) => const ResponsiveDemoWrapper(child: PremiumPage())),
    GoRoute(path: '/admin', builder: (context, state) => const AdminLoginPage()),
    GoRoute(path: '/admin/dashboard', builder: (context, state) => const AdminDashboardPage()),
  ],
);