import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_client.dart';

class PremiumState {
  const PremiumState({
    this.loading = false,
    this.success = false,
    this.error,
    this.tier = 'free',
    this.message,
  });

  final bool loading;
  final bool success;
  final String? error;
  final String tier;
  final String? message;

  bool get isPremium => tier == 'premium';

  PremiumState copyWith({
    bool? loading,
    bool? success,
    String? error,
    String? tier,
    String? message,
  }) =>
      PremiumState(
        loading: loading ?? this.loading,
        success: success ?? this.success,
        error: error,
        tier: tier ?? this.tier,
        message: message,
      );
}

class PremiumNotifier extends StateNotifier<PremiumState> {
  PremiumNotifier(this._api) : super(const PremiumState()) {
    _loadCachedTier();
  }
  final ApiClient _api;

  Future<void> _loadCachedTier() async {
    final prefs = await SharedPreferences.getInstance();
    final tier = prefs.getString('tier') ?? 'free';
    state = state.copyWith(tier: tier);
  }

  Future<bool> applyPromoCode(String code) async {
    final trimmed = code.trim();
    if (trimmed.isEmpty) {
      state = state.copyWith(error: 'Please enter a promo code.', success: false);
      return false;
    }

    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    if (email.isEmpty) {
      state = state.copyWith(error: 'You must be signed in.', success: false);
      return false;
    }

    state = state.copyWith(loading: true, error: null, success: false, message: null);
    try {
      final res = await _api.post('/premium/validate-promo', {
        'email': email,
        'code': trimmed,
      });
      final tier = (res['tier'] ?? 'premium').toString();
      final message = res['message']?.toString();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('tier', tier);

      state = state.copyWith(
        loading: false,
        success: true,
        tier: tier,
        message: message ?? 'Premium unlocked!',
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(loading: false, success: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(loading: false, success: false, error: e.toString());
      return false;
    }
  }

  // To'lov linkini (Click yoki Payme) olish
  Future<String?> generatePaymentUrl(String provider, int amount) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final res = await _api.post('/premium/pay', {
        "provider": provider,
        "amount": amount,
      });
      state = state.copyWith(loading: false);
      return res['url'] as String?;
    } catch (e) {
      state = state.copyWith(loading: false, error: "To'lov tizimiga ulanishda xatolik yuz berdi");
      return null;
    }
  }

  Future<void> refreshStatus() async {
    try {
      final res = await _api.get('/premium/status');
      final tier = (res['tier'] ?? 'free').toString();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('tier', tier);
      state = state.copyWith(tier: tier);
    } catch (_) {}
  }
}

final premiumProvider = StateNotifierProvider<PremiumNotifier, PremiumState>((ref) {
  return PremiumNotifier(ref.watch(apiClientProvider));
});