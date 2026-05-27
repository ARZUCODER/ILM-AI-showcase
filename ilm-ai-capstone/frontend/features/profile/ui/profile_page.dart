import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/l10n/app_l10n.dart';
import '../../../core/theme/liq_colors.dart';
import '../../../core/ui/glass_card.dart';
import '../logic/profile_provider.dart';
import '../../auth/logic/auth_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profileProvider);
    final p = state.profile;
    final l10n = ref.watch(l10nProvider).valueOrNull ?? AppL10n({});
    final locale = ref.watch(localeProvider);

    // Agar xatolik bo'lsa darhol ekranga SnackBar chiqaramiz
    ref.listen<ProfileState>(profileProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: LiqColors.danger,
            behavior: SnackBarBehavior.floating,
            content: Text(next.error!, style: GoogleFonts.inter(color: Colors.white)),
          ),
        );
      }
    });

    final currentEmail = FirebaseAuth.instance.currentUser?.email ?? p?.email ?? "—";

    return RefreshIndicator(
      color: LiqColors.accent,
      backgroundColor: LiqColors.surface,
      onRefresh: () => ref.read(profileProvider.notifier).refresh(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 140),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _Header(profile: p, l10n: l10n)),
              const SizedBox(width: 12),
              _LanguageDropdown(key: ValueKey(locale), current: locale),
            ],
          ),
          const SizedBox(height: 24),
          _GoalCard(
            state: state,
            l10n: l10n,
            onEdit: () => _openGoalSheet(context, ref, state, l10n),
          ).animate().fadeIn(delay: 80.ms).slideY(begin: 0.1),
          if (p?.tier != 'premium') ...[
            const SizedBox(height: 16),
            GlassCard(
              onTap: () => context.push('/premium'),
              glow: true,
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    width: 46, height: 46,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(colors: [LiqColors.auroraAmber, Color(0xFFEAB308)]),
                    ),
                    child: const Icon(LucideIcons.crown, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.t('upgrade_title'), style: GoogleFonts.poppins(color: LiqColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(l10n.t('chat_hero_sub'), style: GoogleFonts.inter(color: LiqColors.textTertiary, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  const Icon(LucideIcons.chevron_right, color: LiqColors.textTertiary, size: 20),
                ],
              ),
            ).animate().fadeIn(delay: 110.ms).slideY(begin: 0.1),
          ],
          const SizedBox(height: 28),
          Text("Telegram Bot", style: GoogleFonts.poppins(fontSize: 18, color: LiqColors.textPrimary, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          _TelegramLinkCard(state: state, ref: ref).animate().fadeIn(delay: 120.ms),
          const SizedBox(height: 28),
          Text(l10n.t('overview'), style: GoogleFonts.poppins(fontSize: 18, color: LiqColors.textPrimary, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          _StatGrid(stats: state.stats, l10n: l10n).animate().fadeIn(delay: 140.ms),
          const SizedBox(height: 28),
          Text(l10n.t('account_settings'), style: GoogleFonts.poppins(fontSize: 18, color: LiqColors.textPrimary, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          _Row(icon: LucideIcons.mail, label: l10n.t('email'), value: currentEmail),
          const SizedBox(height: 10),
          _Row(icon: LucideIcons.shield_check, label: l10n.t('auth_method'), value: (p?.authProvider ?? "—").toUpperCase()),
          const SizedBox(height: 20),
          GlassCard(
            onTap: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/auth');
            },
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.log_out, color: LiqColors.danger, size: 20),
                const SizedBox(width: 12),
                Text(l10n.t('sign_out'), style: GoogleFonts.inter(color: LiqColors.danger, fontWeight: FontWeight.w600, fontSize: 15)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GlassCard(
            onTap: () => _confirmDeleteAccount(context, ref, l10n),
            tint: LiqColors.danger.withOpacity(0.05),
            strokeColor: LiqColors.danger.withOpacity(0.2),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.trash_2, color: LiqColors.danger, size: 18),
                const SizedBox(width: 12),
                Text(l10n.t('delete_account'), style: GoogleFonts.inter(color: LiqColors.danger, fontWeight: FontWeight.w500, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteAccount(BuildContext context, WidgetRef ref, AppL10n l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: LiqColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.t('delete_account_confirm_title'), style: GoogleFonts.poppins(color: LiqColors.textPrimary)),
        content: Text(l10n.t('delete_account_confirm_body'), style: GoogleFonts.inter(color: LiqColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.t('cancel'), style: GoogleFonts.inter(color: LiqColors.textSecondary))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.t('delete_confirm'), style: GoogleFonts.inter(color: LiqColors.danger, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(authProvider.notifier).deleteAccount();
      if (context.mounted) context.go('/auth');
    }
  }

  Future<void> _openGoalSheet(BuildContext context, WidgetRef ref, ProfileState state, AppL10n l10n) async {
    final goalCtrl = TextEditingController(text: state.profile?.learningGoal ?? "");
    DateTime selected = DateTime.tryParse(state.profile?.targetDate ?? "") ?? DateTime.now().add(const Duration(days: 14));

    await showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: LiqColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSt) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 24, left: 20, right: 20, top: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 24), decoration: BoxDecoration(color: LiqColors.glassStroke, borderRadius: BorderRadius.circular(2)))),
                Text(l10n.t('set_learning_goal'), style: GoogleFonts.poppins(color: LiqColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(l10n.t('study_plan_adapt'), style: GoogleFonts.inter(color: LiqColors.textTertiary, fontSize: 13)),
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(color: LiqColors.glassFill, borderRadius: BorderRadius.circular(16), border: Border.all(color: LiqColors.glassStroke)),
                  child: TextField(controller: goalCtrl, style: GoogleFonts.inter(color: LiqColors.textPrimary, fontSize: 15), maxLines: 3, minLines: 1, decoration: InputDecoration(hintText: l10n.t('goal_hint'), hintStyle: GoogleFonts.inter(color: LiqColors.textMuted), border: InputBorder.none, contentPadding: const EdgeInsets.all(16))),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx, initialDate: selected, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                      builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.dark(primary: LiqColors.accent, onPrimary: Colors.white, surface: LiqColors.surface, onSurface: LiqColors.textPrimary), dialogTheme: const DialogThemeData(backgroundColor: LiqColors.surface)), child: child!),
                    );
                    if (picked != null) setSt(() => selected = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: LiqColors.glassFill, borderRadius: BorderRadius.circular(16), border: Border.all(color: LiqColors.glassStroke)),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.calendar_range, color: LiqColors.textSecondary, size: 18),
                        const SizedBox(width: 12),
                        Text(l10n.t('target_deadline'), style: GoogleFonts.inter(color: LiqColors.textSecondary, fontSize: 14)),
                        const Spacer(),
                        Text("${selected.year}-${selected.month.toString().padLeft(2, '0')}-${selected.day.toString().padLeft(2, '0')}", style: GoogleFonts.inter(color: LiqColors.textPrimary, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                LiqButton(
                  label: l10n.t('save_goal'), icon: LucideIcons.check,
                  onPressed: () async {
                    final ok = await ref.read(profileProvider.notifier).saveGoal(goal: goalCtrl.text.trim(), targetDate: selected);
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (ok && context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: LiqColors.surfaceElevated, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), content: Text(l10n.t('goal_saved'), style: GoogleFonts.inter(color: LiqColors.textPrimary))));
                  },
                ),
              ],
            ),
          );
        });
      },
    );
  }
}

