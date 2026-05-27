import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_client.dart';

class AdminState {
  AdminState({
    this.totalUsers = 0,
    this.totalChunks = 0,
    this.totalChats = 0,
    this.totalTokens = 0,
    this.users = const [],
    this.chats = const [],
    this.promos = const [],
    this.loading = false,
    this.error,
  });

  final int totalUsers;
  final int totalChunks;
  final int totalChats;
  final int totalTokens;
  final List<dynamic> users;
  final List<dynamic> chats;
  final List<dynamic> promos;
  final bool loading;
  final String? error;

  AdminState copyWith({
    int? totalUsers,
    int? totalChunks,
    int? totalChats,
    int? totalTokens,
    List<dynamic>? users,
    List<dynamic>? chats,
    List<dynamic>? promos,
    bool? loading,
    String? error,
  }) {
    return AdminState(
      totalUsers: totalUsers ?? this.totalUsers,
      totalChunks: totalChunks ?? this.totalChunks,
      totalChats: totalChats ?? this.totalChats,
      totalTokens: totalTokens ?? this.totalTokens,
      users: users ?? this.users,
      chats: chats ?? this.chats,
      promos: promos ?? this.promos,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

class AdminNotifier extends StateNotifier<AdminState> {
  AdminNotifier(this._api) : super(AdminState());
  final ApiClient _api;

  Future<bool> login(String email, String password) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final res = await _api.post('/admin/login', {"email": email, "password": password});
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', res['token']);
      await prefs.setString('role', res['role']);
      state = state.copyWith(loading: false);
      return true;
    } catch (e) {
      state = state.copyWith(loading: false, error: "Invalid admin credentials");
      return false;
    }
  }

  Future<void> fetchDashboard() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final stats = await _api.get('/admin/dashboard');
      final usersRes = await _api.get('/admin/users');
      final chatsRes = await _api.get('/admin/chats');
      final promosRes = await _api.get('/admin/promo/list'); // Promokodlar tortib olinadi

      state = state.copyWith(
        loading: false,
        totalUsers: stats['total_users'] ?? 0,
        totalChunks: stats['total_chunks'] ?? 0,
        totalChats: stats['total_chats'] ?? 0,
        totalTokens: stats['total_tokens'] ?? 0,
        users: usersRes['users'] ?? [],
        chats: chatsRes['chats'] ?? [],
        promos: promosRes['codes'] ?? [],
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<bool> createPromo(Map<String, dynamic> data) async {
    try {
      await _api.post('/admin/promo/create', data);
      await fetchDashboard();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<void> togglePromo(String code, bool isActive) async {
    try {
      await _api.put('/admin/promo/$code?active=$isActive', {});
      await fetchDashboard();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final adminProvider = StateNotifierProvider<AdminNotifier, AdminState>((ref) {
  return AdminNotifier(ref.watch(apiClientProvider));
});