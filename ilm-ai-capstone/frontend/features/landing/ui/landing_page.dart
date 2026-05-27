import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/liq_colors.dart';
import '../../../core/ui/aurora_background.dart';
import '../../../core/ui/glass_card.dart';
import '../../../core/l10n/app_l10n.dart';

class LandingPage extends ConsumerStatefulWidget {
  const LandingPage({super.key});

  @override
  ConsumerState<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends ConsumerState<LandingPage> {
  final _scroll = ScrollController();
  Map<String, dynamic> _links = {};

  @override
  void initState() {
    super.initState();
    _loadLinks();
  }

  Future<void> _loadLinks() async {
    try {
      final String response = await rootBundle.loadString('assets/links.json');
      setState(() {
        _links = jsonDecode(response);
      });
    } catch (e) {
      setState(() {
        _links = {
          "play_demo": "/auth",
          "watch_video": "https://youtu.be/TYbUJlJmbNU?si=gmL8mTm_2O8MLGL_",
          "pitch_deck": "http://ilmai.arzucoder.uz/",
          "google_play": "https://play.google.com/store/apps/details?id=com.arzucoder.ilm_ai"
        };
      });
    }
  }

  void _handleLink(String key) async {
    final url = _links[key] ?? "";
    if (url.startsWith('/')) {
      context.go(url);
    } else if (url.isNotEmpty) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(l10nProvider).valueOrNull ?? AppL10n({});
    final locale = ref.watch(localeProvider);
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 800;

    if (_links.isEmpty) {
      return const Scaffold(
        backgroundColor: LiqColors.bgDeep,
        body: Center(child: CircularProgressIndicator(color: LiqColors.accent)),
      );
    }

    return Scaffold(
      backgroundColor: LiqColors.bgDeep,
      body: AuroraBackground(
        intensity: 0.8,
        child: CustomScrollView(
          controller: _scroll,
          slivers: [
            SliverAppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              pinned: true,
              toolbarHeight: 80,
              flexibleSpace: ClipRect(
                child: BackdropFilter(
                  filter: ColorFilter.mode(
                      LiqColors.bgDeep.withOpacity(0.7), BlendMode.srcOver),
                  child: Container(color: Colors.transparent),
                ),
              ),
              title: Row(
                children: [
                  const SizedBox(width: 24),
                  Image.asset('assets/images/icon.png', width: 32, height: 32)
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .shimmer(
                      duration: 2.seconds,
                      color: Colors.white.withOpacity(0.5)),
                  const SizedBox(width: 12),
                  Text(
                    l10n.t('app_name'),
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 20),
                  ),
                  const Spacer(),
                  if (isDesktop) _LangRow(current: locale),
                ],
              ),
              actions: [
                if (!isDesktop) ...[
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _LanguageDropdown(current: locale),
                    ),
                  ),
                ],
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 32),
                    child: _HoverScale(
                      child: LiqButton(
                        label: l10n.t('try_demo'),
                        icon: LucideIcons.play,
                        height: 44,
                        onPressed: () => _handleLink('play_demo'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 80),
                    _HeroSection(onAction: _handleLink, l10n: l10n, locale: locale),
                    const SizedBox(height: 80),
                    _AboutMentorshipSection(),
                    const SizedBox(height: 80),
                    _StatsSection(l10n: l10n),
                    const SizedBox(height: 120),
                    _HowItWorksSection(l10n: l10n),
                    const SizedBox(height: 120),
                    _ProblemSolutionSection(l10n: l10n),
                    const SizedBox(height: 120),
                    _DeepFeaturesSection(l10n: l10n),
                    const SizedBox(height: 120),
                    _TestimonialsSection(l10n: l10n),
                    const SizedBox(height: 120),
                    _PricingSection(onAction: _handleLink, l10n: l10n),
                    const SizedBox(height: 120),
                    _FAQSection(l10n: l10n),
                    const SizedBox(height: 120),
                    _TechSection(l10n: l10n),
                    const SizedBox(height: 120),
                    _CTABanner(onAction: _handleLink, l10n: l10n),
                    const SizedBox(height: 80),
                    _Footer(l10n: l10n),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutMentorshipSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: GlassCard(
          glow: true,
          tint: LiqColors.auroraTeal.withOpacity(0.05),
          strokeColor: LiqColors.auroraTeal.withOpacity(0.3),
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: LiqColors.auroraTeal.withOpacity(0.2),
                ),
                child: const Icon(LucideIcons.rocket, color: LiqColors.auroraTeal, size: 32),
              ),
              const SizedBox(height: 20),
              Text(
                "Project Attribution & Credits",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Text(
                "This platform was built as the Final Project (Option A) by a participant of the AI Incubator Mentorship Program to advance to Stage 2. \n\nThe original concept and idea of \"ILM AI\" strictly belongs to AI Incubator Org. The developer of this website acted solely as the builder for the 5-week challenge.",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: LiqColors.textSecondary, fontSize: 15, height: 1.6),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: [
                  _InfoButton(icon: LucideIcons.globe, label: "Website", url: "https://www.ai-incubator.org/"),
                  _InfoButton(icon: LucideIcons.link, label: "Instagram", url: "https://www.instagram.com/ai_incubator_org/"),
                  _InfoButton(icon: LucideIcons.link, label: "LinkedIn", url: "https://www.linkedin.com/company/ai-incubator-org"),
                ],
              )
            ],
          ),
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }
}

class _InfoButton extends StatelessWidget {
  const _InfoButton({required this.icon, required this.label, required this.url});
  final IconData icon;
  final String label;
  final String url;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: LiqColors.glassFill,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: LiqColors.glassStroke),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: LiqColors.textSecondary, size: 16),
              const SizedBox(width: 8),
              Text(label, style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageDropdown extends ConsumerWidget {
  const _LanguageDropdown({required this.current});
  final String current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      onSelected: (code) => ref.read(localeProvider.notifier).setLocale(code),
      color: LiqColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      icon: const Icon(LucideIcons.globe, color: LiqColors.textSecondary),
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
          Text(label, style: GoogleFonts.inter(color: LiqColors.textPrimary)),
          if (current == code)
            const Icon(LucideIcons.check, color: LiqColors.accent, size: 18),
        ],
      ),
    );
  }
}

