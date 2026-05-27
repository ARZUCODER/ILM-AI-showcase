import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import '../../../core/network/api_client.dart';
import '../../profile/logic/profile_provider.dart';

class PlanDay {
  PlanDay({required this.day, required this.title, required this.tasks});
  final int day;
  final String title;
  final List<String> tasks;

  factory PlanDay.fromMap(Map<String, dynamic> m) => PlanDay(
    day: m['day'] is int ? m['day'] : int.tryParse('${m['day']}') ?? 0,
    title: '${m['title'] ?? ''}',
    tasks: (m['tasks'] as List? ?? const []).map((e) => '$e').toList(),
  );
}

class PlannerState {
  const PlannerState({this.days = const [], this.loading = false, this.error, this.goal, this.totalDays});
  final List<PlanDay> days;
  final bool loading;
  final String? error;
  final String? goal;
  final int? totalDays;

  PlannerState copyWith({List<PlanDay>? days, bool? loading, String? error, String? goal, int? totalDays}) =>
      PlannerState(
        days: days ?? this.days,
        loading: loading ?? this.loading,
        error: error,
        goal: goal ?? this.goal,
        totalDays: totalDays ?? this.totalDays,
      );
}

class PlannerNotifier extends StateNotifier<PlannerState> {
  PlannerNotifier(this._api, this._ref) : super(const PlannerState());
  final ApiClient _api;
  final Ref _ref;

  Future<void> generate({String? goal, int? days}) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final profile = _ref.read(profileProvider).profile;
      final targetGoal = goal ?? profile?.learningGoal ?? "";
      final targetDays = days ?? profile?.daysLeft ?? 14;

      if (targetGoal.isEmpty) {
        state = state.copyWith(loading: false, error: "Goal is required. Please set it in your profile.");
        return;
      }

      final filesRes = await _api.get('/knowledge/files');
      final filesList = (filesRes['files'] as List?) ?? [];
      final materials = filesList.map((f) => f['filename'].toString()).join(", ");
      final materialText = materials.isEmpty ? "No materials uploaded." : materials;

      final model = FirebaseVertexAI.instance.generativeModel(model: 'gemini-2.5-flash');
      final prompt = '''You are an AI study planner. Build a practical day-by-day learning plan.
Goal: $targetGoal
Duration: $targetDays days
User's uploaded materials: $materialText

Return ONLY a JSON array of days. Each day format: { "day": 1, "title": "...", "tasks": ["...", "..."] }
''';

      final response = await model.generateContent([Content.text(prompt)]);
      final text = response.text ?? "";

      final startIdx = text.indexOf('[');
      final endIdx = text.lastIndexOf(']');

      if (startIdx != -1 && endIdx != -1 && endIdx > startIdx) {
        final jsonStr = text.substring(startIdx, endIdx + 1);
        final decoded = jsonDecode(jsonStr) as List;
        final parsed = decoded.map((e) => PlanDay.fromMap(Map<String, dynamic>.from(e))).toList();
        state = PlannerState(
          days: parsed,
          loading: false,
          goal: targetGoal,
          totalDays: targetDays,
        );
      } else {
        state = state.copyWith(loading: false, error: "Failed to parse AI response.");
      }
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }
}

final plannerProvider = StateNotifierProvider<PlannerNotifier, PlannerState>(
      (ref) => PlannerNotifier(ref.watch(apiClientProvider), ref),
);