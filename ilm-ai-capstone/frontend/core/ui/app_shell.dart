import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../features/home/ui/home_page.dart';
import '../../features/planner/ui/plan_page.dart';
import '../../features/profile/ui/profile_page.dart';
import '../l10n/app_l10n.dart';
import '../theme/liq_colors.dart';
import 'aurora_background.dart';

// Boshqa sahifalardan (masalan Home'dan) boshqarish uchun global tab state
final currentTabProvider = StateProvider<int>((ref) => 0);

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  static const _pages = [HomePage(), PlanPage(), ProfilePage()];

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(currentTabProvider);
    final l10n = ref.watch(l10nProvider).valueOrNull ?? AppL10n({});

    final tabs = [
      _Tab(icon: LucideIcons.library, label: l10n.t('tab_library')),
      _Tab(icon: LucideIcons.calendar_range, label: l10n.t('tab_plan')),
      _Tab(icon: LucideIcons.user, label: l10n.t('tab_profile')),
    ];

    return Scaffold(
      backgroundColor: LiqColors.bgDeep,
      extendBody: true,
      body: AuroraBackground(
        child: SafeArea(
          bottom: false,
          child: IndexedStack(index: currentIndex, children: _pages),
        ),
      ),
      bottomNavigationBar: _LiquidNavBar(
        items: tabs,
        index: currentIndex,
        onChanged: (i) => ref.read(currentTabProvider.notifier).state = i,
      ),
    );
  }
}

class _Tab {
  const _Tab({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

class _LiquidNavBar extends StatelessWidget {
  const _LiquidNavBar({required this.items, required this.index, required this.onChanged});
  final List<_Tab> items;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                color: LiqColors.glassFill,
                border: Border.all(color: LiqColors.glassStroke),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 32, offset: const Offset(0, 16)),
                ],
              ),
              child: Row(
                children: [
                  for (var i = 0; i < items.length; i++)
                    Expanded(
                      child: _NavItem(
                        tab: items[i],
                        active: i == index,
                        onTap: () => onChanged(i),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.tab, required this.active, required this.onTap});
  final _Tab tab;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 10),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: active
              ? const LinearGradient(colors: [LiqColors.accentSoft, LiqColors.accent])
              : null,
          boxShadow: active
              ? [BoxShadow(color: LiqColors.accent.withOpacity(0.45), blurRadius: 18, offset: const Offset(0, 4))]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              tab.icon,
              color: active ? Colors.white : LiqColors.textTertiary,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              tab.label,
              style: GoogleFonts.inter(
                color: active ? Colors.white : LiqColors.textTertiary,
                fontSize: 11,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}