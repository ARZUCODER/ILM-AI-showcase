import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart' as gsi;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_client.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<bool>>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthNotifier(apiClient);
});

class AuthNotifier extends StateNotifier<AsyncValue<bool>> {
  final ApiClient _apiClient;

  // Siz taqdim etgan to'g'ri Google Client ID
  final String _googleClientId = '227348622815-v7uk166f8ms7ojcf6nl91trgai6tk4pl.apps.googleusercontent.com';

  AuthNotifier(this._apiClient) : super(const AsyncData(false));

  Future<bool> _syncWithBackend(User user, String provider) async {
    try {
      final res = await _apiClient.post('/auth/sync', {
        "email": user.email,
        "name": user.displayName ?? "User",
        "auth_provider": provider,
        "picture_url": user.photoURL ?? "",
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', res['token']);
      await prefs.setString('role', res['role'] ?? 'user');
      await prefs.setString('tier', res['tier'] ?? 'free');
      await prefs.setString('picture_url', user.photoURL ?? "");
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> login(String email, String password, bool isLogin) async {
    state = const AsyncLoading();
    try {
      UserCredential cred;
      if (isLogin) {
        cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        if (cred.user != null) {
          final displayName = email.split('@')[0];
          await cred.user!.updateDisplayName(displayName);
        }
      }
      if (cred.user != null) {
        await cred.user!.reload();
        await _syncWithBackend(cred.user!, 'email');
        state = const AsyncData(true);
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      state = AsyncError(e.message ?? "Authentication failed", StackTrace.current);
      return false;
    } catch (e) {
      state = AsyncError("An error occurred", StackTrace.current);
      return false;
    }
  }

  Future<bool> loginWithGoogle() async {
    state = const AsyncLoading();
    try {
      UserCredential userCred;

      if (kIsWeb) {
        // Web uchun standart Firebase Google ulanishi
        final googleProvider = GoogleAuthProvider();
        userCred = await FirebaseAuth.instance.signInWithPopup(googleProvider);
      } else {
        // Android / iOS uchun yangi google_sign_in 7.2.0 API standarti

        // 1. Singleton instance chaqiramiz
        final googleSignIn = gsi.GoogleSignIn.instance;

        // 2. Majburiy ishga tushirish (Client ID shu yerda beriladi)
        await googleSignIn.initialize(
          serverClientId: _googleClientId,
        );

        // 3. signIn() o'rniga authenticate() ishlatamiz
        final googleUser = await googleSignIn.authenticate();

        if (googleUser == null) {
          state = const AsyncData(false);
          return false; // Foydalanuvchi oynani yopib yuborgan
        }

        // 4. authentication endi Future emas, 'await'siz to'g'ridan-to'g'ri chaqiriladi
        final googleAuth = googleUser.authentication;

        // 5. Yangi xavfsizlik talablariga ko'ra faqat idToken beriladi (accessToken shart emas)
        final credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );

        userCred = await FirebaseAuth.instance.signInWithCredential(credential);
      }

      if (userCred.user != null) {
        final syncSuccess = await _syncWithBackend(userCred.user!, 'google');
        if (syncSuccess) {
          state = const AsyncData(true);
          return true;
        } else {
          state = AsyncError("Server bilan sinxronlashda xatolik.", StackTrace.current);
          return false;
        }
      }
      state = AsyncError("Firebase'dan foydalanuvchi olinmadi", StackTrace.current);
      return false;
    } on FirebaseAuthException catch (e) {
      state = AsyncError(e.message ?? 'Firebase Auth xatosi', StackTrace.current);
      return false;
    } catch (e) {
      state = AsyncError("Bekor qilindi yoki tarmoq xatosi: $e", StackTrace.current);
      return false;
    }
  }

  Future<bool> deleteAccount() async {
    state = const AsyncLoading();
    try {
      await _apiClient.delete('/profile/me');
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.delete();
      }
      await logout();
      state = const AsyncData(true);
      return true;
    } catch (e) {
      state = AsyncError("Failed to delete account: $e", StackTrace.current);
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!kIsWeb) {
        // Chiqishda ham instance ishlatiladi
        await gsi.GoogleSignIn.instance.signOut();
      }
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    state = const AsyncData(false);
  }
}