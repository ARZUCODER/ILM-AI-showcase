import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../core/l10n/app_l10n.dart';
import '../../../core/theme/liq_colors.dart';
import '../../../core/ui/aurora_background.dart';
import '../../../core/ui/glass_card.dart';
import '../logic/quiz_provider.dart';

class FlashcardsPage extends ConsumerStatefulWidget {
  const FlashcardsPage({super.key});

  @override
  ConsumerState<FlashcardsPage> createState() => _FlashcardsPageState();
}

class _FlashcardsPageState extends ConsumerState<FlashcardsPage> {
  final _topic = TextEditingController();
  int _index = 0;
  bool _flipped = false;
  String _difficulty = 'medium';

  @override
  void dispose() {
    _topic.dispose();
    super.dispose();
  }

  void _start() {
    final t = _topic.text.trim();
    if (t.isEmpty) return;
    setState(() {
      _index = 0;
      _flipped = false;
    });
    ref.read(quizProvider.notifier).generate(t, difficulty: _difficulty, count: 5);
  }

  void _next({required bool correct}) async {
    ref.read(quizProvider.notifier).recordAnswer(correct: correct);
    final cards = ref.read(quizProvider).cards;
    if (_index + 1 < cards.length) {
      setState(() {
        _index++;
        _flipped = false;
      });
    } else {
      await ref.read(quizProvider.notifier).saveScore();
      if (mounted) setState(() => _index = cards.length);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(quizProvider);
    final l10n = ref.watch(l10nProvider).valueOrNull ?? AppL10n({});

    return Scaffold(
      backgroundColor: LiqColors.bgDeep,
      body: AuroraBackground(
        palette: const [LiqColors.auroraTeal, LiqColors.auroraViolet, LiqColors.auroraPink],
        child: SafeArea(
          child: Column(
            children: [
              _Header(l10n: l10n),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: _body(s, l10n),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(QuizState s, AppL10n l10n) {
    if (s.loading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: LiqColors.accent),
            const SizedBox(height: 18),
            Text(
              l10n.t('thinking'),
              style: GoogleFonts.inter(color: LiqColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (s.cards.isEmpty) {
      return _SetupCard(
        topic: _topic,
        difficulty: _difficulty,
        onDifficulty: (d) => setState(() => _difficulty = d),
        onStart: _start,
        error: s.error,
        l10n: l10n,
        history: s.history,
      );
    }

    if (_index >= s.cards.length) {
      return _Result(
          state: s,
          l10n: l10n,
          onRestart: () => setState(() {
            _index = 0;
            _flipped = false;
            ref.read(quizProvider.notifier).generate(s.topic ?? "", difficulty: _difficulty);
          }));
    }

    final card = s.cards[_index];
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Card ${_index + 1} / ${s.cards.length}",
              style: GoogleFonts.inter(color: LiqColors.textTertiary, fontSize: 12),
            ),
            if (s.grounded)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: LiqColors.accent.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.book_open, color: LiqColors.accentSoft, size: 12),
                    const SizedBox(width: 6),
                    Text(
                      l10n.t('tab_library'),
                      style: GoogleFonts.inter(
                        color: LiqColors.accentSoft,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: (_index + 1) / s.cards.length,
          backgroundColor: LiqColors.glassFill,
          color: LiqColors.accent,
          borderRadius: BorderRadius.circular(4),
          minHeight: 6,
        ),
        const SizedBox(height: 24),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _flipped = !_flipped),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOutCubic,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: ScaleTransition(scale: Tween(begin: 0.92, end: 1.0).animate(anim), child: child),
              ),
              child: _Flip(
                key: ValueKey('$_index-$_flipped'),
                flipped: _flipped,
                front: card.q,
                back: card.a,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (_flipped)
          Row(
            children: [
              Expanded(
                child: GhostButton(
                  label: l10n.t('incorrect_btn'),
                  icon: LucideIcons.x,
                  onPressed: () => _next(correct: false),
                  height: 56,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: LiqButton(
                  label: l10n.t('correct_btn'),
                  icon: LucideIcons.check,
                  onPressed: () => _next(correct: true),
                  height: 56,
                ),
              ),
            ],
          )
        else
          Row(
            children: [
              Expanded(
                child: LiqButton(
                  label: l10n.t('show_answer'),
                  icon: LucideIcons.eye,
                  onPressed: () => setState(() => _flipped = true),
                  height: 56,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.l10n});
  final AppL10n l10n;

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
              decoration: BoxDecoration(
                color: LiqColors.glassFill,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: LiqColors.glassStroke),
              ),
              child: const Icon(LucideIcons.chevron_left, color: LiqColors.textPrimary, size: 20),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            l10n.t('flashcards_title'),
            style: GoogleFonts.poppins(
              color: LiqColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SetupCard extends StatelessWidget {
  const _SetupCard({
    required this.topic,
    required this.difficulty,
    required this.onDifficulty,
    required this.onStart,
    required this.error,
    required this.l10n,
    required this.history,
  });
  final TextEditingController topic;
  final String difficulty;
  final ValueChanged<String> onDifficulty;
  final VoidCallback onStart;
  final String? error;
  final AppL10n l10n;
  final List<QuizSessionData> history;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          GlassCard(
            glow: true,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.t('practice_topic'), style: GoogleFonts.poppins(color: LiqColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 20)),
                const SizedBox(height: 6),
                Text(l10n.t('ai_will_generate'), style: GoogleFonts.inter(color: LiqColors.textTertiary, fontSize: 13)),
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(color: LiqColors.glassFill, borderRadius: BorderRadius.circular(16), border: Border.all(color: LiqColors.glassStroke)),
                  child: TextField(
                    controller: topic, style: GoogleFonts.inter(color: LiqColors.textPrimary, fontSize: 16),
                    decoration: InputDecoration(hintText: l10n.t('topic_hint'), hintStyle: GoogleFonts.inter(color: LiqColors.textMuted), border: InputBorder.none, contentPadding: const EdgeInsets.all(16)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _diffChip('gentle', l10n.t('gentle'), difficulty, onDifficulty)),
                    const SizedBox(width: 8),
                    Expanded(child: _diffChip('medium', l10n.t('solid'), difficulty, onDifficulty)),
                    const SizedBox(width: 8),
                    Expanded(child: _diffChip('expert', l10n.t('expert'), difficulty, onDifficulty)),
                  ],
                ),
                const SizedBox(height: 24),
                LiqButton(label: l10n.t('start_session'), icon: LucideIcons.play, onPressed: onStart),
                if (error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: LiqColors.danger.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: LiqColors.danger.withOpacity(0.3))),
                    child: Row(children: [const Icon(LucideIcons.circle_alert, color: LiqColors.danger, size: 16), const SizedBox(width: 8), Expanded(child: Text(error!, style: GoogleFonts.inter(color: LiqColors.danger, fontSize: 12)))]),
                  ),
                ],
              ],
            ),
          ),
          if (history.isNotEmpty) ...[
            const SizedBox(height: 32),
            Row(
              children: [
                const Icon(LucideIcons.history, color: LiqColors.textSecondary, size: 18),
                const SizedBox(width: 8),
                Text("Sessiyalar tarixi", style: GoogleFonts.poppins(color: LiqColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < history.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 32, height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: LiqColors.glassFill, borderRadius: BorderRadius.circular(10)),
                        child: Text("#${i + 1}", style: GoogleFonts.poppins(color: LiqColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(history[i].topic, style: GoogleFonts.inter(color: LiqColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text(history[i].createdAt.substring(0, 10), style: GoogleFonts.inter(color: LiqColors.textTertiary, fontSize: 11)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: (history[i].score / history[i].total) >= 0.7 ? LiqColors.success.withOpacity(0.15) : LiqColors.auroraAmber.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "${history[i].score}/${history[i].total}",
                          style: GoogleFonts.inter(
                            color: (history[i].score / history[i].total) >= 0.7 ? LiqColors.success : LiqColors.auroraAmber,
                            fontWeight: FontWeight.w700, fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ]
        ],
      ),
    );
  }

  Widget _diffChip(String value, String label, String current, ValueChanged<String> onSel) {
    final active = current == value;
    return GestureDetector(
      onTap: () => onSel(value),
      child: Container(
        alignment: Alignment.center, padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), gradient: active ? const LinearGradient(colors: [LiqColors.accentSoft, LiqColors.accent]) : null, color: active ? null : LiqColors.glassFill, border: Border.all(color: active ? Colors.transparent : LiqColors.glassStroke)),
        child: Text(label, style: GoogleFonts.inter(color: active ? Colors.white : LiqColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 13)),
      ),
    );
  }
}

class _Flip extends ConsumerWidget {
  const _Flip({super.key, required this.flipped, required this.front, required this.back});
  final bool flipped;
  final String front;
  final String back;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(l10nProvider).valueOrNull ?? AppL10n({});
    final text = flipped ? back : front;
    return GlassCard(
      tint: flipped ? LiqColors.accent.withOpacity(0.08) : LiqColors.glassFillStrong,
      strokeColor: flipped ? LiqColors.accent.withOpacity(0.4) : LiqColors.glassStrokeStrong,
      glow: true,
      radius: 32,
      padding: const EdgeInsets.all(32),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              flipped ? l10n.t('answer') : l10n.t('question'),
              style: GoogleFonts.inter(
                color: flipped ? LiqColors.accentSoft : LiqColors.textTertiary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: LiqColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.touchpad, color: LiqColors.textTertiary, size: 16),
                const SizedBox(width: 8),
                Text(
                  flipped ? l10n.t('tap_to_see_q') : l10n.t('tap_to_flip'),
                  style: GoogleFonts.inter(color: LiqColors.textTertiary, fontSize: 13),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Result extends StatelessWidget {
  const _Result({required this.state, required this.onRestart, required this.l10n});
  final QuizState state;
  final VoidCallback onRestart;
  final AppL10n l10n;

  @override
  Widget build(BuildContext context) {
    final pct = state.answered == 0 ? 0 : (state.correct * 100 / state.answered).round();
    return Center(
      child: GlassCard(
        glow: true,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [LiqColors.accentSoft, LiqColors.accent]),
                boxShadow: [
                  BoxShadow(
                    color: LiqColors.accent.withOpacity(0.4),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: const Icon(LucideIcons.trophy, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.t('session_complete'),
              style: GoogleFonts.poppins(
                color: LiqColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.tr('correct_out_of', {
                'correct': '${state.correct}',
                'total': '${state.answered}',
                'pct': '$pct',
              }),
              style: GoogleFonts.inter(color: LiqColors.textSecondary, fontSize: 15),
            ),
            const SizedBox(height: 32),
            LiqButton(label: l10n.t('practice_again'), icon: LucideIcons.refresh_cw, onPressed: onRestart),
            const SizedBox(height: 16),
            GhostButton(
              label: l10n.t('back_to_library'),
              icon: LucideIcons.library,
              onPressed: () => context.canPop() ? context.pop() : null,
              height: 56,
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }
}