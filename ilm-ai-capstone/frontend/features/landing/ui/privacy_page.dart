import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/liq_colors.dart';
import '../../../core/ui/aurora_background.dart';
import '../../../core/l10n/app_l10n.dart';

class PrivacyPage extends ConsumerWidget {
  const PrivacyPage({super.key});

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
                  l10n.t('privacy_title'),
                  style: GoogleFonts.poppins(
                    color: LiqColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 48),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.t('privacy_last_updated'),
                          style: GoogleFonts.inter(
                              color: LiqColors.textTertiary, fontSize: 13),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.t('privacy_intro'),
                          style: GoogleFonts.inter(
                            color: LiqColors.textSecondary,
                            fontSize: 15,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildBody(l10n.t('privacy_body')),
                      ],
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

  Widget _buildBody(String body) {
    final sections = body.split('\n\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sections.map((section) {
        final lines = section.split('\n');
        if (lines.isEmpty) return const SizedBox.shrink();
        final title = lines.first;
        final rest = lines.skip(1).join('\n');
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: LiqColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (rest.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  rest,
                  style: GoogleFonts.inter(
                    color: LiqColors.textSecondary,
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }
}
