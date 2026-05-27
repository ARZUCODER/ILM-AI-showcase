import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import '../../../core/network/api_client.dart';
import '../../../core/l10n/app_l10n.dart'; // Tilni bilish uchun qo'shildi

class Citation {
  Citation({required this.id, required this.filename, required this.snippet});
  final int id;
  final String filename;
  final String snippet;

  factory Citation.fromMap(Map<String, dynamic> m) => Citation(
    id: m['id'] is int ? m['id'] : int.tryParse('${m['id']}') ?? 0,
    filename: '${m['filename'] ?? 'document'}',
    snippet: '${m['content'] ?? m['snippet'] ?? ''}',
  );
}

class ChatMessage {
  ChatMessage({
    required this.id,
    required this.isUser,
    required this.text,
    this.citations = const [],
    this.thinking = false,
    this.isNew = false,
  });

  final String id;
  final bool isUser;
  final String text;
  final List<Citation> citations;
  final bool thinking;
  final bool isNew;
}

class ChatState {
  ChatState({this.messages = const [], this.loading = false, this.sending = false, this.error});
  final List<ChatMessage> messages;
  final bool loading;
  final bool sending;
  final String? error;

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? loading,
    bool? sending,
    String? error,
  }) =>
      ChatState(
        messages: messages ?? this.messages,
        loading: loading ?? this.loading,
        sending: sending ?? this.sending,
        error: error,
      );
}

class ChatNotifier extends StateNotifier<ChatState> {
  // Konstruktor endi joriy tilni ham qabul qiladi
  ChatNotifier(this._api, this._locale) : super(ChatState(loading: true)) {
    _initModel();
    _loadHistory();
  }

  final ApiClient _api;
  final String _locale;
  late final GenerativeModel _model;
  late ChatSession _chatSession;

  // Joriy tilga qarab xush kelibsiz xabarini tanlash
  String get _welcomeMsg {
    if (_locale == 'ru') {
      return "Привет! Я ваш ИИ-наставник. Загрузите документ или задайте любой вопрос.";
    } else if (_locale == 'en') {
      return "Hello! I am your AI tutor. Upload a document or ask any question.";
    }
    return "Salom! Men sizning AI ustozingizman. Hujjat yuklang yoki istalgan savolingizni bering.";
  }

  // Yangi chat ochilgandagi xabar
  String get _newChatMsg {
    if (_locale == 'ru') {
      return "Новый чат начат! Чем могу помочь?";
    } else if (_locale == 'en') {
      return "New chat started! How can I help you?";
    }
    return "Yangi chat boshlandi! Sizga qanday yordam bera olaman?";
  }

  void _initModel() {
    // AI ga joriy interfeys qaysi tilda ekanligini aytib o'tamiz
    String aiLang = _locale == 'uz' ? "O'zbek" : _locale == 'ru' ? "Rus" : "Ingliz";

    _model = FirebaseVertexAI.instance.generativeModel(
      model: 'gemini-2.5-flash',
      systemInstruction: Content.system(
          '''Sizning ismingiz "ILM AI" - aqlli, qisqa va aniq javob beradigan o'quv yordamchisisiz.
        
Joriy interfeys tili: $aiLang tili.

QOIDALAR:
1. Asosan joriy interfeys tilida javob bering. Agar foydalanuvchi boshqa tilda murojaat qilsagina, o'sha tilga o'tishingiz mumkin.
2. Javoblaringiz qisqa va aniq bo'lsin.
3. Agar sizga taqdim etilgan hujjatlarda (context) aniq javob mavjud bo'lsa, o'sha ma'lumotdan foydalaning va qaysi manbadan olinganini matn ichida [1], [2] shaklida ko'rsating.
4. MUHIM: Agar hujjatlarda umuman javob bo'lmasa, o'zingizning bilimlaringizdan foydalaning, LEKIN hech qanday [1], [2] manba belgilarini ishlata ko'rmang. Hujjatda yo'q narsaga iqtibos (citation) ishlatish qat'iyan man etiladi!
5. Chiroyli Markdown formatida yozing.'''
      ),
    );
    _chatSession = _model.startChat();
  }