class _LangRow extends ConsumerWidget {
  const _LangRow({required this.current});
  final String current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: ['uz', 'ru', 'en'].map((code) {
        final active = current == code;
        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: GestureDetector(
            onTap: () => ref.read(localeProvider.notifier).setLocale(code),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: active
                    ? LiqColors.accent.withOpacity(0.3)
                    : LiqColors.glassFill,
                border: Border.all(
                    color: active
                        ? LiqColors.accentSoft
                        : LiqColors.glassStroke),
              ),
              child: Text(
                code.toUpperCase(),
                style: GoogleFonts.inter(
                  color: active ? Colors.white : LiqColors.textSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _HoverScale extends StatefulWidget {
  const _HoverScale({required this.child});
  final Widget child;

  @override
  State<_HoverScale> createState() => _HoverScaleState();
}

class _HoverScaleState extends State<_HoverScale> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.onAction, required this.l10n, required this.locale});
  final Function(String) onAction;
  final AppL10n l10n;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 800;

    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: LiqColors.accent.withOpacity(0.4),
                blurRadius: 60,
                spreadRadius: -10,
              ),
            ],
          ),
          child: Image.asset('assets/images/icon.png'),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .moveY(begin: -8, end: 8, duration: 3.seconds, curve: Curves.easeInOut)
            .fadeIn(duration: 600.ms)
            .scale(begin: const Offset(0.8, 0.8)),
        const SizedBox(height: 40),
        Text(
          l10n.t('hero_title'),
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: isDesktop ? 64 : 42,
            fontWeight: FontWeight.w800,
            height: 1.1,
            letterSpacing: -2,
          ),
        )
            .animate()
            .fadeIn(delay: 200.ms, duration: 600.ms)
            .slideY(begin: 0.2)
            .blur(
            begin: const Offset(10, 10),
            end: Offset.zero,
            duration: 600.ms),
        const SizedBox(height: 24),
        Container(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Text(
            l10n.t('hero_subtitle'),
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: LiqColors.textSecondary,
              fontSize: isDesktop ? 20 : 16,
              height: 1.5,
            ),
          ),
        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
        const SizedBox(height: 48),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.center,
          children: [
            // 1. Play Web Demo tugmasi
            SizedBox(
              width: 220,
              child: _HoverScale(
                child: LiqButton(
                  label: l10n.t('play_web_demo'),
                  icon: LucideIcons.mouse_pointer_2,
                  height: 56,
                  onPressed: () => onAction('play_demo'),
                ),
              ),
            ),
            // 2. Watch Video tugmasi
            SizedBox(
              width: 220,
              child: _HoverScale(
                child: GlassCard(
                  onTap: () => onAction('watch_video'),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  radius: 28,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.circle_play,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        l10n.t('watch_video'),
                        style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // 3. Pitch Deck tugmasi
            SizedBox(
              width: 220,
              child: _HoverScale(
                child: GlassCard(
                  onTap: () => onAction('pitch_deck'),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  radius: 28,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.presentation,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        locale == 'uz' ? "Taqdimot" : locale == 'ru' ? "Презентация" : "Pitch Deck",
                        style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // 4. Google Play tugmasi
            SizedBox(
              width: 220,
              child: _HoverScale(
                child: GlassCard(
                  onTap: () => onAction('google_play'),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  radius: 28,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.android,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        "Google Play",
                        style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2),
      ],
    );
  }
}

class _StatsSection extends StatelessWidget {
  const _StatsSection({required this.l10n});
  final AppL10n l10n;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 40,
      runSpacing: 40,
      alignment: WrapAlignment.center,
      children: [
        _StatCard(
          number: l10n.t('stats_users'),
          label: l10n.t('stats_users_label'),
          icon: LucideIcons.users,
          color: LiqColors.auroraGreen,
        ),
        _StatCard(
          number: l10n.t('stats_cards'),
          label: l10n.t('stats_cards_label'),
          icon: LucideIcons.layers,
          color: LiqColors.auroraTeal,
        ),
        _StatCard(
          number: l10n.t('stats_accuracy'),
          label: l10n.t('stats_accuracy_label'),
          icon: LucideIcons.target,
          color: LiqColors.auroraViolet,
        ),
        _StatCard(
          number: l10n.t('stats_countries'),
          label: l10n.t('stats_countries_label'),
          icon: LucideIcons.globe,
          color: LiqColors.accent,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.number,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String number, label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: color.withOpacity(0.1),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Icon(icon, color: color, size: 40),
        )
            .animate()
            .fadeIn()
            .scale(begin: const Offset(0.8, 0.8)),
        const SizedBox(height: 16),
        Text(
          number,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            color: LiqColors.textSecondary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _HowItWorksSection extends StatelessWidget {
  const _HowItWorksSection({required this.l10n});
  final AppL10n l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          l10n.t('how_title'),
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 44,
            fontWeight: FontWeight.w700,
          ),
        ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
        const SizedBox(height: 16),
        Text(
          l10n.t('how_subtitle'),
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: LiqColors.textSecondary,
            fontSize: 18,
          ),
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
        const SizedBox(height: 80),
        Wrap(
          spacing: 32,
          runSpacing: 32,
          alignment: WrapAlignment.center,
          children: [
            _StepCard(
              number: '01',
              title: l10n.t('step1_title'),
              description: l10n.t('step1_desc'),
              icon: LucideIcons.cloud_upload,
              color: LiqColors.auroraGreen,
            ),
            _StepCard(
              number: '02',
              title: l10n.t('step2_title'),
              description: l10n.t('step2_desc'),
              icon: LucideIcons.brain_circuit,
              color: LiqColors.auroraTeal,
            ),
            _StepCard(
              number: '03',
              title: l10n.t('step3_title'),
              description: l10n.t('step3_desc'),
              icon: LucideIcons.sparkles,
              color: LiqColors.auroraViolet,
            ),
          ],
        ),
      ],
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.number,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  final String number, title, description;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: [color.withOpacity(0.3), color.withOpacity(0.1)],
              ),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, color: color, size: 40),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Text(
                    number,
                    style: GoogleFonts.poppins(
                      color: color.withOpacity(0.5),
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: LiqColors.textSecondary,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9));
  }
}

class _ProblemSolutionSection extends StatelessWidget {
  const _ProblemSolutionSection({required this.l10n});
  final AppL10n l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          l10n.t('why_title'),
          style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 44,
              fontWeight: FontWeight.w700),
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
        const SizedBox(height: 16),
        Text(
          l10n.t('why_subtitle'),
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
              color: LiqColors.textSecondary, fontSize: 18),
        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
        const SizedBox(height: 60),
        Wrap(
          spacing: 24,
          runSpacing: 24,
          alignment: WrapAlignment.center,
          children: [
            _HoverScale(
              child: _FeatureCard(
                icon: LucideIcons.brain_circuit,
                title: l10n.t('feat1_title'),
                problem: l10n.t('feat1_problem'),
                solution: l10n.t('feat1_solution'),
                color: LiqColors.auroraGreen,
                problemLabel: l10n.t('problem'),
                solutionLabel: l10n.t('solution'),
              ),
            ).animate().fadeIn(delay: 400.ms).scale(),
            _HoverScale(
              child: _FeatureCard(
                icon: LucideIcons.calendar_clock,
                title: l10n.t('feat2_title'),
                problem: l10n.t('feat2_problem'),
                solution: l10n.t('feat2_solution'),
                color: LiqColors.auroraViolet,
                problemLabel: l10n.t('problem'),
                solutionLabel: l10n.t('solution'),
              ),
            ).animate().fadeIn(delay: 500.ms).scale(),
            _HoverScale(
              child: _FeatureCard(
                icon: LucideIcons.layers,
                title: l10n.t('feat3_title'),
                problem: l10n.t('feat3_problem'),
                solution: l10n.t('feat3_solution'),
                color: LiqColors.auroraTeal,
                problemLabel: l10n.t('problem'),
                solutionLabel: l10n.t('solution'),
              ),
            ).animate().fadeIn(delay: 600.ms).scale(),
          ],
        ),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.problem,
    required this.solution,
    required this.color,
    required this.problemLabel,
    required this.solutionLabel,
  });

  final IconData icon;
  final String title, problem, solution, problemLabel, solutionLabel;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 360,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: LiqColors.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: LiqColors.glassStroke),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 40,
            spreadRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                height: 1.2),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: LiqColors.danger.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: LiqColors.danger.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(problemLabel,
                    style: GoogleFonts.inter(
                        color: LiqColors.danger,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1)),
                const SizedBox(height: 6),
                Text(problem,
                    style: GoogleFonts.inter(
                        color: LiqColors.textSecondary,
                        fontSize: 14,
                        height: 1.5)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: LiqColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: LiqColors.accent.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(solutionLabel,
                    style: GoogleFonts.inter(
                        color: LiqColors.accentSoft,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1)),
                const SizedBox(height: 6),
                Text(solution,
                    style: GoogleFonts.inter(
                        color: LiqColors.textSecondary,
                        fontSize: 14,
                        height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeepFeaturesSection extends StatelessWidget {
  const _DeepFeaturesSection({required this.l10n});
  final AppL10n l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          l10n.t('deep_features'),
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 44,
            fontWeight: FontWeight.w700,
          ),
        ).animate().fadeIn().slideY(begin: 0.1),
        const SizedBox(height: 60),
        Wrap(
          spacing: 24,
          runSpacing: 24,
          alignment: WrapAlignment.center,
          children: [
            _DeepFeatureCard(
              icon: LucideIcons.zap,
              title: l10n.t('feat_rag_title'),
              desc: l10n.t('feat_rag_desc'),
              color: LiqColors.accent,
            ),
            _DeepFeatureCard(
              icon: LucideIcons.calendar_check,
              title: l10n.t('feat_plan_title'),
              desc: l10n.t('feat_plan_desc'),
              color: LiqColors.auroraGreen,
            ),
            _DeepFeatureCard(
              icon: LucideIcons.layers,
              title: l10n.t('feat_flash_title'),
              desc: l10n.t('feat_flash_desc'),
              color: LiqColors.auroraTeal,
            ),
            _DeepFeatureCard(
              icon: LucideIcons.languages,
              title: l10n.t('feat_multi_title'),
              desc: l10n.t('feat_multi_desc'),
              color: LiqColors.auroraViolet,
            ),
            _DeepFeatureCard(
              icon: LucideIcons.shield_check,
              title: l10n.t('feat_secure_title'),
              desc: l10n.t('feat_secure_desc'),
              color: LiqColors.auroraPink,
            ),
            _DeepFeatureCard(
              icon: LucideIcons.wifi_off,
              title: l10n.t('feat_offline_title'),
              desc: l10n.t('feat_offline_desc'),
              color: LiqColors.auroraAmber,
            ),
          ],
        ),
      ],
    );
  }
}

