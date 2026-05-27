import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import '../../../core/network/api_client.dart';

class Flashcard {
  Flashcard({required this.q, required this.a});
  final String q;
  final String a;

  factory Flashcard.fromMap(Map<String, dynamic> m) =>
      Flashcard(q: '${m['q'] ?? ''}', a: '${m['a'] ?? ''}');
}

class QuizSessionData {
  QuizSessionData({required this.id, required this.topic, required this.score, required this.total, required this.createdAt});
  final int id;
  final String topic;
  final int score;
  final int total;
  final String createdAt;

  factory QuizSessionData.fromMap(Map<String, dynamic> m) => QuizSessionData(
    id: m['id'] ?? 0,
    topic: m['topic'] ?? '',
    score: m['score'] ?? 0,
    total: m['total'] ?? 0,
    createdAt: m['created_at'] ?? '',
  );
}

class QuizState {
  const QuizState({
    this.cards = const [],
    this.history = const [],
    this.loading = false,
    this.error,
    this.grounded = false,
    this.topic,
    this.correct = 0,
    this.answered = 0,
  });

  final List<Flashcard> cards;
  final List<QuizSessionData> history;
  final bool loading;
  final String? error;
  final bool grounded;
  final String? topic;
  final int correct;
  final int answered;

  QuizState copyWith({
    List<Flashcard>? cards,
    List<QuizSessionData>? history,
    bool? loading,
    String? error,
    bool? grounded,
    String? topic,
    int? correct,
    int? answered,
  }) =>
      QuizState(
        cards: cards ?? this.cards,
        history: history ?? this.history,
        loading: loading ?? this.loading,
        error: error,
        grounded: grounded ?? this.grounded,
        topic: topic ?? this.topic,
        correct: correct ?? this.correct,
        answered: answered ?? this.answered,
      );
}

class QuizNotifier extends StateNotifier<QuizState> {
  QuizNotifier(this._api) : super(const QuizState()) {
    loadHistory();
  }
  final ApiClient _api;

  Future<void> loadHistory() async {
    try {
      final res = await _api.get('/quiz/history');
      final list = (res['history'] as List?) ?? [];
      final history = list.map((e) => QuizSessionData.fromMap(Map<String, dynamic>.from(e))).toList();
      state = state.copyWith(history: history);
    } catch (_) {}
  }

  Future<void> generate(String topic, {String difficulty = 'medium', int count = 5}) async {
    final trimmed = topic.trim();
    if (trimmed.isEmpty) {
      state = state.copyWith(loading: false, error: "Please enter a topic.");
      return;
    }

    state = state.copyWith(loading: true, error: null, topic: trimmed, correct: 0, answered: 0, cards: const []);
    try {
      String contextText = "";
      try {
        final ragRes = await _api.post('/knowledge/retrieve', {"query": trimmed, "limit": 6});
        final chunks = (ragRes['chunks'] as List?) ?? [];
        for (final c in chunks) {
          final cm = Map<String, dynamic>.from(c);
          contextText += "${cm['content']}\n\n";
        }
      } catch (_) {}

      final prompt = contextText.isNotEmpty
          ? '''Based on the following MATERIAL, generate exactly $count flashcards on the topic: "$trimmed" (difficulty: $difficulty).
Each flashcard must have a question (q) and a clear, concise answer (a).
Return ONLY a JSON array of objects, no markdown, no commentary.
Format: [{"q":"...","a":"..."}]
MATERIAL:\n$contextText'''
          : '''Generate exactly $count flashcards on the topic: "$trimmed" (difficulty: $difficulty).
Each flashcard must have a question (q) and a clear, concise answer (a).
Return ONLY a JSON array of objects, no markdown, no commentary.
Format: [{"q":"...","a":"..."}]''';

      final model = FirebaseVertexAI.instance.generativeModel(
        model: 'gemini-2.5-flash',
        generationConfig: GenerationConfig(responseMimeType: 'application/json'),
      );
      final response = await model.generateContent([Content.text(prompt)]);
      final text = response.text ?? "";

      final parsed = _parseFlashcards(text);
      if (parsed.isEmpty) {
        state = state.copyWith(loading: false, error: "Couldn't generate flashcards for this topic. Try rephrasing it.");
        return;
      }

      state = state.copyWith(cards: parsed, loading: false, grounded: contextText.isNotEmpty);
    } catch (e) {
      state = state.copyWith(loading: false, error: "Generation failed: ${e.toString()}");
    }
  }

  List<Flashcard> _parseFlashcards(String text) {
    var s = text.trim().replaceAll('```json', '').replaceAll('```', '').trim();
    final startIdx = s.indexOf('[');
    final endIdx = s.lastIndexOf(']');
    if (startIdx == -1 || endIdx == -1 || endIdx <= startIdx) return const [];
    try {
      final decoded = jsonDecode(s.substring(startIdx, endIdx + 1)) as List;
      return decoded.whereType<Map>().map((e) => Flashcard.fromMap(Map<String, dynamic>.from(e)))
          .where((f) => f.q.isNotEmpty && f.a.isNotEmpty).toList();
    } catch (_) {
      return const [];
    }
  }

  void recordAnswer({required bool correct}) {
    state = state.copyWith(answered: state.answered + 1, correct: state.correct + (correct ? 1 : 0));
  }

  Future<void> saveScore() async {
    if (state.topic == null || state.answered == 0) return;
    try {
      await _api.post('/quiz/score', {"topic": state.topic, "score": state.correct, "total": state.answered});
      await loadHistory();
    } catch (_) {}
  }
}

final quizProvider = StateNotifierProvider<QuizNotifier, QuizState>((ref) => QuizNotifier(ref.watch(apiClientProvider)));