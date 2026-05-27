import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/liq_colors.dart';
import '../../../core/ui/glass_card.dart';
import '../../../core/ui/aurora_background.dart';
import '../../../core/l10n/app_l10n.dart';
import '../logic/auth_provider.dart';

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  bool _isLogin = true;
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final ok = await ref
        .read(authProvider.notifier)
        .login(_email.text.trim(), _password.text, _isLogin);
    if (ok && mounted) context.go('/app');
  }

  Future<void> _submitGoogle() async {
    final ok = await ref.read(authProvider.notifier).loginWithGoogle();
    if (ok && mounted) context.go('/app');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authProvider);
    final l10n = ref.watch(l10nProvider).valueOrNull ?? AppL10n({});
    final locale = ref.watch(localeProvider);

    ref.listen<AsyncValue<bool>>(authProvider, (_, next) {
      next.whenOrNull(error: (e, _) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString(),
                style: GoogleFonts.inter(color: Colors.white)),
            backgroundColor: LiqColors.danger,
            behavior: SnackBarBehavior.floating,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );
      });
    });

    return Scaffold(
      backgroundColor: LiqColors.bgDeep,
      body: AuroraBackground(
        child: SafeArea(
          child: Stack(
            children: [
              // 1-QATLAM: Login formasi (Boshqasining ustiga chiqib ketmasligi uchun birinchi yozildi)
              Center(
                child: SingleChildScrollView(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _Logo()
                            .animate()
                            .fadeIn(duration: 600.ms)
                            .slideY(begin: -0.2),
                        const SizedBox(height: 28),
                        Text(
                          l10n.t('app_name'),
                          style: GoogleFonts.poppins(
                            fontSize: 42,
                            fontWeight: FontWeight.w700,
                            color: LiqColors.textPrimary,
                            letterSpacing: -1.2,
                          ),
                        ).animate().fadeIn(delay: 100.ms),
                        const SizedBox(height: 8),
                        Text(
                          l10n.t('tagline'),
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: LiqColors.textSecondary,
                          ),
                        ).animate().fadeIn(delay: 200.ms),
                        const SizedBox(height: 36),
                        GlassCard(
                          glow: true,
                          padding: const EdgeInsets.all(28),
                          child: Column(
                            children: [
                              _SegmentedToggle(
                                isLogin: _isLogin,
                                signInLabel: l10n.t('sign_in'),
                                signUpLabel: l10n.t('sign_up'),
                                onChanged: (v) => setState(() => _isLogin = v),
                              ),
                              const SizedBox(height: 24),
                              _Field(
                                controller: _email,
                                hint: l10n.t('email'),
                                icon: LucideIcons.mail,
                              ),
                              const SizedBox(height: 14),
                              _Field(
                                controller: _password,
                                hint: l10n.t('password'),
                                icon: LucideIcons.lock,
                                obscure: true,
                              ),
                              const SizedBox(height: 22),
                              LiqButton(
                                label: _isLogin
                                    ? l10n.t('sign_in')
                                    : l10n.t('create_account'),
                                icon: LucideIcons.arrow_right,
                                loading: state is AsyncLoading,
                                onPressed: _submit,
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  const Expanded(
                                      child: Divider(
                                          color: LiqColors.glassStroke,
                                          height: 1)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    child: Text(
                                      l10n.t('or'),
                                      style: GoogleFonts.inter(
                                        color: LiqColors.textTertiary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const Expanded(
                                      child: Divider(
                                          color: LiqColors.glassStroke,
                                          height: 1)),
                                ],
                              ),
                              const SizedBox(height: 14),
                              // Google uchun maxsus yaratilgan rasm oladigan tugma ishlatamiz
                              _GoogleButton(
                                label: l10n.t('continue_with_google'),
                                loading: state is AsyncLoading,
                                onPressed: _submitGoogle,
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.15),
                        const SizedBox(height: 18),
                        _TermsRow(l10n: l10n),
                      ],
                    ),
                  ),
                ),
              ),
              // 2-QATLAM: Til tugmasi (Eng ustki qatlamda turadi va doim bosiladi)
              Positioned(
                top: 16,
                right: 16,
                child: _LanguageDropdown(key: ValueKey(locale), current: locale),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Google kirish uchun maxsus tugma
class _GoogleButton extends StatelessWidget {
  const _GoogleButton({
    required this.label,
    required this.onPressed,
    required this.loading,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(27),
          onTap: loading ? null : onPressed,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(27),
              border: Border.all(color: LiqColors.glassStrokeStrong),
              color: LiqColors.glassFill,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/images/google_logo.png', width: 22, height: 22),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    color: LiqColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
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
      onSelected: (code) {
        if (code != current) {
          ref.read(localeProvider.notifier).setLocale(code);
        }
      },
      color: LiqColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      offset: const Offset(0, 40),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: LiqColors.glassFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: LiqColors.glassStroke),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.globe, color: LiqColors.textSecondary, size: 16),
            const SizedBox(width: 6),
            Text(
              current.toUpperCase(),
              style: GoogleFonts.inter(
                color: LiqColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(LucideIcons.chevron_down, color: LiqColors.textSecondary, size: 14),
          ],
        ),
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
          Text(label, style: GoogleFonts.inter(
            color: current == code ? LiqColors.accentSoft : LiqColors.textPrimary,
            fontWeight: current == code ? FontWeight.w600 : FontWeight.w400,
          )),
          if (current == code)
            const Icon(LucideIcons.check, color: LiqColors.accentSoft, size: 18),
        ],
      ),
    );
  }
}

class _TermsRow extends StatelessWidget {
  const _TermsRow({required this.l10n});
  final AppL10n l10n;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      children: [
        Text(
          '${l10n.t('terms_notice')} ',
          style: GoogleFonts.inter(
              color: LiqColors.textMuted, fontSize: 11),
        ),
        GestureDetector(
          onTap: () => context.go('/terms'),
          child: Text(
            l10n.t('terms_link'),
            style: GoogleFonts.inter(
              color: LiqColors.accentSoft,
              fontSize: 11,
              decoration: TextDecoration.underline,
              decorationColor: LiqColors.accentSoft,
            ),
          ),
        ),
        Text(
          ' ${l10n.t('and')} ',
          style: GoogleFonts.inter(
              color: LiqColors.textMuted, fontSize: 11),
        ),
        GestureDetector(
          onTap: () => context.go('/privacy'),
          child: Text(
            l10n.t('privacy_link'),
            style: GoogleFonts.inter(
              color: LiqColors.accentSoft,
              fontSize: 11,
              decoration: TextDecoration.underline,
              decorationColor: LiqColors.accentSoft,
            ),
          ),
        ),
      ],
    );
  }
}

class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [LiqColors.accentSoft, LiqColors.accent, LiqColors.accentDeep],
        ),
        boxShadow: [
          BoxShadow(
            color: LiqColors.accent.withOpacity(0.55),
            blurRadius: 32,
            spreadRadius: -2,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: const Icon(LucideIcons.sparkles, color: Colors.white, size: 42),
    );
  }
}

class _SegmentedToggle extends StatelessWidget {
  const _SegmentedToggle({
    required this.isLogin,
    required this.signInLabel,
    required this.signUpLabel,
    required this.onChanged,
  });
  final bool isLogin;
  final String signInLabel, signUpLabel;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: LiqColors.glassFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: LiqColors.glassStroke),
      ),
      child: Row(
        children: [
          _seg(signInLabel, isLogin, () => onChanged(true)),
          _seg(signUpLabel, !isLogin, () => onChanged(false)),
        ],
      ),
    );
  }

  Widget _seg(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: active ? Colors.white : Colors.transparent,
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: active ? LiqColors.bgDark : LiqColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: LiqColors.glassFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LiqColors.glassStroke),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: GoogleFonts.inter(color: LiqColors.textPrimary, fontSize: 15),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: LiqColors.textTertiary, size: 18),
          hintText: hint,
          hintStyle:
          GoogleFonts.inter(color: LiqColors.textMuted, fontSize: 15),
          border: InputBorder.none,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
        ),
      ),
    );
  }
}