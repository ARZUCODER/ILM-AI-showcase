import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../core/theme/liq_colors.dart';
import '../../../core/ui/aurora_background.dart';
import '../../../core/ui/glass_card.dart';
import '../logic/admin_provider.dart';

class AdminLoginPage extends ConsumerStatefulWidget {
  const AdminLoginPage({super.key});

  @override
  ConsumerState<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends ConsumerState<AdminLoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  Future<void> _submit() async {
    final ok = await ref.read(adminProvider.notifier).login(_email.text.trim(), _password.text);
    if (ok && mounted) context.go('/admin/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminProvider);

    ref.listen(adminProvider, (_, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.error!, style: GoogleFonts.inter(color: Colors.white)),
          backgroundColor: LiqColors.danger,
        ));
      }
    });

    return Scaffold(
      backgroundColor: LiqColors.bgDeep,
      body: AuroraBackground(
        palette: const [LiqColors.danger, LiqColors.auroraAmber, LiqColors.auroraViolet],
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: GlassCard(
                glow: true,
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.shield_alert, size: 48, color: LiqColors.danger),
                    const SizedBox(height: 16),
                    Text(
                      "Admin Portal",
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 32),
                    _Field(controller: _email, hint: "Admin Email", icon: LucideIcons.mail),
                    const SizedBox(height: 16),
                    _Field(controller: _password, hint: "Password", icon: LucideIcons.lock, obscure: true),
                    const SizedBox(height: 32),
                    LiqButton(
                      label: "Authenticate",
                      icon: LucideIcons.log_in,
                      loading: state.loading,
                      onPressed: _submit,
                      gradient: const [LiqColors.danger, LiqColors.auroraAmber],
                    ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: 0.1),
            ),
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.controller, required this.hint, required this.icon, this.obscure = false});
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
        style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: LiqColors.textTertiary, size: 18),
          hintText: hint,
          hintStyle: GoogleFonts.inter(color: LiqColors.textMuted),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
        ),
      ),
    );
  }
}