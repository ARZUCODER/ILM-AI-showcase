import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../core/l10n/app_l10n.dart';
import '../../../core/theme/liq_colors.dart';
import '../../../core/ui/aurora_background.dart';
import '../../../core/ui/glass_card.dart';
import '../logic/chat_provider.dart';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _send() {
    final text = _input.text;
    if (text.trim().isEmpty) return;
    ref.read(chatProvider.notifier).send(text);
    _input.clear();
  }

  void _confirmClearChat() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: LiqColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Yangi chat boshlash", style: GoogleFonts.poppins(color: Colors.white)),
        content: Text("Barcha oldingi xabarlar o'chib ketadi. Davom etamizmi?", style: GoogleFonts.inter(color: LiqColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text("Bekor qilish", style: GoogleFonts.inter(color: LiqColors.textSecondary))),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(chatProvider.notifier).clearChat();
            },
            child: Text("Tozalash", style: GoogleFonts.inter(color: LiqColors.danger, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatProvider);

    return Scaffold(
      backgroundColor: LiqColors.bgDeep,
      resizeToAvoidBottomInset: true,
      body: AuroraBackground(
        palette: const [LiqColors.auroraGreen, LiqColors.auroraTeal, LiqColors.auroraViolet],
        child: SafeArea(
          child: Column(
            children: [
              _Header(onClear: _confirmClearChat),
              Expanded(
                child: ListView.builder(
                  reverse: true, // Xabarlar ro'yxati doim eng pastda turadi
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  itemCount: state.messages.length,
                  itemBuilder: (_, i) {
                    final reversedIndex = state.messages.length - 1 - i;
                    final m = state.messages[reversedIndex];

                    // MUHIM: ValueKey aralashib ketish xatosini to'liq oldini oladi
                    return _Bubble(key: ValueKey(m.id), message: m);
                  },
                ),
              ),
              _Composer(
                controller: _input,
                sending: state.sending,
                onSend: _send,
                l10n: ref.watch(l10nProvider).valueOrNull ?? AppL10n({}),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onClear});
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.canPop() ? context.pop() : null,
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: LiqColors.glassFill, borderRadius: BorderRadius.circular(12), border: Border.all(color: LiqColors.glassStroke)),
              child: const Icon(LucideIcons.chevron_left, color: LiqColors.textPrimary, size: 20),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: const LinearGradient(colors: [LiqColors.accentSoft, LiqColors.accent])),
                  child: const Icon(LucideIcons.sparkles, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("ILM AI", style: GoogleFonts.poppins(color: LiqColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
                    Row(
                      children: [
                        Container(width: 6, height: 6, decoration: const BoxDecoration(color: LiqColors.accent, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text("Online", style: GoogleFonts.inter(color: LiqColors.textTertiary, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClear,
            icon: const Icon(LucideIcons.trash_2, color: LiqColors.textSecondary, size: 20),
            tooltip: "Chatni tozalash",
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({super.key, required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final user = message.isUser;
    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: user ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (user) _UserBubble(text: message.text) else _AiBubble(message: message),
          ],
        ),
      ),
    );
  }
}

class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20), bottomLeft: Radius.circular(20), bottomRight: Radius.circular(6)),
        gradient: const LinearGradient(colors: [LiqColors.accentSoft, LiqColors.accent], begin: Alignment.topLeft, end: Alignment.bottomRight),
        boxShadow: [BoxShadow(color: LiqColors.accent.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Text(text, style: GoogleFonts.inter(color: Colors.white, fontSize: 15, height: 1.4)),
    );
  }
}

class _AiBubble extends StatefulWidget {
  const _AiBubble({required this.message});
  final ChatMessage message;

  @override
  State<_AiBubble> createState() => _AiBubbleState();
}

class _AiBubbleState extends State<_AiBubble> {
  late String _displayedText;
  Timer? _timer;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    // Faqatgina endigina kelgan (isNew = true) xabarlar uchun animatsiya o'ynaydi
    if (widget.message.isNew && !widget.message.thinking) {
      _isTyping = true;
      _displayedText = '';
      _startTyping();
    } else {
      _displayedText = widget.message.text;
    }
  }

  void _startTyping() {
    int index = 0;
    _timer = Timer.periodic(const Duration(milliseconds: 15), (t) {
      if (mounted) {
        setState(() {
          index += 6;
          if (index >= widget.message.text.length) {
            index = widget.message.text.length;
            _isTyping = false;
            _timer?.cancel();
          }
          _displayedText = widget.message.text.substring(0, index);
        });
      }
    });
  }

  void _skip() {
    if (_timer != null && _timer!.isActive) {
      _timer!.cancel();
    }
    if (mounted) {
      setState(() {
        _isTyping = false;
        _displayedText = widget.message.text;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.message.thinking) {
      return GlassCard(
        radius: 20,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 1.8, valueColor: AlwaysStoppedAnimation(LiqColors.accent))),
            const SizedBox(width: 10),
            Text("Thinking…", style: GoogleFonts.inter(color: LiqColors.textSecondary, fontSize: 13)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassCard(
          radius: 20,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MarkdownBody(
                data: _displayedText,
                selectable: true,
                styleSheet: MarkdownStyleSheet(
                  p: GoogleFonts.inter(color: LiqColors.textPrimary, fontSize: 15, height: 1.5),
                  strong: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700),
                  em: GoogleFonts.inter(color: LiqColors.textPrimary, fontStyle: FontStyle.italic),
                  h1: GoogleFonts.poppins(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
                  h2: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                  h3: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                  h4: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                  listBullet: GoogleFonts.inter(color: LiqColors.accentSoft, fontSize: 15, fontWeight: FontWeight.bold),
                  code: GoogleFonts.jetBrainsMono(color: LiqColors.accentSoft, backgroundColor: Colors.transparent, fontSize: 14),
                  codeblockPadding: const EdgeInsets.all(12),
                  codeblockDecoration: BoxDecoration(color: Colors.black.withOpacity(0.4), borderRadius: BorderRadius.circular(12), border: Border.all(color: LiqColors.glassStroke)),
                  blockquoteDecoration: BoxDecoration(border: const Border(left: BorderSide(color: LiqColors.accent, width: 4)), color: LiqColors.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                  blockquotePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  horizontalRuleDecoration: const BoxDecoration(border: Border(top: BorderSide(width: 1, color: LiqColors.glassStrokeStrong))),
                ),
              ),
              if (_isTyping)
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: _skip,
                    child: Container(
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: LiqColors.accent.withOpacity(0.2), borderRadius: BorderRadius.circular(12), border: Border.all(color: LiqColors.accent.withOpacity(0.4))),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("Tezkor ko'rish", style: GoogleFonts.inter(color: LiqColors.accentSoft, fontSize: 11, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 6),
                          const Icon(LucideIcons.fast_forward, color: LiqColors.accentSoft, size: 14),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (widget.message.citations.isNotEmpty && !_isTyping) ...[
          const SizedBox(height: 8),
          _Citations(citations: widget.message.citations).animate().fadeIn(duration: 400.ms),
        ],
      ],
    );
  }
}

class _Citations extends StatelessWidget {
  const _Citations({required this.citations});
  final List<Citation> citations;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 86,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: citations.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final c = citations[i];
          return GestureDetector(
            onTap: () => _showCitation(context, c, i + 1),
            child: Container(
              width: 220,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: LiqColors.glassFill, borderRadius: BorderRadius.circular(14), border: Border.all(color: LiqColors.glassStroke)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: LiqColors.accent.withOpacity(0.25), borderRadius: BorderRadius.circular(6)),
                        child: Text("[${i + 1}]", style: GoogleFonts.inter(color: LiqColors.accentSoft, fontSize: 10, fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(c.filename, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(color: LiqColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  Text(c.snippet, maxLines: 3, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(color: LiqColors.textTertiary, fontSize: 11, height: 1.3)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showCitation(BuildContext context, Citation c, int n) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
        decoration: const BoxDecoration(color: LiqColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).padding.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: LiqColors.accent.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                  child: Text("Citation [$n]", style: GoogleFonts.inter(color: LiqColors.accentSoft, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(c.filename, style: GoogleFonts.inter(color: LiqColors.textPrimary, fontWeight: FontWeight.w600))),
              ],
            ),
            const SizedBox(height: 16),
            Flexible(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: LiqColors.glassFill, borderRadius: BorderRadius.circular(14), border: Border.all(color: LiqColors.glassStroke)),
                child: SingleChildScrollView(child: Text(c.snippet, style: GoogleFonts.inter(color: LiqColors.textSecondary, fontSize: 14, height: 1.5))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({required this.controller, required this.sending, required this.onSend, required this.l10n});
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;
  final AppL10n l10n;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(12, 8, 12, 12 + MediaQuery.of(context).viewInsets.bottom),
      child: GlassCard(
        radius: 28,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                style: GoogleFonts.inter(color: LiqColors.textPrimary, fontSize: 15),
                maxLines: 4,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: l10n.t('type_message'),
                  hintStyle: GoogleFonts.inter(color: LiqColors.textMuted, fontSize: 15),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ),
            GestureDetector(
              onTap: sending ? null : onSend,
              child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: const LinearGradient(colors: [LiqColors.accentSoft, LiqColors.accent]),
                  boxShadow: [BoxShadow(color: LiqColors.accent.withOpacity(0.4), blurRadius: 14, offset: const Offset(0, 4))],
                ),
                child: sending
                    ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                    : const Icon(LucideIcons.send, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}