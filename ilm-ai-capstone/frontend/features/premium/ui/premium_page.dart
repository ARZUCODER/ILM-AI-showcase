import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/l10n/app_l10n.dart';
import '../../../core/theme/liq_colors.dart';
import '../../../core/ui/glass_card.dart';
import '../logic/premium_provider.dart';

class PremiumPage extends ConsumerStatefulWidget {
  const PremiumPage({super.key});

  @override
  ConsumerState<PremiumPage> createState() => _PremiumPageState();
}

class _PremiumPageState extends ConsumerState<PremiumPage> {
  final _codeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  // To'lov linklarini to'g'ridan-to'g'ri Flutter'da yaratamiz (Backend xatosi bermasligi uchun)
  Future<void> _pay(String provider) async {
    setState(() => _isLoading = true);

    final userEmail = FirebaseAuth.instance.currentUser?.email ?? 'foydalanuvchi';
    const amount = 49000; // 49,000 so'm
    String url = '';

    if (provider == 'click') {
      // Click URL
      url = 'https://my.click.uz/services/pay?service_id=12345&merchant_id=12345&amount=$amount&transaction_param=$userEmail';
    } else if (provider == 'payme') {
      // Payme URL (tiyinda hisoblanadi va base64 formatda jo'natiladi)
      final amountTiyin = amount * 100;
      final rawStr = 'm=5f3a123456789;ac.account=$userEmail;a=$amountTiyin';
      final encoded = base64.encode(utf8.encode(rawStr));
      url = 'https://checkout.paycom.uz/$encoded';
    }

    setState(() => _isLoading = false);

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Ilovani ochib bo'lmadi", style: GoogleFonts.inter())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final premium = ref.watch(premiumProvider);
    final l10n = ref.watch(l10nProvider).valueOrNull ?? AppL10n({});

    ref.listen<PremiumState>(premiumProvider, (prev, next) {
      if (next.success && (prev == null || !prev.success)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: LiqColors.success,
            behavior: SnackBarBehavior.floating,
            content: Text(next.message ?? 'Premium unlocked!',
                style: GoogleFonts.inter(color: Colors.white)),
          ),
        );
      }
    });

    final benefits = [
      (LucideIcons.file_text, _benefit(l10n, 'Unlimited document uploads', 'Cheksiz hujjat yuklash', 'Безлимитная загрузка документов')),
      (LucideIcons.messages_square, _benefit(l10n, 'Unlimited AI chat', 'Cheksiz AI suhbat', 'Безлимитный ИИ-чат')),
      (LucideIcons.layers, _benefit(l10n, 'Unlimited flashcards', 'Cheksiz kartochkalar', 'Безлимитные карточки')),
      (LucideIcons.calendar_range, _benefit(l10n, '30-day study plans', '30 kunlik o\'quv rejalari', 'Планы обучения на 30 дней')),
    ];

    return Scaffold(
      backgroundColor: LiqColors.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: LiqColors.textPrimary),
        title: Text(l10n.t('upgrade_title'),
            style: GoogleFonts.poppins(color: LiqColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      // Bitta ekranga sig'dirish uchun paddinglar qisqartirildi
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Asosiy Banner (Hero)
            GlassCard(
              glow: true,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [LiqColors.auroraAmber, Color(0xFFEAB308)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Icon(LucideIcons.crown, color: Colors.white, size: 28),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'ILM AI Premium',
                    style: GoogleFonts.poppins(color: LiqColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    premium.isPremium
                        ? _benefit(l10n, 'You are a Premium member', 'Siz Premium foydalanuvchisiz', 'Вы Premium-пользователь')
                        : _benefit(l10n, 'Unlock powerful features', 'Barcha imkoniyatlarni oching', 'Откройте все возможности'),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(color: LiqColors.textTertiary, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Imtiyozlar Ro'yxati
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  for (var i = 0; i < benefits.length; i++) ...[
                    Row(
                      children: [
                        Icon(benefits[i].$1, color: LiqColors.accent, size: 18),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            benefits[i].$2,
                            style: GoogleFonts.inter(color: LiqColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ),
                        const Icon(LucideIcons.check, color: LiqColors.success, size: 16),
                      ],
                    ),
                    if (i < benefits.length - 1)
                      const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(color: LiqColors.glassStroke, height: 1)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (!premium.isPremium) ...[
              // 3. To'lov tizimlari (Click, Payme)
              Text(
                _benefit(l10n, 'Choose Payment Method', 'To\'lov tizimini tanlang', 'Выберите способ оплаты'),
                style: GoogleFonts.poppins(color: LiqColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _isLoading ? null : () => _pay('click'),
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0073FF).withOpacity(0.15),
                          border: Border.all(color: const Color(0xFF0073FF).withOpacity(0.4)),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset('assets/images/click.png', width: 20, height: 20,
                              errorBuilder: (_, __, ___) => const Icon(Icons.payment, color: Color(0xFF0073FF), size: 18),
                            ),
                            const SizedBox(width: 8),
                            Text("Click", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: _isLoading ? null : () => _pay('payme'),
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFF33C7A5).withOpacity(0.15),
                          border: Border.all(color: const Color(0xFF33C7A5).withOpacity(0.4)),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset('assets/images/payme.png', width: 20, height: 20,
                              errorBuilder: (_, __, ___) => const Icon(Icons.account_balance_wallet, color: Color(0xFF33C7A5), size: 18),
                            ),
                            const SizedBox(width: 8),
                            Text("Payme", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              Center(
                child: Text(
                  _benefit(l10n, 'OR', 'YOKI', 'ИЛИ'),
                  style: GoogleFonts.inter(color: LiqColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1),
                ),
              ),
              const SizedBox(height: 16),

              // 4. Promokod kiritish (Joy tejash uchun Yonma-yon qilingan)
              Text(
                _benefit(l10n, 'Have a promo code?', 'Promokodingiz bormi?', 'Есть промокод?'),
                style: GoogleFonts.poppins(color: LiqColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _codeController,
                      textCapitalization: TextCapitalization.characters,
                      style: GoogleFonts.inter(color: LiqColors.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'PREMIUM2026',
                        hintStyle: GoogleFonts.inter(color: LiqColors.textMuted, fontSize: 14),
                        filled: true,
                        fillColor: LiqColors.glassFill,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: LiqColors.glassStroke),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: LiqColors.accent),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 100,
                    child: LiqButton(
                      label: l10n.t('upgrade_cta').length > 8 ? "Yuborish" : l10n.t('upgrade_cta'),
                      height: 48,
                      loading: premium.loading,
                      onPressed: () async {
                        FocusScope.of(context).unfocus();
                        final ok = await ref.read(premiumProvider.notifier).applyPromoCode(_codeController.text);
                        if (ok && context.mounted) {
                          await Future.delayed(const Duration(milliseconds: 600));
                          if (context.mounted) Navigator.of(context).maybePop();
                        }
                      },
                    ),
                  ),
                ],
              ),
              if (premium.error != null) ...[
                const SizedBox(height: 8),
                Text(premium.error!, style: GoogleFonts.inter(color: LiqColors.danger, fontSize: 12)),
              ],
            ],
          ],
        ),
      ),
    );
  }

  String _benefit(AppL10n l10n, String en, String uz, String ru) {
    final code = ref.read(localeProvider);
    switch (code) {
      case 'uz': return uz;
      case 'ru': return ru;
      default: return en;
    }
  }
}