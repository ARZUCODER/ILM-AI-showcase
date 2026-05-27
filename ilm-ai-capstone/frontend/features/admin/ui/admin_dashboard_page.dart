import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/liq_colors.dart';
import '../../../core/ui/glass_card.dart';
import '../logic/admin_provider.dart';

class AdminDashboardPage extends ConsumerStatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  ConsumerState<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends ConsumerState<AdminDashboardPage> {
  int _tab = 0;
  Timer? _timer;
  String? _selectedUser;

  @override
  void initState() {
    super.initState();
    ref.read(adminProvider.notifier).fetchDashboard();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      ref.read(adminProvider.notifier).fetchDashboard();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) context.go('/admin');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminProvider);

    return Scaffold(
      backgroundColor: LiqColors.bgDeep,
      body: Row(
        children: [
          _Sidebar(
            currentTab: _tab,
            onTabChanged: (i) => setState(() => _tab = i),
            onLogout: _logout,
          ),
          Expanded(
            child: Column(
              children: [
                _Header(),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _buildContent(state),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(AdminState state) {
    if (_tab == 0) return _DashboardView(state: state, key: const ValueKey('d'));
    if (_tab == 1) return _ChatsView(
        state: state,
        selectedUser: _selectedUser,
        onUserSelected: (u) => setState(() => _selectedUser = u),
        key: const ValueKey('c')
    );
    if (_tab == 2) return _UsersView(state: state, key: const ValueKey('u'));
    if (_tab == 3) return _PromosView(state: state, key: const ValueKey('p'));
    return const SizedBox.shrink();
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.currentTab, required this.onTabChanged, required this.onLogout});
  final int currentTab;
  final ValueChanged<int> onTabChanged;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: LiqColors.bgDark,
        border: Border(right: BorderSide(color: LiqColors.glassStroke)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [LiqColors.accentSoft, LiqColors.accent]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(LucideIcons.shield_check, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Ilm AI", style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                    Text("Observability", style: GoogleFonts.inter(color: LiqColors.accentSoft, fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _NavItem(icon: LucideIcons.layout_dashboard, label: "Dashboard", active: currentTab == 0, onTap: () => onTabChanged(0)),
                _NavItem(icon: LucideIcons.message_square, label: "Live Chats & RAG", active: currentTab == 1, onTap: () => onTabChanged(1)),
                _NavItem(icon: LucideIcons.users, label: "Users", active: currentTab == 2, onTap: () => onTabChanged(2)),
                _NavItem(icon: LucideIcons.ticket, label: "Promo Codes", active: currentTab == 3, onTap: () => onTabChanged(3)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: GestureDetector(
              onTap: onLogout,
              child: Row(
                children: [
                  const Icon(LucideIcons.log_out, color: LiqColors.textTertiary, size: 20),
                  const SizedBox(width: 12),
                  Text("Logout", style: GoogleFonts.inter(color: LiqColors.textTertiary, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label, required this.active, required this.onTap});
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: active ? LiqColors.accent.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? LiqColors.accent.withOpacity(0.3) : Colors.transparent),
        ),
        child: Row(
          children: [
            Icon(icon, color: active ? LiqColors.accentSoft : LiqColors.textTertiary, size: 18),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.inter(
                color: active ? Colors.white : LiqColors.textSecondary,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      decoration: const BoxDecoration(
        color: LiqColors.bgDeep,
        border: Border(bottom: BorderSide(color: LiqColors.glassStroke)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("System Overview", style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
              Text("Real-time metrics and RAG traces", style: GoogleFonts.inter(color: LiqColors.textTertiary, fontSize: 13)),
            ],
          ),
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(color: LiqColors.accent, shape: BoxShape.circle),
              ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1.seconds, color: Colors.white),
              const SizedBox(width: 8),
              Text("Live Sync Active", style: GoogleFonts.inter(color: LiqColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView({super.key, required this.state});
  final AdminState state;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        Row(
          children: [
            Expanded(child: _StatCard(title: "Total Users", value: "${state.totalUsers}", icon: LucideIcons.users, color: LiqColors.auroraTeal)),
            const SizedBox(width: 24),
            Expanded(child: _StatCard(title: "Vector Chunks", value: "${state.totalChunks}", icon: LucideIcons.database, color: LiqColors.auroraViolet)),
            const SizedBox(width: 24),
            Expanded(child: _StatCard(title: "Conversations", value: "${state.totalChats}", icon: LucideIcons.messages_square, color: LiqColors.accent)),
            const SizedBox(width: 24),
            Expanded(child: _StatCard(title: "Total Tokens", value: "${state.totalTokens}", icon: LucideIcons.cpu, color: LiqColors.auroraAmber)),
          ],
        ),
        const SizedBox(height: 32),
        GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("RAG Strict Grounding Info", style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Text(
                "Retrieval-Augmented Generation (RAG) is configured with a strict Cosine Similarity threshold. If the distance is > 0.70, it refuses to answer to prevent hallucinations. You can trace these decisions in the 'Live Chats & RAG' tab by viewing the specific similarity scores for each retrieved chunk.",
                style: GoogleFonts.inter(color: LiqColors.textSecondary, height: 1.6),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.value, required this.icon, required this.color});
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title.toUpperCase(), style: GoogleFonts.inter(color: LiqColors.textTertiary, fontSize: 12, fontWeight: FontWeight.w700)),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          Text(value, style: GoogleFonts.poppins(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _ChatsView extends StatelessWidget {
  const _ChatsView({super.key, required this.state, required this.selectedUser, required this.onUserSelected});
  final AdminState state;
  final String? selectedUser;
  final ValueChanged<String?> onUserSelected;

  @override
  Widget build(BuildContext context) {
    final filtered = selectedUser == null ? state.chats : state.chats.where((c) => c['email'] == selectedUser).toList();
    final uniqueUsers = state.chats.map((c) => c['email'].toString()).toSet().toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 32, 32, 16),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _UserChip(label: "All Users", active: selectedUser == null, onTap: () => onUserSelected(null)),
              for (final u in uniqueUsers)
                _UserChip(label: u, active: selectedUser == u, onTap: () => onUserSelected(u)),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            itemCount: filtered.length,
            itemBuilder: (ctx, i) {
              final c = filtered[i];
              final isUser = c['is_user'] == true;
              return Container(
                margin: const EdgeInsets.only(bottom: 24),
                alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.5),
                  child: Column(
                    crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(c['email'], style: GoogleFonts.inter(color: LiqColors.textTertiary, fontSize: 11)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isUser ? Colors.blue.withOpacity(0.2) : LiqColors.accent.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isUser ? "USER" : "AI",
                              style: GoogleFonts.inter(color: isUser ? Colors.blue : LiqColors.accentSoft, fontSize: 10, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isUser ? LiqColors.surfaceElevated : LiqColors.glassFill,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: LiqColors.glassStroke),
                        ),
                        child: isUser
                            ? Text(c['message'], style: GoogleFonts.inter(color: Colors.white, fontSize: 14, height: 1.5))
                            : MarkdownBody(
                          data: c['message'],
                          styleSheet: MarkdownStyleSheet(
                            p: GoogleFonts.inter(color: Colors.white, fontSize: 14, height: 1.5),
                            strong: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700),
                            listBullet: GoogleFonts.inter(color: LiqColors.accentSoft, fontSize: 14, fontWeight: FontWeight.bold),
                            code: GoogleFonts.jetBrainsMono(color: LiqColors.accentSoft, backgroundColor: Colors.transparent, fontSize: 13),
                            codeblockDecoration: BoxDecoration(color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      if (!isUser && c['rag_info'] != null && c['rag_info']['matches'] != null && (c['rag_info']['matches'] as List).isNotEmpty) ...[
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => _showRagDetails(context, c['rag_info'], c['total_tokens'] ?? 0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: LiqColors.accent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: LiqColors.accent.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(LucideIcons.search, color: LiqColors.accentSoft, size: 14),
                                const SizedBox(width: 6),
                                Text("View RAG Trace & Tokens", style: GoogleFonts.inter(color: LiqColors.accentSoft, fontSize: 12, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showRagDetails(BuildContext context, dynamic ragInfo, int tokens) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassCard(
          glow: true,
          padding: const EdgeInsets.all(32),
          width: 600,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("RAG Trace Details", style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(LucideIcons.x, color: Colors.white)),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: LiqColors.surfaceElevated, borderRadius: BorderRadius.circular(8)),
                child: Text("Tokens Used: $tokens", style: GoogleFonts.inter(color: LiqColors.auroraAmber, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 16),
              Text("Vector Query:", style: GoogleFonts.inter(color: LiqColors.textTertiary, fontSize: 12)),
              const SizedBox(height: 4),
              Text('"${ragInfo['query']}"', style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontStyle: FontStyle.italic)),
              const SizedBox(height: 24),
              Text("Retrieved Chunks:", style: GoogleFonts.inter(color: LiqColors.textTertiary, fontSize: 12)),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: (ragInfo['matches'] as List).length,
                  itemBuilder: (c, i) {
                    final m = ragInfo['matches'][i];
                    final sim = (m['similarity'] as num).toDouble();
                    final pct = (sim * 100).round();
                    final color = pct > 65 ? LiqColors.accent : (pct > 40 ? LiqColors.auroraAmber : LiqColors.danger);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: LiqColors.bgDeep,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: LiqColors.glassStroke),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("[Chunk ${i+1}] ${m['filename']}", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                              Text("Sim: ${sim.toStringAsFixed(3)}", style: TextStyle(fontFamily: 'monospace', color: color, fontWeight: FontWeight.w700)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(value: sim, backgroundColor: LiqColors.surface, color: color, borderRadius: BorderRadius.circular(4)),
                          const SizedBox(height: 12),
                          Text(
                            m['content'].toString().length > 200 ? m['content'].toString().substring(0, 200) + '...' : m['content'],
                            style: GoogleFonts.inter(color: LiqColors.textSecondary, fontSize: 12, height: 1.5),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UsersView extends StatelessWidget {
  const _UsersView({super.key, required this.state});
  final AdminState state;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        GlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Text("Registered Accounts", style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                color: LiqColors.surfaceElevated,
                child: Row(
                  children: [
                    Expanded(flex: 2, child: Text("EMAIL", style: GoogleFonts.inter(color: LiqColors.textTertiary, fontSize: 11, fontWeight: FontWeight.w700))),
                    Expanded(flex: 1, child: Text("ROLE", style: GoogleFonts.inter(color: LiqColors.textTertiary, fontSize: 11, fontWeight: FontWeight.w700))),
                    Expanded(flex: 1, child: Text("AUTH", style: GoogleFonts.inter(color: LiqColors.textTertiary, fontSize: 11, fontWeight: FontWeight.w700))),
                    Expanded(flex: 3, child: Text("GOAL", style: GoogleFonts.inter(color: LiqColors.textTertiary, fontSize: 11, fontWeight: FontWeight.w700))),
                  ],
                ),
              ),
              for (final u in state.users)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: LiqColors.glassStroke)),
                  ),
                  child: Row(
                    children: [
                      Expanded(flex: 2, child: Text(u['email'], style: GoogleFonts.inter(color: Colors.white, fontSize: 14))),
                      Expanded(flex: 1, child: Text(u['role'].toString().toUpperCase(), style: GoogleFonts.inter(color: u['role'] == 'admin' ? LiqColors.danger : LiqColors.accentSoft, fontSize: 12, fontWeight: FontWeight.w700))),
                      Expanded(flex: 1, child: Text(u['auth'], style: GoogleFonts.inter(color: LiqColors.textSecondary, fontSize: 13))),
                      Expanded(flex: 3, child: Text(u['goal'] == "" ? "—" : u['goal'], style: GoogleFonts.inter(color: LiqColors.textSecondary, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PromosView extends ConsumerStatefulWidget {
  const _PromosView({super.key, required this.state});
  final AdminState state;

  @override
  ConsumerState<_PromosView> createState() => _PromosViewState();
}

class _PromosViewState extends ConsumerState<_PromosView> {
  final _codeCtrl = TextEditingController();
  final _discCtrl = TextEditingController(text: '100');
  final _maxCtrl = TextEditingController(text: '100');
  String _tier = 'premium';
  DateTime _date = DateTime.now().add(const Duration(days: 30));

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Create Promo Code", style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Code (e.g. SUMMER2026)", style: GoogleFonts.inter(color: LiqColors.textTertiary, fontSize: 12)),
                        const SizedBox(height: 6),
                        _buildInput(_codeCtrl, false),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Tier", style: GoogleFonts.inter(color: LiqColors.textTertiary, fontSize: 12)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(color: LiqColors.glassFill, borderRadius: BorderRadius.circular(12), border: Border.all(color: LiqColors.glassStroke)),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _tier,
                              dropdownColor: LiqColors.surface,
                              isExpanded: true,
                              style: GoogleFonts.inter(color: Colors.white),
                              items: const [
                                DropdownMenuItem(value: 'premium', child: Text('Premium')),
                                DropdownMenuItem(value: 'free', child: Text('Free')),
                              ],
                              onChanged: (v) => setState(() => _tier = v!),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Discount %", style: GoogleFonts.inter(color: LiqColors.textTertiary, fontSize: 12)),
                        const SizedBox(height: 6),
                        _buildInput(_discCtrl, true),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Max Uses", style: GoogleFonts.inter(color: LiqColors.textTertiary, fontSize: 12)),
                        const SizedBox(height: 6),
                        _buildInput(_maxCtrl, true),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Valid Until", style: GoogleFonts.inter(color: LiqColors.textTertiary, fontSize: 12)),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: _date,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365*5)),
                            );
                            if (d != null) setState(() => _date = d);
                          },
                          child: Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(color: LiqColors.glassFill, borderRadius: BorderRadius.circular(12), border: Border.all(color: LiqColors.glassStroke)),
                            alignment: Alignment.centerLeft,
                            child: Text("${_date.year}-${_date.month.toString().padLeft(2,'0')}-${_date.day.toString().padLeft(2,'0')}", style: GoogleFonts.inter(color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    height: 48,
                    child: LiqButton(
                      label: "Create",
                      icon: LucideIcons.plus,
                      height: 48,
                      onPressed: () async {
                        if (_codeCtrl.text.trim().isEmpty) return;
                        final ok = await ref.read(adminProvider.notifier).createPromo({
                          "code": _codeCtrl.text.trim(),
                          "discount_percent": int.tryParse(_discCtrl.text) ?? 100,
                          "max_uses": int.tryParse(_maxCtrl.text) ?? 100,
                          "tier": _tier,
                          "valid_until": "${_date.year}-${_date.month.toString().padLeft(2,'0')}-${_date.day.toString().padLeft(2,'0')}"
                        });
                        if (ok && mounted) {
                          _codeCtrl.clear();
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: LiqColors.success, content: Text("Promo Code Created!")));
                        }
                      },
                    ),
                  ),
                ],
              ),
              if (widget.state.error != null) ...[
                const SizedBox(height: 12),
                Text(widget.state.error!, style: GoogleFonts.inter(color: LiqColors.danger, fontSize: 13)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 32),
        GlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Text("Existing Promo Codes", style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                color: LiqColors.surfaceElevated,
                child: Row(
                  children: [
                    Expanded(flex: 2, child: Text("CODE", style: GoogleFonts.inter(color: LiqColors.textTertiary, fontSize: 11, fontWeight: FontWeight.w700))),
                    Expanded(flex: 1, child: Text("TIER", style: GoogleFonts.inter(color: LiqColors.textTertiary, fontSize: 11, fontWeight: FontWeight.w700))),
                    Expanded(flex: 1, child: Text("DISC %", style: GoogleFonts.inter(color: LiqColors.textTertiary, fontSize: 11, fontWeight: FontWeight.w700))),
                    Expanded(flex: 1, child: Text("USAGE", style: GoogleFonts.inter(color: LiqColors.textTertiary, fontSize: 11, fontWeight: FontWeight.w700))),
                    Expanded(flex: 2, child: Text("VALID UNTIL", style: GoogleFonts.inter(color: LiqColors.textTertiary, fontSize: 11, fontWeight: FontWeight.w700))),
                    Expanded(flex: 1, child: Text("STATUS", style: GoogleFonts.inter(color: LiqColors.textTertiary, fontSize: 11, fontWeight: FontWeight.w700))),
                    Expanded(flex: 1, child: Text("ACTION", style: GoogleFonts.inter(color: LiqColors.textTertiary, fontSize: 11, fontWeight: FontWeight.w700), textAlign: TextAlign.right)),
                  ],
                ),
              ),
              for (final p in widget.state.promos)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: LiqColors.glassStroke)),
                  ),
                  child: Row(
                    children: [
                      Expanded(flex: 2, child: Text(p['code'], style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700))),
                      Expanded(flex: 1, child: Text(p['tier'].toString().toUpperCase(), style: GoogleFonts.inter(color: p['tier'] == 'premium' ? LiqColors.auroraAmber : LiqColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w700))),
                      Expanded(flex: 1, child: Text("${p['discount_percent']}%", style: GoogleFonts.inter(color: LiqColors.textSecondary, fontSize: 13))),
                      Expanded(flex: 1, child: Text("${p['used_count']} / ${p['max_uses']}", style: GoogleFonts.inter(color: LiqColors.textSecondary, fontSize: 13))),
                      Expanded(flex: 2, child: Text(p['valid_until'].toString().substring(0, 10), style: GoogleFonts.inter(color: LiqColors.textSecondary, fontSize: 13))),
                      Expanded(flex: 1, child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: p['is_active'] ? LiqColors.success.withOpacity(0.1) : LiqColors.danger.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(p['is_active'] ? 'ACTIVE' : 'INACTIVE', style: GoogleFonts.inter(color: p['is_active'] ? LiqColors.success : LiqColors.danger, fontSize: 10, fontWeight: FontWeight.w700)),
                      )),
                      Expanded(
                        flex: 1,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: () => ref.read(adminProvider.notifier).togglePromo(p['code'], !p['is_active']),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                border: Border.all(color: p['is_active'] ? LiqColors.danger : LiqColors.success),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(p['is_active'] ? 'Disable' : 'Enable', style: GoogleFonts.inter(color: p['is_active'] ? LiqColors.danger : LiqColors.success, fontSize: 11, fontWeight: FontWeight.w600)),
                            ),
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
    );
  }

  Widget _buildInput(TextEditingController ctrl, bool isNumber) {
    return Container(
      height: 48,
      decoration: BoxDecoration(color: LiqColors.glassFill, borderRadius: BorderRadius.circular(12), border: Border.all(color: LiqColors.glassStroke)),
      child: TextField(
        controller: ctrl,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
        decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14)),
      ),
    );
  }
}

class _UserChip extends StatelessWidget {
  const _UserChip({required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? LiqColors.accent.withOpacity(0.2) : LiqColors.glassFill,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? LiqColors.accent : LiqColors.glassStroke),
        ),
        child: Text(label, style: GoogleFonts.inter(color: active ? LiqColors.accentSoft : LiqColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
      ),
    );
  }
}