  Future<void> _loadHistory() async {
    try {
      final res = await _api.get('/chat/history');
      final history = (res['history'] as List?) ?? [];
      var msgs = history.map<ChatMessage>((e) {
        final m = Map<String, dynamic>.from(e);
        final cits = (m['citations'] as List?)
            ?.map((c) => Citation.fromMap(Map<String, dynamic>.from(c)))
            .toList() ??
            const [];
        return ChatMessage(
          id: m['id'].toString(),
          isUser: m['isUser'] == true,
          text: '${m['text']}',
          citations: cits,
          isNew: false,
        );
      }).toList();

      // Agar tarix bo'sh bo'lsa yoki Backenddan eski O'zbekcha yozuv kelib qolsa,
      // biz uni darhol joriy tilga moslashtiramiz:
      if (msgs.isEmpty || (msgs.length == 1 && msgs.first.id == '0' && !msgs.first.isUser)) {
        msgs = [
          ChatMessage(id: 'welcome', isUser: false, text: _welcomeMsg, isNew: false)
        ];
      }

      state = ChatState(messages: msgs);
    } catch (e) {
      state = ChatState(messages: [
        ChatMessage(id: 'welcome', isUser: false, text: _welcomeMsg)
      ]);
    }
  }

  Future<void> clearChat() async {
    state = ChatState(messages: [
      ChatMessage(id: 'welcome_new', isUser: false, text: _newChatMsg)
    ]);
    try {
      await _api.delete('/chat/history');
      _chatSession = _model.startChat();
    } catch (_) {}
  }

  Future<void> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.sending) return;

    final userMsgId = DateTime.now().millisecondsSinceEpoch.toString();
    final updated = [
      ...state.messages,
      ChatMessage(id: userMsgId, isUser: true, text: trimmed),
      ChatMessage(id: 'thinking', isUser: false, text: "", thinking: true),
    ];
    state = state.copyWith(messages: updated, sending: true);

    try {
      await _api.post('/chat/message', {"is_user": true, "message": trimmed, "total_tokens": 0});

      final ragRes = await _api.post('/knowledge/retrieve', {"query": trimmed, "limit": 3});
      final chunks = (ragRes['chunks'] as List?) ?? [];

      String contextText = "";
      List<Citation> cits = [];

      if (chunks.isNotEmpty) {
        contextText += "--- YUKLANGAN HUJJATDAN MA'LUMOTLAR ---\n";
        for (int i = 0; i < chunks.length; i++) {
          final c = Map<String, dynamic>.from(chunks[i]);
          contextText += "[${i + 1}] (Manba: ${c['filename']}):\n${c['content']}\n\n";
          cits.add(Citation.fromMap(c));
        }
        contextText += "---------------------------------------\n";
      }

      final promptText = contextText.isNotEmpty ? "$contextText\nFoydalanuvchi savoli: $trimmed" : trimmed;

      final response = await _chatSession.sendMessage(Content.text(promptText));
      final replyText = response.text ?? "Men javob topa olmadim.";
      final totalTokens = response.usageMetadata?.totalTokenCount ?? 0;

      List<Citation> actualCitations = [];
      for (int i = 0; i < cits.length; i++) {
        if (replyText.contains('[${i + 1}]')) {
          actualCitations.add(cits[i]);
        }
      }

      final saveRes = await _api.post('/chat/message', {
        "is_user": false,
        "message": replyText,
        "citations": actualCitations.map((c) => {"filename": c.filename, "content": c.snippet}).toList(),
        "rag_info": {"query": trimmed, "matches": chunks},
        "total_tokens": totalTokens
      });

      final aiMsgId = saveRes['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();

      final without = state.messages.where((m) => !m.thinking).toList();
      state = state.copyWith(
        messages: [
          ...without,
          ChatMessage(id: aiMsgId, isUser: false, text: replyText, citations: actualCitations, isNew: true),
        ],
        sending: false,
      );
    } catch (e) {
      final without = state.messages.where((m) => !m.thinking).toList();
      state = state.copyWith(
        messages: [
          ...without,
          ChatMessage(id: 'error', isUser: false, text: "Kechirasiz, tarmoqda xatolik yuz berdi. Iltimos qaytadan urinib ko'ring."),
        ],
        sending: false,
      );
    }
  }
}

// Provider endi localeProvider'ni ham eshitadi. Til o'zgarsa ChatProvider ham yangilanadi!
final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final locale = ref.watch(localeProvider);
  return ChatNotifier(apiClient, locale);
});