class _DeepFeatureCard extends StatelessWidget {
  const _DeepFeatureCard({
    required this.icon,
    required this.title,
    required this.desc,
    required this.color,
  });

  final IconData icon;
  final String title, desc;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: GlassCard(
        padding: const EdgeInsets.all(24),
        radius: 24,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: color.withOpacity(0.2),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              desc,
              style: GoogleFonts.inter(
                color: LiqColors.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9));
  }
}

class _TestimonialsSection extends StatelessWidget {
  const _TestimonialsSection({required this.l10n});
  final AppL10n l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          l10n.t('testimonials_title'),
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 44,
            fontWeight: FontWeight.w700,
          ),
        ).animate().fadeIn().slideY(begin: 0.1),
        const SizedBox(height: 16),
        Text(
          l10n.t('testimonials_subtitle'),
          style: GoogleFonts.inter(
            color: LiqColors.textSecondary,
            fontSize: 18,
          ),
        ).animate().fadeIn().slideY(begin: 0.1),
        const SizedBox(height: 60),
        Wrap(
          spacing: 24,
          runSpacing: 24,
          alignment: WrapAlignment.center,
          children: [
            _TestimonialCard(
              name: l10n.t('test1_name'),
              role: l10n.t('test1_role'),
              text: l10n.t('test1_text'),
            ),
            _TestimonialCard(
              name: l10n.t('test2_name'),
              role: l10n.t('test2_role'),
              text: l10n.t('test2_text'),
            ),
            _TestimonialCard(
              name: l10n.t('test3_name'),
              role: l10n.t('test3_role'),
              text: l10n.t('test3_text'),
            ),
          ],
        ),
      ],
    );
  }
}