class _TelegramLinkCard extends StatelessWidget {
  const _TelegramLinkCard({required this.state, required this.ref});
  final ProfileState state;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    if (state.profile?.isTgLinked == true) {
      return GlassCard(
        glow: true, tint: LiqColors.success.withOpacity(0.08), strokeColor: LiqColors.success.withOpacity(0.3), padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.telegram, color: Color(0xFF2AABEE), size: 28),
                const SizedBox(width: 12),
                Text("Telegram Connected", style: GoogleFonts.poppins(color: LiqColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                const Spacer(),
                const Icon(LucideIcons.check, color: LiqColors.success, size: 20),
              ],
            ),
            const SizedBox(height: 12),
            Text("Your account is successfully linked. You can receive daily reminders and run quizzes directly in the bot.", style: GoogleFonts.inter(color: LiqColors.textSecondary, fontSize: 13, height: 1.5)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: GhostButton(label: "Disconnect", icon: LucideIcons.unplug, onPressed: () => ref.read(profileProvider.notifier).disconnectTg())),
                const SizedBox(width: 12),
                Expanded(child: LiqButton(label: "Open Bot", icon: Icons.telegram, gradient: const [Color(0xFF229ED9), Color(0xFF2AABEE)], onPressed: () => launchUrl(Uri.parse("https://t.me/ILM_AIBOT"), mode: LaunchMode.externalApplication))),
              ],
            ),
          ],
        ),
      );
    }

    if (state.tgCode == null) {
      return GlassCard(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.telegram, color: Color(0xFF2AABEE), size: 28),
                const SizedBox(width: 12),
                Text("Link Telegram", style: GoogleFonts.poppins(color: LiqColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            Text("Connect ILM AI bot to receive daily reminders and run quizzes directly in Telegram.", style: GoogleFonts.inter(color: LiqColors.textSecondary, fontSize: 13, height: 1.5)),
            const SizedBox(height: 20),
            LiqButton(label: "Generate Code", icon: LucideIcons.key, height: 48, onPressed: () => ref.read(profileProvider.notifier).generateTgCode()),
          ],
        ),
      );
    }

    return GlassCard(
      glow: true, tint: const Color(0xFF2AABEE).withOpacity(0.1), strokeColor: const Color(0xFF2AABEE).withOpacity(0.3), padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text("Your Connection Code", style: GoogleFonts.inter(color: LiqColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), decoration: BoxDecoration(color: LiqColors.bgDeep, borderRadius: BorderRadius.circular(16), border: Border.all(color: LiqColors.glassStroke)),
            child: Text(state.tgCode!, style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: 8)),
          ),
          const SizedBox(height: 12),
          Text("Expires in 10 minutes", style: GoogleFonts.inter(color: LiqColors.danger, fontSize: 11)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: GhostButton(label: "Copy", icon: LucideIcons.copy, onPressed: () { Clipboard.setData(ClipboardData(text: state.tgCode!)); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Code copied!", style: GoogleFonts.inter(color: Colors.white)), backgroundColor: LiqColors.success, behavior: SnackBarBehavior.floating)); })),
              const SizedBox(width: 12),
              Expanded(child: LiqButton(label: "Open Telegram", icon: Icons.telegram, gradient: const [Color(0xFF229ED9), Color(0xFF2AABEE)], onPressed: () => launchUrl(Uri.parse("https://t.me/ILM_AIBOT?start=${state.tgCode}"), mode: LaunchMode.externalApplication))),
            ],
          ),
        ],
      ),
    );
  }
}

