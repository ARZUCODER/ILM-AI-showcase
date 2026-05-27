import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/l10n/app_l10n.dart';
import '../../../core/theme/liq_colors.dart';
import '../../../core/ui/glass_card.dart';
import '../../../core/ui/app_shell.dart';
import '../../knowledge/logic/upload_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  Future<void> _pick(WidgetRef ref) async {
    final res = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'md'],
      withData: true,
    );
    if (res != null) {
      await ref.read(uploadProvider.notifier).uploadFile(res.files.single);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final files = ref.watch(filesProvider);
    final upload = ref.watch(uploadProvider);
    final l10n = ref.watch(l10nProvider).valueOrNull ?? AppL10n({});

    ref.listen<UploadState>(uploadProvider, (_, next) {
      if (next is UploadSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: LiqColors.surface,
            behavior: SnackBarBehavior.floating,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            content: Text(
              l10n.tr('chunks_indexed', {'n': '${next.chunksSaved}'}),
              style: GoogleFonts.inter(color: LiqColors.textPrimary),
            ),
          ),
        );
      } else if (next is UploadFailed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor:
            next.isQuota ? LiqColors.surfaceElevated : LiqColors.danger,
            behavior: SnackBarBehavior.floating,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            content: Text(
              next.isQuota
                  ? (next.upgradeMessage ?? next.message)
                  : next.message,
              style: GoogleFonts.inter(color: Colors.white),
            ),
            action: next.isQuota
                ? SnackBarAction(
              label: l10n.t('upgrade_cta'),
              textColor: LiqColors.accent,
              onPressed: () => context.push('/premium'),
            )
                : null,
          ),
        );
      }
    });

    return RefreshIndicator(
      color: LiqColors.accent,
      backgroundColor: LiqColors.surface,
      onRefresh: () => ref.read(filesProvider.notifier).refresh(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 140),
        children: [
          _Header(l10n: l10n),
          const SizedBox(height: 16),
          _MentorshipCard().animate().fadeIn(delay: 40.ms).slideY(begin: 0.1),
          const SizedBox(height: 22),
          _UploadCard(state: upload, onTap: () => _pick(ref), l10n: l10n)
              .animate()
              .fadeIn(delay: 80.ms)
              .slideY(begin: 0.1),
          const SizedBox(height: 16),
          _StudyTools(l10n: l10n)
              .animate()
              .fadeIn(delay: 120.ms)
              .slideY(begin: 0.1),
          const SizedBox(height: 28),
          Row(
            children: [
              Text(
                l10n.t('library'),
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: LiqColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 8),
              if (files.files.isNotEmpty)
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: LiqColors.glassFill,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: LiqColors.glassStroke),
                  ),
                  child: Text(
                    "${files.files.length}",
                    style: GoogleFonts.inter(
                      color: LiqColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              const Spacer(),
              if (files.loading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: LiqColors.accent),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (files.files.isEmpty && !files.loading)
            _EmptyLibrary(l10n: l10n)
          else
            ...files.files.asMap().entries.map((e) {
              final f = e.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _FileTile(
                  file: f,
                  l10n: l10n,
                  onDelete: () =>
                      ref.read(filesProvider.notifier).delete(f.id),
                  onChat: () => context.push('/chat'),
                ).animate(delay: (40 * e.key).ms).fadeIn().slideY(begin: 0.1),
              );
            }),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.l10n});
  final AppL10n l10n;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.t('good_day'),
            style: GoogleFonts.inter(
              color: LiqColors.textTertiary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            l10n.t('your_library'),
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: LiqColors.textPrimary,
              letterSpacing: -1,
            ),
          ),
        ],
      ),
    );
  }
}

class _MentorshipCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: () => _showMentorshipDetails(context),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      tint: LiqColors.auroraTeal.withOpacity(0.1),
      strokeColor: LiqColors.auroraTeal.withOpacity(0.3),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: LiqColors.auroraTeal.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.rocket, color: LiqColors.auroraTeal, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Built for AI Incubator Program",
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                Text(
                  "Tap to view project credits & details",
                  style: GoogleFonts.inter(color: LiqColors.textTertiary, fontSize: 11),
                ),
              ],
            ),
          ),
          const Icon(LucideIcons.chevron_right, color: LiqColors.textTertiary, size: 18),
        ],
      ),
    );
  }

  void _showMentorshipDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: LiqColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(color: LiqColors.glassStroke, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [LiqColors.auroraTeal, LiqColors.auroraViolet]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(LucideIcons.rocket, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      "Project Attribution",
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                "This platform was built by me (Participant) as the Final Project (Option A) for the AI Incubator Mentorship Program to advance to Stage 2.",
                style: GoogleFonts.inter(color: LiqColors.textSecondary, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 12),
              Text(
                "Important Note:",
                style: GoogleFonts.inter(color: LiqColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                "The original concept and idea of \"ILM AI\" (a personal AI learning companion) strictly belongs to AI Incubator Org. I am acting solely as the builder/developer for this 5-week challenge.",
                style: GoogleFonts.inter(color: LiqColors.textSecondary, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 24),
              Text(
                "Official Links:",
                style: GoogleFonts.inter(color: LiqColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              _LinkTile(icon: LucideIcons.globe, label: "AI Incubator Website", url: "https://www.ai-incubator.org/"),
              _LinkTile(icon: LucideIcons.link, label: "Instagram", url: "https://www.instagram.com/ai_incubator_org/"),
              _LinkTile(icon: LucideIcons.link, label: "LinkedIn", url: "https://www.linkedin.com/company/ai-incubator-org"),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({required this.icon, required this.label, required this.url});
  final IconData icon;
  final String label;
  final String url;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: LiqColors.textSecondary, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: GoogleFonts.inter(color: LiqColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
            ),
            const Icon(LucideIcons.external_link, color: LiqColors.textTertiary, size: 16),
          ],
        ),
      ),
    );
  }
}