class _TestimonialCard extends StatelessWidget {
  const _TestimonialCard({
    required this.name,
    required this.role,
    required this.text,
  });

  final String name, role, text;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 340,
      child: GlassCard(
        padding: const EdgeInsets.all(24),
        radius: 24,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: List.generate(
                5,
                    (i) => Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(LucideIcons.star,
                      color: LiqColors.auroraAmber, size: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              text,
              style: GoogleFonts.inter(
                color: LiqColors.textPrimary,
                fontSize: 14,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              height: 1,
              color: LiqColors.glassStroke,
            ),
            const SizedBox(height: 16),
            Text(
              name,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              role,
              style: GoogleFonts.inter(
                color: LiqColors.textTertiary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9));
  }
}

class _PricingSection extends StatelessWidget {
  const _PricingSection({required this.onAction, required this.l10n});
  final Function(String) onAction;
  final AppL10n l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          l10n.t('pricing_title'),
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 44,
            fontWeight: FontWeight.w700,
          ),
        ).animate().fadeIn().slideY(begin: 0.1),
        const SizedBox(height: 16),
        Text(
          l10n.t('pricing_subtitle'),
          style: GoogleFonts.inter(
            color: LiqColors.textSecondary,
            fontSize: 18,
          ),
        ).animate().fadeIn().slideY(begin: 0.1),
        const SizedBox(height: 60),
        Wrap(
          spacing: 32,
          runSpacing: 32,
          alignment: WrapAlignment.center,
          children: [
            _PricingCard(
              name: l10n.t('plan_free'),
              price: l10n.t('plan_free_price'),
              period: l10n.t('plan_per_month'),
              desc: l10n.t('plan_free_desc'),
              features: [
                l10n.t('feat_storage_free'),
                l10n.t('feat_requests_free'),
                l10n.t('feat_cards_free'),
                l10n.t('feat_plans_free'),
              ],
              isPro: false,
              buttonLabel: l10n.t('get_started_free'),
              onTap: () => onAction('play_demo'),
            ),
            _PricingCard(
              name: l10n.t('plan_pro'),
              price: l10n.t('plan_pro_price'),
              period: l10n.t('plan_per_month'),
              desc: l10n.t('plan_pro_desc'),
              features: [
                l10n.t('feat_storage_pro'),
                l10n.t('feat_requests_pro'),
                l10n.t('feat_cards_pro'),
                l10n.t('feat_plans_pro'),
              ],
              isPro: true,
              buttonLabel: l10n.t('upgrade_now'),
              onTap: () => onAction('play_demo'),
            ),
          ],
        ),
      ],
    );
  }
}