class _LanguageDropdown extends ConsumerWidget {
  const _LanguageDropdown({super.key, required this.current});
  final String current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      initialValue: current,
      onSelected: (code) { if (code != current) ref.read(localeProvider.notifier).setLocale(code); },
      color: LiqColors.surface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), offset: const Offset(0, 40),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: LiqColors.glassFill, borderRadius: BorderRadius.circular(12), border: Border.all(color: LiqColors.glassStroke)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(LucideIcons.globe, color: LiqColors.textSecondary, size: 16), const SizedBox(width: 6), Text(current.toUpperCase(), style: GoogleFonts.inter(color: LiqColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)), const SizedBox(width: 4), const Icon(LucideIcons.chevron_down, color: LiqColors.textSecondary, size: 14)]),
      ),
      itemBuilder: (context) => [
        _buildItem('uz', 'O\'zbekcha', current),
        _buildItem('ru', 'Русский', current),
        _buildItem('en', 'English', current),
      ],
    );
  }

  PopupMenuItem<String> _buildItem(String code, String label, String current) {
    return PopupMenuItem<String>(
      value: code,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(color: current == code ? LiqColors.accentSoft : LiqColors.textPrimary, fontWeight: current == code ? FontWeight.w600 : FontWeight.w400)),
          if (current == code) const Icon(LucideIcons.check, color: LiqColors.accentSoft, size: 18),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.profile, required this.l10n});
  final ProfileData? profile;
  final AppL10n l10n;

  @override
  Widget build(BuildContext context) {
    final fallbackEmail = FirebaseAuth.instance.currentUser?.email ?? profile?.email ?? "";
    final displayName = (profile?.name.isNotEmpty ?? false) ? profile!.name : fallbackEmail.split('@').first;
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : "U";
    final hasPicture = profile?.pictureUrl != null && profile!.pictureUrl!.isNotEmpty;

    return Row(
      children: [
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(shape: BoxShape.circle, gradient: !hasPicture ? const LinearGradient(colors: [LiqColors.auroraTeal, LiqColors.auroraViolet], begin: Alignment.topLeft, end: Alignment.bottomRight) : null, boxShadow: [BoxShadow(color: LiqColors.auroraViolet.withOpacity(0.4), blurRadius: 18, offset: const Offset(0, 6))], border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5)),
          child: hasPicture ? ClipOval(child: Image.network(profile!.pictureUrl!, fit: BoxFit.cover, errorBuilder: (c, e, s) => Center(child: Text(initial, style: GoogleFonts.poppins(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700))))) : Center(child: Text(initial, style: GoogleFonts.poppins(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700))),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(displayName.isEmpty ? l10n.t('learner') : displayName, style: GoogleFonts.poppins(color: LiqColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.5), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: (profile?.tier == 'premium') ? LiqColors.accent.withOpacity(0.2) : LiqColors.glassFill, borderRadius: BorderRadius.circular(12), border: Border.all(color: (profile?.tier == 'premium') ? LiqColors.accent.withOpacity(0.4) : LiqColors.glassStroke)),
                child: Text((profile?.tier == 'premium') ? '⭐ ${l10n.t('pro_member')}' : l10n.t('learner'), style: GoogleFonts.inter(color: (profile?.tier == 'premium') ? LiqColors.accentSoft : LiqColors.textTertiary, fontSize: 10, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.state, required this.onEdit, required this.l10n});
  final ProfileState state;
  final VoidCallback onEdit;
  final AppL10n l10n;

  @override
  Widget build(BuildContext context) {
    final goal = state.profile?.learningGoal ?? "";
    final daysLeft = state.profile?.daysLeft;
    return GlassCard(
      glow: true, padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 40, height: 40, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: const LinearGradient(colors: [LiqColors.accentSoft, LiqColors.accent])), child: const Icon(LucideIcons.target, color: Colors.white, size: 22)),
              const SizedBox(width: 14), Text(l10n.t('current_goal'), style: GoogleFonts.poppins(color: LiqColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)), const Spacer(), IconButton(onPressed: onEdit, style: IconButton.styleFrom(backgroundColor: LiqColors.glassFill), icon: const Icon(LucideIcons.pen, color: LiqColors.textSecondary, size: 16)),
            ],
          ),
          const SizedBox(height: 16),
          if (goal.isEmpty) Text(l10n.t('tap_edit_to_set'), style: GoogleFonts.inter(color: LiqColors.textTertiary, fontSize: 13, height: 1.5))
          else ...[
            Text(goal, style: GoogleFonts.inter(color: LiqColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w500, height: 1.4)),
            const SizedBox(height: 16),
            if (daysLeft != null) Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: LiqColors.accent.withOpacity(0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: LiqColors.accent.withOpacity(0.3))), child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(LucideIcons.clock, color: LiqColors.accentSoft, size: 14), const SizedBox(width: 6), Text(l10n.tr('days_remaining', {'n': '$daysLeft'}), style: GoogleFonts.inter(color: LiqColors.accentSoft, fontSize: 13, fontWeight: FontWeight.w600))])),
          ],
        ],
      ),
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.stats, required this.l10n});
  final ProfileStats stats;
  final AppL10n l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(children: [Expanded(child: _StatTile(icon: LucideIcons.file_text, label: l10n.t('materials'), value: "${stats.files}", color: LiqColors.auroraTeal)), const SizedBox(width: 16), Expanded(child: _StatTile(icon: LucideIcons.layers, label: l10n.t('chunks_label'), value: "${stats.chunks}", color: LiqColors.auroraViolet))]),
        const SizedBox(height: 16),
        Row(children: [Expanded(child: _StatTile(icon: LucideIcons.messages_square, label: l10n.t('questions_label'), value: "${stats.chatMessages}", color: LiqColors.auroraGreen)), const SizedBox(width: 16), Expanded(child: _StatTile(icon: LucideIcons.brain, label: l10n.t('accuracy'), value: "${stats.accuracy.toStringAsFixed(0)}%", color: LiqColors.auroraAmber))]),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.icon, required this.label, required this.value, required this.color});
  final IconData icon;
  final String label, value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.3))), child: Icon(icon, color: color, size: 18)),
          const SizedBox(height: 16), FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(value, style: GoogleFonts.poppins(color: LiqColors.textPrimary, fontSize: 26, fontWeight: FontWeight.w700))), const SizedBox(height: 2), Text(label, style: GoogleFonts.inter(color: LiqColors.textTertiary, fontSize: 13)),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label, value;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: LiqColors.glassFill, borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: LiqColors.textSecondary, size: 18)),
          const SizedBox(width: 16), Text(label, style: GoogleFonts.inter(color: LiqColors.textSecondary, fontSize: 14)), const Spacer(), Flexible(child: Text(value, style: GoogleFonts.inter(color: LiqColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}