import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../core/l10n/app_l10n.dart';
import '../../../core/theme/liq_colors.dart';
import '../../../core/ui/glass_card.dart';
import '../../profile/logic/profile_provider.dart';
import '../logic/planner_provider.dart';

class PlanPage extends ConsumerWidget {
  const PlanPage({super.key});

  Future<void> _openGoalSheet(BuildContext context, WidgetRef ref, AppL10n l10n) async {
    final state = ref.read(profileProvider);
    final goalCtrl = TextEditingController(text: state.profile?.learningGoal ?? "");
    DateTime selected = DateTime.tryParse(state.profile?.targetDate ?? "") ??
        DateTime.now().add(const Duration(days: 14));

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: LiqColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSt) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: LiqColors.glassStroke,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  l10n.t('set_learning_goal'),
                  style: GoogleFonts.poppins(color: LiqColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.t('study_plan_adapt'),
                  style: GoogleFonts.inter(color: LiqColors.textTertiary, fontSize: 13),
                ),
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    color: LiqColors.glassFill,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: LiqColors.glassStroke),
                  ),
                  child: TextField(
                    controller: goalCtrl,
                    style: GoogleFonts.inter(color: LiqColors.textPrimary, fontSize: 15),
                    maxLines: 3,
                    minLines: 1,
                    decoration: InputDecoration(
                      hintText: l10n.t('goal_hint'),
                      hintStyle: GoogleFonts.inter(color: LiqColors.textMuted),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: selected,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                      builder: (context, child) => Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: LiqColors.accent,
                            onPrimary: Colors.white,
                            surface: LiqColors.surface,
                            onSurface: LiqColors.textPrimary,
                          ),
                          dialogTheme: const DialogThemeData(backgroundColor: LiqColors.surface),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) setSt(() => selected = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: LiqColors.glassFill,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: LiqColors.glassStroke),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.calendar_range, color: LiqColors.textSecondary, size: 18),
                        const SizedBox(width: 12),
                        Text(
                          l10n.t('target_deadline'),
                          style: GoogleFonts.inter(color: LiqColors.textSecondary, fontSize: 14),
                        ),
                        const Spacer(),
                        Text(
                          "${selected.year}-${selected.month.toString().padLeft(2, '0')}-${selected.day.toString().padLeft(2, '0')}",
                          style: GoogleFonts.inter(color: LiqColors.textPrimary, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                LiqButton(
                  label: l10n.t('save_goal'),
                  icon: LucideIcons.check,
                  onPressed: () async {
                    final ok = await ref.read(profileProvider.notifier).saveGoal(
                      goal: goalCtrl.text.trim(),
                      targetDate: selected,
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (ok && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: LiqColors.surfaceElevated,
                          behavior: SnackBarBehavior.floating,
                          content: Text(l10n.t('goal_saved'), style: GoogleFonts.inter(color: LiqColors.textPrimary)),
                        ),
                      );
                      // Maqsad yangilangach planni ham qayta tiklash qulay bo'ladi
                      ref.read(plannerProvider.notifier).generate();
                    }
                  },
                ),
              ],
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final planner = ref.watch(plannerProvider);
    final l10n = ref.watch(l10nProvider).valueOrNull ?? AppL10n({});

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 140),
      children: [
        _Header(
          daysLeft: profile.profile?.daysLeft,
          goal: profile.profile?.learningGoal,
          l10n: l10n,
          onEditGoal: () => _openGoalSheet(context, ref, l10n),
        ),
        const SizedBox(height: 22),
        if ((profile.profile?.learningGoal ?? "").isEmpty)
          _NoGoalCard(l10n: l10n, onSetGoal: () => _openGoalSheet(context, ref, l10n))
        else ...[
          Row(
            children: [
              Text(
                l10n.t('day_by_day_plan'),
                style: GoogleFonts.poppins(
                  color: LiqColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: planner.loading
                    ? null
                    : () => ref.read(plannerProvider.notifier).generate(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: LiqColors.glassFill,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: LiqColors.glassStroke),
                  ),
                  child: Row(
                    children: [
                      planner.loading
                          ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 1.6, valueColor: AlwaysStoppedAnimation(LiqColors.accent)),
                      )
                          : const Icon(LucideIcons.sparkles, color: LiqColors.accentSoft, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        planner.days.isEmpty ? l10n.t('generate_plan') : l10n.t('regenerate'),
                        style: GoogleFonts.inter(color: LiqColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (planner.error != null)
            _ErrorCard(message: planner.error!),
          if (planner.days.isEmpty && !planner.loading && planner.error == null)
            _EmptyPlan(
              onTap: () => ref.read(plannerProvider.notifier).generate(),
              l10n: l10n,
            ),
          for (var i = 0; i < planner.days.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _DayCard(day: planner.days[i], index: i).animate(delay: (60 * i).ms).fadeIn().slideY(begin: 0.1),
            ),
        ],
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({this.daysLeft, this.goal, required this.l10n, required this.onEditGoal});
  final int? daysLeft;
  final String? goal;
  final AppL10n l10n;
  final VoidCallback onEditGoal;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.t('learning_plan'),
              style: GoogleFonts.poppins(
                color: LiqColors.textPrimary,
                fontSize: 32,
                fontWeight: FontWeight.w700,
                letterSpacing: -1,
              ),
            ),
            if ((goal ?? "").isNotEmpty)
              IconButton(
                onPressed: onEditGoal,
                style: IconButton.styleFrom(backgroundColor: LiqColors.glassFill),
                icon: const Icon(LucideIcons.pen, color: LiqColors.textSecondary, size: 16),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            if (daysLeft != null) ...[
              const Icon(LucideIcons.clock, size: 13, color: LiqColors.accentSoft),
              const SizedBox(width: 4),
              Text(
                l10n.tr('days_left', {'n': '$daysLeft'}),
                style: GoogleFonts.inter(color: LiqColors.accentSoft, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 10),
            ],
            if ((goal ?? "").isNotEmpty)
              Expanded(
                child: Text(
                  goal!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(color: LiqColors.textTertiary, fontSize: 13),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _NoGoalCard extends StatelessWidget {
  const _NoGoalCard({required this.l10n, required this.onSetGoal});
  final AppL10n l10n;
  final VoidCallback onSetGoal;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      glow: true,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(colors: [LiqColors.accentSoft, LiqColors.accent]),
                ),
                child: const Icon(LucideIcons.target, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                l10n.t('set_goal_first'),
                style: GoogleFonts.poppins(
                  color: LiqColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "Go to your Profile and set the topic you want to learn and the target date. ILM AI will build a daily plan based on that.", // l10n ga qo'shishingiz mumkin
            style: GoogleFonts.inter(color: LiqColors.textSecondary, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 20),
          LiqButton(
            label: l10n.t('set_learning_goal'),
            icon: LucideIcons.target,
            height: 48,
            onPressed: onSetGoal,
          )
        ],
      ),
    );
  }
}

class _EmptyPlan extends StatelessWidget {
  const _EmptyPlan({required this.onTap, required this.l10n});
  final VoidCallback onTap;
  final AppL10n l10n;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 18),
      child: Column(
        children: [
          const Icon(LucideIcons.sparkles, color: LiqColors.accentSoft, size: 28),
          const SizedBox(height: 10),
          Text(
            l10n.t('tap_to_generate'),
            style: GoogleFonts.poppins(
              color: LiqColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.t('ai_generate_desc'),
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: LiqColors.textTertiary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        tint: LiqColors.danger.withOpacity(0.12),
        strokeColor: LiqColors.danger.withOpacity(0.4),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        child: Row(
          children: [
            const Icon(LucideIcons.triangle_alert, color: LiqColors.danger, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(color: LiqColors.textPrimary, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({required this.day, required this.index});
  final PlanDay day;
  final int index;

  @override
  Widget build(BuildContext context) {
    final color = [LiqColors.auroraGreen, LiqColors.auroraTeal, LiqColors.auroraViolet, LiqColors.auroraAmber, LiqColors.auroraPink][index % 5];
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                colors: [color.withOpacity(0.4), color.withOpacity(0.15)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: color.withOpacity(0.4)),
            ),
            child: Center(
              child: Text(
                "D${day.day}",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  day.title,
                  style: GoogleFonts.poppins(
                    color: LiqColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                for (final task in day.tasks)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 14,
                          height: 14,
                          margin: const EdgeInsets.only(top: 3),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: LiqColors.glassStrokeStrong, width: 1.2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            task,
                            style: GoogleFonts.inter(
                              color: LiqColors.textSecondary,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}