class _PricingCard extends StatelessWidget {
  const _PricingCard({
    required this.name,
    required this.price,
    required this.period,
    required this.desc,
    required this.features,
    required this.isPro,
    required this.buttonLabel,
    required this.onTap,
  });

  final String name, price, period, desc;
  final List<String> features;
  final bool isPro;
  final String buttonLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 360,
      child: GlassCard(
        glow: isPro,
        padding: const EdgeInsets.all(32),
        radius: 28,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isPro)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: LiqColors.accent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: LiqColors.accent.withOpacity(0.4)),
                ),
                child: Text(
                  '⭐ POPULAR',
                  style: GoogleFonts.inter(
                    color: LiqColors.accentSoft,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            if (isPro) const SizedBox(height: 12),
            Text(
              name,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: price,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(
                    text: period,
                    style: GoogleFonts.inter(
                      color: LiqColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              desc,
              style: GoogleFonts.inter(
                color: LiqColors.textTertiary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),
            _HoverScale(
              child: isPro
                  ? LiqButton(
                label: buttonLabel,
                icon: LucideIcons.check,
                height: 48,
                onPressed: onTap,
              )
                  : GhostButton(
                label: buttonLabel,
                icon: LucideIcons.play,
                height: 48,
                onPressed: onTap,
              ),
            ),
            const SizedBox(height: 32),
            Column(
              children: features
                  .map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(LucideIcons.check,
                        color: LiqColors.accent, size: 18),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        f,
                        style: GoogleFonts.inter(
                          color: LiqColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ))
                  .toList(),
            ),
          ],
        ),
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9));
  }
}

