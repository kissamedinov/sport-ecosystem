import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../matches/providers/match_provider.dart';
import 'package:mobile/core/theme/premium_theme.dart';
import '../../children/presentation/screens/child_list_screen.dart';
import '../../children/providers/child_provider.dart';
import '../../notifications/providers/notification_provider.dart';
import '../../notifications/presentation/screens/notification_screen.dart';
import 'parent_coach_notes_screen.dart';
import 'parent_academy_info_screen.dart';
import 'parent_attendance_screen.dart';
import 'parent_payments_screen.dart';

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChildProvider>().fetchChildren();
      context.read<MatchProvider>().fetchMatches();
      context.read<NotificationProvider>().fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final firstName = (user?.name ?? 'auth.role_parent'.tr()).split(' ').first;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: PremiumTheme.surfaceBase(context),
      body: Consumer2<ChildProvider, MatchProvider>(
        builder: (context, childProvider, matchProvider, _) {
          final kids = childProvider.children.length;
          final matches = matchProvider.matches.length;
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(firstName, isDark, context)),
              SliverToBoxAdapter(child: _buildStatsRow(kids, matches)),
              SliverToBoxAdapter(child: _buildManageCard(context)),
              SliverToBoxAdapter(child: _buildSectionLabel('profile.parent_tools'.tr())),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(20, 12, 20,
                    MediaQuery.of(context).padding.bottom + 90),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.3,
                  ),
                  delegate: SliverChildListDelegate([
                    _buildToolCard(
                      context: context,
                      icon: Icons.chat_bubble_outline_rounded,
                      action: 'parent.read'.tr(),
                      label: 'profile.coach_notes'.tr(),
                      tag: 'MSG',
                      color: PremiumTheme.electricBlue,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const ParentCoachNotesScreen())),
                    ),
                    _buildToolCard(
                      context: context,
                      icon: Icons.school_outlined,
                      action: 'parent.view'.tr(),
                      label: 'profile.academy_info'.tr(),
                      tag: 'INFO',
                      color: const Color(0xFFFFC107),
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const ParentAcademyInfoScreen())),
                    ),
                    _buildToolCard(
                      context: context,
                      icon: Icons.playlist_add_check_rounded,
                      action: 'parent.check'.tr(),
                      label: 'profile.attendance'.tr(),
                      tag: 'TRACK',
                      color: PremiumTheme.neonGreen,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const ParentAttendanceScreen())),
                    ),
                    _buildToolCard(
                      context: context,
                      icon: Icons.account_balance_wallet_outlined,
                      action: 'parent.pay'.tr(),
                      label: 'profile.payments'.tr(),
                      tag: 'WALLET',
                      color: const Color(0xFFB490D0),
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const ParentPaymentsScreen())),
                    ),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── HEADER ──────────────────────────────────────────────────────────────────

  Widget _buildHeader(String name, bool isDark, BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [const Color(0xFF0D2118), const Color(0xFF0A0E12)]
              : [const Color(0xFFE8F5E9), const Color(0xFFF5F5F5)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'profile.hello'.tr(namedArgs: {'name': name}),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(children: [
                      Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(
                          color: PremiumTheme.neonGreen,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: PremiumTheme.neonGreen.withValues(alpha: 0.5), blurRadius: 6)],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'profile.parent_guardian'.tr(),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
              Consumer<NotificationProvider>(
                builder: (context, notifProvider, _) => GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const NotificationScreen())),
                  child: Stack(children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08)),
                      ),
                      child: Icon(Icons.notifications_none_rounded,
                          color: Theme.of(context).colorScheme.onSurface, size: 20),
                    ),
                    if (notifProvider.unreadCount > 0)
                      Positioned(
                        right: 4, top: 4,
                        child: Container(
                          width: 14, height: 14,
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          alignment: Alignment.center,
                          child: Text('${notifProvider.unreadCount}',
                              style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                        ),
                      ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── STATS ROW ────────────────────────────────────────────────────────────────

  Widget _buildStatsRow(int kids, int matches) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(children: [
        Expanded(child: _buildStatCard(
          icon: Icons.child_care_rounded,
          value: '$kids',
          label: 'profile.linked_kids'.tr(),
          tag: 'nav.family'.tr(),
          accent: PremiumTheme.neonGreen,
        )),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard(
          icon: Icons.sports_soccer_rounded,
          value: '$matches',
          label: 'profile.this_week'.tr(),
          tag: 'nav.matches'.tr(),
          accent: PremiumTheme.electricBlue,
        )),
      ]),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required String tag,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.18), width: 1.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accent, size: 16),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(tag,
                style: TextStyle(color: accent, fontSize: 8, letterSpacing: 0.8, fontWeight: FontWeight.w800)),
          ),
        ]),
        const SizedBox(height: 14),
        Text(value,
            style: TextStyle(color: accent, fontSize: 32, fontWeight: FontWeight.w900, height: 1.0)),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 10, letterSpacing: 0.8, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  // ── MANAGE CARD ──────────────────────────────────────────────────────────────

  Widget _buildManageCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ChildListScreen()));
        },
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                PremiumTheme.neonGreen.withValues(alpha: 0.12),
                PremiumTheme.electricBlue.withValues(alpha: 0.06),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: PremiumTheme.neonGreen.withValues(alpha: 0.25)),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: PremiumTheme.neonGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.people_alt_rounded, color: PremiumTheme.neonGreen, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('parent.manage_children'.tr(),
                  style: const TextStyle(
                      color: PremiumTheme.neonGreen,
                      fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5)),
              const SizedBox(height: 3),
              Text('parent.manage_children_desc'.tr(),
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 11)),
            ])),
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: PremiumTheme.neonGreen.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_forward_ios_rounded,
                  color: PremiumTheme.neonGreen, size: 14),
            ),
          ]),
        ),
      ),
    );
  }

  // ── SECTION LABEL ────────────────────────────────────────────────────────────

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      child: Row(children: [
        Container(
          width: 3, height: 14,
          decoration: BoxDecoration(
              color: PremiumTheme.neonGreen, borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(width: 10),
        Text(text,
            style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w900,
              color: Theme.of(context).colorScheme.onSurfaceVariant, letterSpacing: 2)),
      ]),
    );
  }

  // ── TOOL CARD ────────────────────────────────────────────────────────────────

  Widget _buildToolCard({
    required BuildContext context,
    required IconData icon,
    required String action,
    required String label,
    required String tag,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: PremiumTheme.surfaceCard(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: color.withValues(alpha: 0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
          // Top: icon + tag
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 15),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(tag,
                  style: TextStyle(color: color, fontSize: 8,
                      letterSpacing: 0.6, fontWeight: FontWeight.w800)),
            ),
          ]),
          // Bottom: label title + action arrow row
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 12, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Row(children: [
              Text(action,
                  style: TextStyle(
                      color: color, fontSize: 11,
                      fontWeight: FontWeight.w700, letterSpacing: 0.4)),
              const SizedBox(width: 4),
              Icon(Icons.arrow_forward_rounded, color: color.withValues(alpha: 0.7), size: 12),
            ]),
          ]),
        ]),
      ),
    );
  }

}

class TemporaryScreen extends StatelessWidget {
  final String title;
  const TemporaryScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PremiumTheme.surfaceBase(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(title, style: const TextStyle(letterSpacing: 1.5, fontSize: 14, fontWeight: FontWeight.w900)),
      ),
      body: Center(
        child: Text('parent.coming_soon'.tr(),
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ),
    );
  }
}
