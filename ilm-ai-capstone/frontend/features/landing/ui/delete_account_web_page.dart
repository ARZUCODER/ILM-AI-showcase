import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/liq_colors.dart';
import '../../../core/ui/aurora_background.dart';
import '../../../core/ui/glass_card.dart';
import '../../../core/l10n/app_l10n.dart';

class DeleteAccountWebPage extends ConsumerWidget {
  const DeleteAccountWebPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(l10nProvider).valueOrNull ?? AppL10n({});

    return Scaffold(
      backgroundColor: LiqColors.bgDeep,
      body: AuroraBackground(
        intensity: 0.5,
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  onPressed: () =>
                      context.canPop() ? context.pop() : context.go('/'),
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: LiqColors.glassFill,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: LiqColors.glassStroke),
                    ),
                    child: const Icon(LucideIcons.chevron_left,
                        color: LiqColors.textPrimary, size: 20),
                  ),
                ),
                title: Text(
                  l10n.t('delete_account_web_title'),
                  style: GoogleFonts.poppins(
                    color: LiqColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.t('delete_account_web_subtitle'),
                            style: GoogleFonts.poppins(
                              color: LiqColors.textSecondary,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.t('delete_account_web_intro'),
                            style: GoogleFonts.inter(
                              color: LiqColors.textSecondary,
                              fontSize: 15,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 32),
                          GlassCard(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.t('delete_account_web_steps_title'),
                                  style: GoogleFonts.poppins(
                                    color: LiqColors.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _Step(number: 1, text: l10n.t('delete_account_web_step1')),
                                _Step(number: 2, text: l10n.t('delete_account_web_step2')),
                                _Step(number: 3, text: l10n.t('delete_account_web_step3')),
                                _Step(number: 4, text: l10n.t('delete_account_web_step4')),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          GlassCard(
                            tint: LiqColors.danger.withOpacity(0.08),
                            strokeColor: LiqColors.danger.withOpacity(0.3),
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(LucideIcons.triangle_alert,
                                    color: LiqColors.danger, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    l10n.t('delete_account_web_warning'),
                                    style: GoogleFonts.inter(
                                      color: LiqColors.textSecondary,
                                      fontSize: 14,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            l10n.t('delete_account_web_contact'),
                            style: GoogleFonts.inter(
                              color: LiqColors.textTertiary,
                              fontSize: 14,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 32),
                          GhostButton(
                            label: l10n.t('delete_account_web_back'),
                            icon: LucideIcons.arrow_left,
                            height: 52,
                            onPressed: () =>
                                context.canPop() ? context.pop() : context.go('/'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text});
  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [LiqColors.accentSoft, LiqColors.accent]),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$number',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                text,
                style: GoogleFonts.inter(
                    color: LiqColors.textSecondary, fontSize: 14, height: 1.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