class _FAQSection extends StatefulWidget {
  const _FAQSection({required this.l10n});
  final AppL10n l10n;

  @override
  State<_FAQSection> createState() => _FAQSectionState();
}

class _FAQSectionState extends State<_FAQSection> {
  int? _expandedIndex;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          widget.l10n.t('faq_title'),
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 44,
            fontWeight: FontWeight.w700,
          ),
        ).animate().fadeIn().slideY(begin: 0.1),
        const SizedBox(height: 16),
        Text(
          widget.l10n.t('faq_subtitle'),
          style: GoogleFonts.inter(
            color: LiqColors.textSecondary,
            fontSize: 18,
          ),
        ).animate().fadeIn().slideY(begin: 0.1),
        const SizedBox(height: 60),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: List.generate(5, (i) {
              final qKey = 'faq_${i + 1}_q';
              final aKey = 'faq_${i + 1}_a';
              final expanded = _expandedIndex == i;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: GestureDetector(
                  onTap: () =>
                      setState(() => _expandedIndex = expanded ? null : i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      color: LiqColors.surface.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: expanded
                            ? LiqColors.accent.withOpacity(0.4)
                            : LiqColors.glassStroke,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  widget.l10n.t(qKey),
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Icon(
                                expanded
                                    ? LucideIcons.chevron_up
                                    : LucideIcons.chevron_down,
                                color: LiqColors.accent,
                              ),
                            ],
                          ),
                          if (expanded) ...[
                            const SizedBox(height: 16),
                            Text(
                              widget.l10n.t(aKey),
                              style: GoogleFonts.inter(
                                color: LiqColors.textSecondary,
                                fontSize: 14,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _TechSection extends StatelessWidget {
  const _TechSection({required this.l10n});
  final AppL10n l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          l10n.t('tech_title'),
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 44,
            fontWeight: FontWeight.w700,
          ),
        ).animate().fadeIn().slideY(begin: 0.1),
        const SizedBox(height: 16),
        Text(
          l10n.t('tech_subtitle'),
          style: GoogleFonts.inter(
            color: LiqColors.textSecondary,
            fontSize: 18,
          ),
        ).animate().fadeIn().slideY(begin: 0.1),
        const SizedBox(height: 60),
        Wrap(
          spacing: 24,
          runSpacing: 24,
          alignment: WrapAlignment.center,
          children: [
            _TechCard(
              title: l10n.t('rag_title'),
              description: l10n.t('rag_desc'),
              icon: LucideIcons.database,
            ),
            _TechCard(
              title: l10n.t('llm_title'),
              description: l10n.t('llm_desc'),
              icon: LucideIcons.brain_circuit,
            ),
            _TechCard(
              title: l10n.t('vector_title'),
              description: l10n.t('vector_desc'),
              icon: LucideIcons.grid_3x3,
            ),
          ],
        ),
      ],
    );
  }
}