class _UploadCard extends StatelessWidget {
  const _UploadCard(
      {required this.state, required this.onTap, required this.l10n});
  final UploadState state;
  final VoidCallback onTap;
  final AppL10n l10n;

  @override
  Widget build(BuildContext context) {
    final isLoading = state is UploadInProgress;
    return GlassCard(
      onTap: isLoading ? null : onTap,
      padding: const EdgeInsets.all(20),
      tint: LiqColors.glassFillStrong,
      glow: true,
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                colors: [LiqColors.accentSoft, LiqColors.accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: LiqColors.accent.withOpacity(0.4),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: isLoading
                ? const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            )
                : const Icon(LucideIcons.cloud_upload,
                color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _title(state, l10n),
                  style: GoogleFonts.poppins(
                    color: LiqColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _subtitle(state, l10n),
                  style: GoogleFonts.inter(
                    color: LiqColors.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (!isLoading)
            const Icon(LucideIcons.chevron_right,
                color: LiqColors.textTertiary, size: 22),
        ],
      ),
    );
  }

  String _title(UploadState s, AppL10n l) => switch (s) {
    UploadInProgress(:final filename) =>
        l.tr('processing', {'filename': filename}),
    UploadSuccess(:final filename) =>
        l.tr('saved', {'filename': filename}),
    UploadFailed() => l.t('upload_failed'),
    _ => l.t('upload_material'),
  };

  String _subtitle(UploadState s, AppL10n l) => switch (s) {
    UploadInProgress() => l.t('indexing'),
    UploadSuccess(:final chunksSaved) =>
        l.tr('chunks_indexed', {'n': '$chunksSaved'}),
    UploadFailed(:final message) => message,
    _ => l.t('upload_subtitle'),
  };
}

class _StudyTools extends StatelessWidget {
  const _StudyTools({required this.l10n});
  final AppL10n l10n;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GlassCard(
            onTap: () => context.push('/chat'),
            padding: const EdgeInsets.all(18),
            glow: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: LiqColors.auroraTeal.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(LucideIcons.messages_square, color: LiqColors.auroraTeal, size: 24),
                ),
                const SizedBox(height: 14),
                Text(
                  l10n.t('chat_hero_title'),
                  style: GoogleFonts.poppins(color: LiqColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600, height: 1.2),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: GlassCard(
            onTap: () => context.push('/flashcards'),
            padding: const EdgeInsets.all(18),
            glow: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: LiqColors.auroraViolet.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(LucideIcons.layers, color: LiqColors.auroraViolet, size: 24),
                ),
                const SizedBox(height: 14),
                Text(
                  l10n.t('flashcards_title'),
                  style: GoogleFonts.poppins(color: LiqColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600, height: 1.2),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary({required this.l10n});
  final AppL10n l10n;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      child: Column(
        children: [
          Icon(LucideIcons.book_open, size: 38, color: LiqColors.textTertiary),
          const SizedBox(height: 12),
          Text(
            l10n.t('no_materials'),
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: LiqColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.t('no_materials_sub'),
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: LiqColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _FileTile extends StatelessWidget {
  const _FileTile(
      {required this.file,
        required this.onDelete,
        required this.onChat,
        required this.l10n});
  final KnowledgeFile file;
  final VoidCallback onDelete;
  final VoidCallback onChat;
  final AppL10n l10n;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onChat,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                colors: [
                  LiqColors.auroraTeal.withOpacity(0.4),
                  LiqColors.auroraViolet.withOpacity(0.4),
                ],
              ),
            ),
            child:
            const Icon(LucideIcons.file_text, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.filename,
                  style: GoogleFonts.inter(
                    color: LiqColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(LucideIcons.layers,
                        size: 11, color: LiqColors.textTertiary),
                    const SizedBox(width: 4),
                    Text(
                      l10n.tr('chunks_count', {'n': '${file.chunkCount}'}),
                      style: GoogleFonts.inter(
                          color: LiqColors.textTertiary, fontSize: 11),
                    ),
                    const SizedBox(width: 8),
                    Container(
                        width: 3,
                        height: 3,
                        decoration: const BoxDecoration(
                            color: LiqColors.textMuted,
                            shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text(
                      "${(file.charCount / 1000).toStringAsFixed(1)}k chars",
                      style: GoogleFonts.inter(
                          color: LiqColors.textTertiary, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(LucideIcons.trash_2,
                color: LiqColors.textTertiary, size: 18),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: LiqColors.surface,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                  title: Text(l10n.t('delete_file_title'),
                      style:
                      GoogleFonts.poppins(color: LiqColors.textPrimary)),
                  content: Text(
                    l10n.tr(
                        'delete_file_content', {'filename': file.filename}),
                    style: GoogleFonts.inter(color: LiqColors.textSecondary),
                  ),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(l10n.t('cancel'),
                            style: GoogleFonts.inter(
                                color: LiqColors.textSecondary))),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        onDelete();
                      },
                      child: Text(l10n.t('delete'),
                          style: GoogleFonts.inter(
                              color: LiqColors.danger,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}