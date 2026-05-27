import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

class ProfileData {
  ProfileData({
    required this.email,
    required this.name,
    required this.authProvider,
    this.learningGoal,
    this.targetDate,
    this.daysLeft,
    this.pictureUrl,
    this.tier,
    this.isTgLinked = false,
  });

  final String email;
  final String name;
  final String authProvider;
  final String? learningGoal;
  final String? targetDate;
  final int? daysLeft;
  final String? pictureUrl;
  final String? tier;
  final bool isTgLinked;

  factory ProfileData.fromMap(Map<String, dynamic> m) => ProfileData(
    email: '${m['email'] ?? ''}',
    name: '${m['name'] ?? ''}',
    authProvider: '${m['auth_provider'] ?? ''}',
    learningGoal: m['learning_goal']?.toString(),
    targetDate: m['target_date']?.toString(),
    daysLeft: m['days_left'] is int ? m['days_left'] : null,
    pictureUrl: m['picture_url']?.toString(),
    tier: m['tier']?.toString() ?? 'free',
    isTgLinked: m['tg_linked'] == true,
  );
}

class ProfileStats {
  const ProfileStats({
    this.files = 0,
    this.chunks = 0,
    this.chatMessages = 0,
    this.quizSessions = 0,
    this.questionsDone = 0,
    this.accuracy = 0,
  });

  final int files;
  final int chunks;
  final int chatMessages;
  final int quizSessions;
  final int questionsDone;
  final double accuracy;

  factory ProfileStats.fromMap(Map<String, dynamic> m) => ProfileStats(
    files: (m['files'] ?? 0) as int,
    chunks: (m['chunks'] ?? 0) as int,
    chatMessages: (m['chat_messages'] ?? 0) as int,
    quizSessions: (m['quiz_sessions'] ?? 0) as int,
    questionsDone: (m['questions_done'] ?? 0) as int,
    accuracy: (m['accuracy'] is num) ? (m['accuracy'] as num).toDouble() : 0,
  );
}

class ProfileState {
  const ProfileState({
    this.profile,
    this.stats = const ProfileStats(),
    this.loading = true,
    this.error,
    this.tgCode,
  });

  final ProfileData? profile;
  final ProfileStats stats;
  final bool loading;
  final String? error;
  final String? tgCode;

  ProfileState copyWith({ProfileData? profile, ProfileStats? stats, bool? loading, String? error, String? tgCode}) =>
      ProfileState(
        profile: profile ?? this.profile,
        stats: stats ?? this.stats,
        loading: loading ?? this.loading,
        error: error,
        tgCode: tgCode ?? this.tgCode,
      );
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier(this._api) : super(const ProfileState()) {
    refresh();
  }

  final ApiClient _api;
  Timer? _pollingTimer;

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> refresh() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final me = await _api.get('/profile/me');
      final st = await _api.get('/profile/stats');
      state = ProfileState(
        profile: ProfileData.fromMap(Map<String, dynamic>.from(me)),
        stats: ProfileStats.fromMap(Map<String, dynamic>.from(st)),
        loading: false,
        tgCode: state.tgCode,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<bool> saveGoal({required String goal, required DateTime targetDate}) async {
    try {
      final iso = '${targetDate.year.toString().padLeft(4, '0')}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}';
      await _api.put('/profile/goal', {"goal": goal, "target_date": iso});
      await refresh();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> generateTgCode() async {
    try {
      state = state.copyWith(error: null);
      final res = await _api.post('/profile/tg-code', {});
      state = state.copyWith(tgCode: res['code']);

      _pollingTimer?.cancel();
      _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
        await refresh();
        if (state.profile?.isTgLinked == true) {
          timer.cancel();
        }
      });

      Future.delayed(const Duration(minutes: 10), () {
        _pollingTimer?.cancel();
      });

    } catch (e) {
      state = state.copyWith(error: "Code Error: ${e.toString()}");
    }
  }

  Future<void> disconnectTg() async {
    try {
      await _api.post('/profile/tg-disconnect', {});
      state = state.copyWith(tgCode: null);
      _pollingTimer?.cancel();
      await refresh();
    } catch (_) {}
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>(
      (ref) => ProfileNotifier(ref.watch(apiClientProvider)),
);