class _TechCard extends StatelessWidget {
  const _TechCard({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title, description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      child: GlassCard(
        padding: const EdgeInsets.all(28),
        radius: 24,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: LiqColors.accent, size: 40),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: GoogleFonts.inter(
                color: LiqColors.textSecondary,
                fontSize: 13,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9));
  }
}

class _CTABanner extends StatelessWidget {
  const _CTABanner({required this.onAction, required this.l10n});
  final Function(String) onAction;
  final AppL10n l10n;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      glow: true,
      padding: const EdgeInsets.all(48),
      radius: 32,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            l10n.t('cta_title'),
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 44,
              fontWeight: FontWeight.w700,
            ),
          ).animate().fadeIn().slideY(begin: 0.1),
          const SizedBox(height: 16),
          Text(
            l10n.t('cta_subtitle'),
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: LiqColors.textSecondary,
              fontSize: 18,
              height: 1.6,
            ),
          ).animate().fadeIn().slideY(begin: 0.1),
          const SizedBox(height: 40),
          _HoverScale(
            child: SizedBox(
              width: 280,
              child: LiqButton(
                label: l10n.t('cta_btn'),
                icon: LucideIcons.rocket,
                height: 56,
                onPressed: () => onAction('play_demo'),
              ),
            ),
          ).animate().fadeIn().slideY(begin: 0.1),
          const SizedBox(height: 16),
          Text(
            l10n.t('cta_no_credit'),
            style: GoogleFonts.inter(
              color: LiqColors.textTertiary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95));
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.l10n});
  final AppL10n l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: LiqColors.glassStroke)),
      ),
      child: Column(
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 24,
            runSpacing: 8,
            children: [
              _FooterLink(
                label: l10n.t('terms_title'),
                onTap: () => context.go('/terms'),
              ),
              _FooterLink(
                label: l10n.t('privacy_title'),
                onTap: () => context.go('/privacy'),
              ),
              _FooterLink(
                label: l10n.t('delete_account'),
                onTap: () => context.go('/delete-account'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            children: [
              Text(
                "© 2026 Ilm AI. Designed & Developed by ",
                style: GoogleFonts.inter(color: LiqColors.textMuted, fontSize: 14),
              ),
              GestureDetector(
                onTap: () => launchUrl(Uri.parse('https://arzucoder.uz'), mode: LaunchMode.externalApplication),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Text(
                    "ARZUCODER.",
                    style: GoogleFonts.inter(
                      color: LiqColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: LiqColors.textTertiary,
          fontSize: 13,
          decoration: TextDecoration.underline,
          decorationColor: LiqColors.textTertiary,
        ),
      ),
    );
  }
}