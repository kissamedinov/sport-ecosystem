import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/academy_provider.dart';
import '../../data/models/crm_models.dart';
import '../../data/models/academy_team.dart';
import 'academy_team_details_screen.dart';
import '../../../../features/clubs/providers/club_provider.dart';

// ── Design tokens ──────────────────────────────────────────────────────────
const _kNavy   = Color(0xFF0A0E12);
const _kCard   = Color(0xFF161B22);
const _kGreen  = Color(0xFF00E676);
const _kGreenD = Color(0xFF00C853);
const _kGold   = Color(0xFFF5C518);
const _kBlue   = Color(0xFF1E90D4);
const _kRed    = Color(0xFFFF5252);
const _kPurple = Color(0xFFB388FF);
const _kOrange = Color(0xFFFF9800);

TextStyle _outfit(double size, FontWeight w, Color color, {double ls = 0}) =>
    GoogleFonts.outfit(fontSize: size, fontWeight: w, color: color, letterSpacing: ls);

const _avatarPalette = [_kGreen, _kBlue, _kGold, _kPurple, _kOrange, _kRed];
Color _accentAt(int i) => _avatarPalette[i % _avatarPalette.length];

// ── Screen ─────────────────────────────────────────────────────────────────
class AcademyDashboardScreen extends StatefulWidget {
  const AcademyDashboardScreen({super.key});

  @override
  State<AcademyDashboardScreen> createState() => _AcademyDashboardScreenState();
}

class _AcademyDashboardScreenState extends State<AcademyDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  DayOfWeek? _filterDay;
  String?    _filterTeamId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AcademyProvider>().fetchMyAcademy();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Scaffold ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Consumer<AcademyProvider>(
      builder: (context, provider, _) {
        final hasAcademy = provider.myAcademy != null;
        return Scaffold(
          backgroundColor: _kNavy,
          appBar: _buildAppBar(hasAcademy),
          body: provider.isLoading && !hasAcademy
              ? const Center(child: CircularProgressIndicator(color: _kGreen))
              : hasAcademy
                  ? TabBarView(
                      controller: _tabController,
                      children: [
                        _buildOverviewTab(provider),
                        _buildTeamsTab(provider),
                        _buildSchedulesTab(provider),
                        _buildBillingTab(provider),
                      ],
                    )
                  : _buildNoAcademyView(),
          floatingActionButton: hasAcademy ? _buildFab() : null,
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(bool hasAcademy) {
    return AppBar(
      backgroundColor: _kCard,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
        onPressed: () => Navigator.maybePop(context),
      ),
      title: Text('academy.academy_dashboard'.tr(),
          style: _outfit(17, FontWeight.w800, Colors.white, ls: 0.3)),
      bottom: hasAcademy
          ? PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.07))),
                ),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicatorColor: _kGreen,
                  indicatorWeight: 2.5,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelColor: _kGreen,
                  unselectedLabelColor: Colors.white.withValues(alpha: 0.45),
                  labelStyle: _outfit(13, FontWeight.w700, _kGreen),
                  unselectedLabelStyle: _outfit(13, FontWeight.w500, Colors.white),
                  tabs: [
                    Tab(text: 'academy.overview'.tr()),
                    Tab(text: 'academy.teams'.tr()),
                    Tab(text: 'academy.schedules'.tr()),
                    Tab(text: 'academy.billing'.tr()),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  // ── No academy ────────────────────────────────────────────────────────────
  Widget _buildNoAcademyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _kGreen.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.school_rounded, size: 56, color: _kGreen),
          ),
          const SizedBox(height: 20),
          Text('academy.no_academy_yet'.tr(), style: _outfit(18, FontWeight.w700, Colors.white)),
          const SizedBox(height: 8),
          Text('academy.register_academy_hint'.tr(),
              style: _outfit(13, FontWeight.w400, Colors.white.withValues(alpha: 0.5))),
          const SizedBox(height: 28),
          _PrimaryBtn(label: 'academy.register_academy'.tr(), onPressed: () {}),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // OVERVIEW TAB
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildOverviewTab(AcademyProvider provider) {
    final academy = provider.myAcademy!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildAcademyInfoCard(academy),
        const SizedBox(height: 16),
        _buildStatGrid(provider),
        const SizedBox(height: 16),
        _buildRecentSessions(provider),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildAcademyInfoCard(dynamic academy) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_kGreen, _kGreenD],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.school_rounded, color: Colors.black, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(academy.name,
                    style: _outfit(16, FontWeight.w800, Colors.white)),
                const SizedBox(height: 3),
                Text('${academy.city} · ${academy.address}',
                    style: _outfit(12, FontWeight.w400, Colors.white.withValues(alpha: 0.5))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _kGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _kGreen.withValues(alpha: 0.3)),
            ),
            child: Text('academy.active'.tr(), style: _outfit(10, FontWeight.w700, _kGreen, ls: 0.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatGrid(AcademyProvider provider) {
    final stats = [
      _StatData('academy.teams'.tr(),    provider.teams.length.toString(),   Icons.group_rounded,    _kGreen),
      _StatData('academy.players'.tr(),  provider.players.length.toString(), Icons.person_rounded,   _kBlue),
      _StatData('academy.sessions'.tr(), provider.sessions.length.toString(),Icons.event_rounded,    _kGold),
      _StatData('player.rating'.tr(),    '#5',                               Icons.emoji_events_rounded, _kPurple),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.35,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: stats.map(_buildStatCard).toList(),
    );
  }

  Widget _buildStatCard(_StatData s) {
    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: s.color.withValues(alpha: 0.18)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: s.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(s.icon, color: s.color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.value, style: _outfit(28, FontWeight.w900, Colors.white)),
              Text(s.label,
                  style: _outfit(11, FontWeight.w600,
                      Colors.white.withValues(alpha: 0.45), ls: 0.3)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSessions(AcademyProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('academy.recent_sessions'.tr(), style: _outfit(15, FontWeight.w800, Colors.white)),
            if (provider.sessions.isNotEmpty)
              Text('${provider.sessions.length} total',
                  style: _outfit(11, FontWeight.w600, Colors.white.withValues(alpha: 0.4))),
          ],
        ),
        const SizedBox(height: 10),
        if (provider.sessions.isEmpty)
          _emptyState(Icons.event_note_rounded, 'academy.no_training_sessions'.tr())
        else
          ...provider.sessions.take(5).mapIndexed((i, s) => _buildSessionRow(s, i)),
      ],
    );
  }

  Widget _buildSessionRow(dynamic s, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _accentAt(index).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.calendar_today_rounded, color: _accentAt(index), size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.scheduledAt,
                    style: _outfit(13, FontWeight.w600, Colors.white)),
                Text(s.topic ?? 'academy.training_session'.tr(),
                    style: _outfit(11, FontWeight.w400,
                        Colors.white.withValues(alpha: 0.45))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _kGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('academy.active'.tr(),
                style: _outfit(9, FontWeight.w700, _kGreen, ls: 0.3)),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TEAMS TAB
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildTeamsTab(AcademyProvider provider) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text('academy.my_teams'.tr(), style: _outfit(16, FontWeight.w800, Colors.white)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _kGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('${provider.teams.length}',
                        style: _outfit(11, FontWeight.w800, _kGreen)),
                  ),
                ],
              ),
              GestureDetector(
                onTap: _showLinkTeamDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: _kBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _kBlue.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.link_rounded, size: 14, color: _kBlue),
                      const SizedBox(width: 5),
                      Text('academy.add_existing'.tr(), style: _outfit(11, FontWeight.w700, _kBlue)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            color: _kGreen,
            backgroundColor: _kCard,
            onRefresh: () => provider.fetchMyAcademy(),
            child: provider.teams.isEmpty
                ? SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.5,
                      child: _emptyState(Icons.group_rounded, 'academy.no_teams_added'.tr()),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                    itemCount: provider.teams.length,
                    itemBuilder: (context, index) =>
                        _buildTeamCard(provider.teams[index], index, provider),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildTeamCard(dynamic team, int index, AcademyProvider provider) {
    final accent = _accentAt(index);
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AcademyTeamDetailsScreen(team: team)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accent.withValues(alpha: 0.25), accent.withValues(alpha: 0.08)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: accent.withValues(alpha: 0.3)),
              ),
              child: Center(
                child: Text(
                  team.ageGroup,
                  textAlign: TextAlign.center,
                  style: _outfit(9, FontWeight.w800, accent),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(team.name, style: _outfit(14, FontWeight.w700, Colors.white)),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.schedule_rounded, size: 11,
                          color: Colors.white.withValues(alpha: 0.35)),
                      const SizedBox(width: 4),
                      Text('academy.next_session'.tr(),
                          style: _outfit(11, FontWeight.w400,
                              Colors.white.withValues(alpha: 0.4))),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.25), size: 20),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SCHEDULES TAB
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildSchedulesTab(AcademyProvider provider) {
    var schedules = provider.schedules;
    if (_filterDay != null) {
      schedules = schedules.where((s) => s.dayOfWeek == _filterDay).toList();
    }
    if (_filterTeamId != null) {
      schedules = schedules.where((s) => s.teamIds.contains(_filterTeamId)).toList();
    }

    return Column(
      children: [
        _buildScheduleFilterBar(provider),
        Expanded(
          child: schedules.isEmpty
              ? _emptyState(Icons.calendar_month_rounded,
                  provider.schedules.isEmpty
                      ? 'academy.no_schedules'.tr()
                      : 'academy.no_schedules_filter'.tr())
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  itemCount: schedules.length,
                  itemBuilder: (context, index) =>
                      _buildScheduleCard(schedules[index], index, provider),
                ),
        ),
      ],
    );
  }

  Widget _buildScheduleFilterBar(AcademyProvider provider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          _FilterChip(
            label: _filterDay?.toShortString() ?? 'academy.all_days'.tr(),
            icon: Icons.today_rounded,
            active: _filterDay != null,
            onTap: _selectFilterDay,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: _filterTeamId != null
                ? provider.teams
                    .firstWhere((t) => t.id == _filterTeamId)
                    .name
                : 'academy.all_teams'.tr(),
            icon: Icons.group_rounded,
            active: _filterTeamId != null,
            onTap: () => _selectFilterTeam(provider),
          ),
          if (_filterDay != null || _filterTeamId != null) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => setState(() {
                _filterDay = null;
                _filterTeamId = null;
              }),
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: _kRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _kRed.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.close_rounded, size: 14, color: _kRed),
              ),
            ),
          ],
          const Spacer(),
          GestureDetector(
            onTap: _showGenerateSessionsDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: _kGold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _kGold.withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt_rounded, size: 14, color: _kGold),
                  const SizedBox(width: 4),
                  Text('academy.generate'.tr(), style: _outfit(11, FontWeight.w700, _kGold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const _dayColors = [_kBlue, _kGreen, _kGold, _kPurple, _kOrange, _kRed, _kBlue];

  Widget _buildScheduleCard(dynamic schedule, int index, AcademyProvider provider) {
    final scheduleTeams = provider.teams
        .where((t) => schedule.teamIds.contains(t.id))
        .toList();
    final teamsLabel = scheduleTeams.isNotEmpty
        ? scheduleTeams.map((e) => e.name).join(', ')
        : 'academy.no_teams_assigned'.tr();
    final branch = schedule.branchId != null
        ? provider.branches.firstWhere(
            (b) => b.id == schedule.branchId,
            orElse: () => AcademyBranch(id: '', academyId: '', name: 'Unknown', address: ''),
          )
        : null;
    final dayColor = _dayColors[index % _dayColors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Left accent bar
              Container(width: 4, color: dayColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                  child: Row(
                    children: [
                      // Day/time icon
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: dayColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.timer_rounded, color: dayColor, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${schedule.dayOfWeek.toShortString()}  ·  ${schedule.startTime} – ${schedule.endTime}',
                              style: _outfit(13, FontWeight.w800, Colors.white),
                            ),
                            const SizedBox(height: 5),
                            Row(children: [
                              Icon(Icons.group_rounded, size: 12,
                                  color: Colors.white.withValues(alpha: 0.4)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(teamsLabel,
                                    style: _outfit(11, FontWeight.w400,
                                        Colors.white.withValues(alpha: 0.55))),
                              ),
                            ]),
                            if (branch != null) ...[
                              const SizedBox(height: 3),
                              Row(children: [
                                const Icon(Icons.location_on_rounded,
                                    size: 12, color: _kBlue),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text('${branch.name} (${branch.address})',
                                      style: _outfit(11, FontWeight.w500, _kBlue)),
                                ),
                              ]),
                            ],
                            const SizedBox(height: 3),
                            Row(children: [
                              Icon(Icons.place_rounded, size: 12,
                                  color: Colors.white.withValues(alpha: 0.3)),
                              const SizedBox(width: 4),
                              Text(schedule.location ?? 'academy.main_field'.tr(),
                                  style: _outfit(11, FontWeight.w400,
                                      Colors.white.withValues(alpha: 0.4))),
                            ]),
                          ],
                        ),
                      ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(Icons.delete_outline_rounded,
                            color: _kRed.withValues(alpha: 0.7), size: 18),
                        onPressed: () => _confirmDeleteSchedule(schedule, provider),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteSchedule(dynamic schedule, AcademyProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _kCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('academy.delete_schedule'.tr(), style: _outfit(16, FontWeight.w800, Colors.white)),
        content: Text('academy.delete_schedule_confirm'.tr(),
            style: _outfit(13, FontWeight.w400, Colors.white.withValues(alpha: 0.7))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('common.cancel'.tr(), style: _outfit(13, FontWeight.w600, Colors.white.withValues(alpha: 0.5))),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: _kRed),
            onPressed: () async {
              Navigator.pop(context);
              final ok = await provider.deleteSchedule(provider.myAcademy!.id, schedule.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(ok ? 'academy.schedule_deleted'.tr() : 'academy.failed_delete'.tr()),
                  backgroundColor: ok ? _kGreen : _kRed,
                ));
              }
            },
            child: Text('common.delete'.tr(), style: _outfit(13, FontWeight.w700, _kRed)),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BILLING TAB
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildBillingTab(AcademyProvider provider) {
    if (provider.billingConfig == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _kGold.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.account_balance_wallet_rounded,
                  size: 52, color: _kGold),
            ),
            const SizedBox(height: 20),
            Text('academy.billing_not_configured'.tr(),
                style: _outfit(18, FontWeight.w700, Colors.white)),
            const SizedBox(height: 8),
            Text('academy.setup_billing_hint'.tr(),
                style: _outfit(13, FontWeight.w400,
                    Colors.white.withValues(alpha: 0.45))),
            const SizedBox(height: 28),
            _PrimaryBtn(label: 'academy.configure_billing'.tr(), onPressed: _showBillingConfigDialog),
          ],
        ),
      );
    }

    final fee = provider.billingConfig!.monthlySubscriptionFee ?? 0;
    final currency = provider.billingConfig!.currency;

    return Column(
      children: [
        // Pricing banner
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _kGreen.withValues(alpha: 0.12),
                _kBlue.withValues(alpha: 0.08),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _kGreen.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _kGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.payments_rounded, color: _kGreen, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('academy.monthly_fee'.tr(), style: _outfit(11, FontWeight.w600,
                        Colors.white.withValues(alpha: 0.5), ls: 0.5)),
                    Text('$fee $currency / month',
                        style: _outfit(16, FontWeight.w800, Colors.white)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _showBillingConfigDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _kGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _kGreen.withValues(alpha: 0.3)),
                  ),
                  child: Text('common.edit'.tr(), style: _outfit(11, FontWeight.w700, _kGreen)),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(
            children: [
              Text('academy.player_billing'.tr(), style: _outfit(15, FontWeight.w800, Colors.white)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _kBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('${provider.players.length}',
                    style: _outfit(11, FontWeight.w800, _kBlue)),
              ),
            ],
          ),
        ),
        Expanded(
          child: provider.players.isEmpty
              ? _emptyState(Icons.people_rounded, 'academy.no_players_enrolled'.tr())
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  itemCount: provider.players.length,
                  itemBuilder: (context, index) =>
                      _buildPlayerBillingCard(provider.players[index], index),
                ),
        ),
      ],
    );
  }

  Widget _buildPlayerBillingCard(dynamic player, int index) {
    final idStr = (player.playerProfileId ?? 'Unknown');
    final shortId = idStr.length >= 8 ? idStr.substring(0, 8).toUpperCase() : idStr;
    final accent = _accentAt(index);
    final initials = shortId.length >= 2 ? shortId.substring(0, 2) : shortId;

    return GestureDetector(
      onTap: () => _showPlayerBillingReport(player.playerProfileId ?? ''),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accent.withValues(alpha: 0.3), accent.withValues(alpha: 0.1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(color: accent.withValues(alpha: 0.4)),
              ),
              child: Center(
                child: Text(initials,
                    style: _outfit(12, FontWeight.w800, accent)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('academy.player_num'.tr(namedArgs: {'num': (index + 1).toString()}),
                      style: _outfit(13, FontWeight.w700, Colors.white)),
                  Text('ID: $shortId',
                      style: _outfit(11, FontWeight.w500,
                          Colors.white.withValues(alpha: 0.4))),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: accent.withValues(alpha: 0.25)),
              ),
              child: Text('academy.report'.tr(),
                  style: _outfit(10, FontWeight.w700, accent, ls: 0.3)),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // FAB
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildFab() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kGreen, _kGreenD],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: _kGreen.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (_tabController.index == 1) {
              _showAddTeamDialog();
            } else if (_tabController.index == 2) _showAddScheduleDialog();
            else if (_tabController.index == 3) _showBillingConfigDialog();
          },
          child: const Icon(Icons.add_rounded, color: Colors.black, size: 26),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Shared helpers
  // ══════════════════════════════════════════════════════════════════════════
  Widget _emptyState(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 52, color: Colors.white.withValues(alpha: 0.15)),
          const SizedBox(height: 14),
          Text(message,
              style: _outfit(14, FontWeight.w500, Colors.white.withValues(alpha: 0.35))),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Dialogs – logic identical to original, only styling updated
  // ══════════════════════════════════════════════════════════════════════════

  void _selectFilterDay() async {
    final result = await showDialog<DayOfWeek>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _kCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('academy.filter_by_day'.tr(), style: _outfit(16, FontWeight.w800, Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: DayOfWeek.values
              .map((day) => ListTile(
                    title: Text(day.toShortString(),
                        style: _outfit(14, FontWeight.w500, Colors.white)),
                    onTap: () => Navigator.pop(context, day),
                  ))
              .toList(),
        ),
      ),
    );
    if (result != null) setState(() => _filterDay = result);
  }

  void _selectFilterTeam(AcademyProvider provider) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _kCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('academy.filter_by_team'.tr(), style: _outfit(16, FontWeight.w800, Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: provider.teams.length,
            itemBuilder: (context, i) {
              final team = provider.teams[i];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _accentAt(i).withValues(alpha: 0.2),
                  child: Text(team.ageGroup, style: _outfit(9, FontWeight.w800, _accentAt(i))),
                ),
                title: Text(team.name, style: _outfit(13, FontWeight.w600, Colors.white)),
                onTap: () => Navigator.pop(context, team.id),
              );
            },
          ),
        ),
      ),
    );
    if (result != null) setState(() => _filterTeamId = result);
  }

  void _showAddTeamDialog() {
    final nameCtrl = TextEditingController();
    final ageCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _kCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('academy.new_team'.tr(), style: _outfit(16, FontWeight.w800, Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dialogField(nameCtrl, 'academy.team_name'.tr()),
            const SizedBox(height: 12),
            _dialogField(ageCtrl, 'academy.age_groups'.tr(), hint: 'academy.age_groups_hint'.tr()),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('common.cancel'.tr(), style: _outfit(13, FontWeight.w600, Colors.white.withValues(alpha: 0.5))),
          ),
          _DialogBtn(
            label: 'academy.add_team'.tr(),
            onPressed: () {
              final p = context.read<AcademyProvider>();
              final id = p.myAcademy?.id;
              if (id == null) return;
              p.createTeam(id, nameCtrl.text, ageCtrl.text, 'Intermediate');
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showLinkTeamDialog() {
    final clubProvider = context.read<ClubProvider>();
    final academyProvider = context.read<AcademyProvider>();
    final allTeams = (clubProvider.coachDashboard?['teams'] as List?) ?? [];
    final existing = academyProvider.teams.map((t) => t.id).toSet();
    final available = allTeams.where((t) => !existing.contains(t['id'].toString())).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _kCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('academy.link_existing_team'.tr(), style: _outfit(16, FontWeight.w800, Colors.white)),
        content: available.isEmpty
            ? Text('academy.all_teams_linked'.tr(),
                style: _outfit(13, FontWeight.w400, Colors.white.withValues(alpha: 0.6)))
            : SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: available.length,
                  itemBuilder: (context, i) {
                    final team = available[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _accentAt(i).withValues(alpha: 0.2),
                        child: const Icon(Icons.groups_rounded, size: 18),
                      ),
                      title: Text(team['name'] ?? 'common.unknown'.tr(),
                          style: _outfit(13, FontWeight.w600, Colors.white)),
                      subtitle: Text(team['age_group'] ?? '',
                          style: _outfit(11, FontWeight.w400,
                              Colors.white.withValues(alpha: 0.45))),
                      onTap: () async {
                        final id = academyProvider.myAcademy?.id;
                        if (id != null) {
                          final ok = await academyProvider.linkExistingTeam(id, team['id'].toString());
                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(ok ? 'academy.team_linked'.tr() : 'academy.failed_link_team'.tr()),
                              backgroundColor: ok ? _kGreen : _kRed,
                            ));
                          }
                        }
                      },
                    );
                  },
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('common.close'.tr(), style: _outfit(13, FontWeight.w600, Colors.white.withValues(alpha: 0.5))),
          ),
        ],
      ),
    );
  }

  void _showGenerateSessionsDialog() {
    final provider = context.read<AcademyProvider>();
    final academyId = provider.myAcademy?.id;
    if (academyId == null) return;

    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 30));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModal) => AlertDialog(
          backgroundColor: _kCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(children: [
            const Icon(Icons.bolt_rounded, color: _kGold, size: 22),
            const SizedBox(width: 10),
            Text('academy.generate_sessions'.tr(), style: _outfit(16, FontWeight.w800, Colors.white)),
          ]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'academy.generate_sessions_desc'.tr(),
                style: _outfit(13, FontWeight.w400, Colors.white.withValues(alpha: 0.6)),
              ),
              const SizedBox(height: 20),
              Text('academy.date_range'.tr(), style: _outfit(11, FontWeight.w700,
                  Colors.white.withValues(alpha: 0.5), ls: 1)),
              const SizedBox(height: 10),
              _buildDateRow('academy.start'.tr(), startDate,
                  (d) { if (d != null) setModal(() => startDate = d); }),
              const SizedBox(height: 8),
              _buildDateRow('academy.end'.tr(), endDate,
                  (d) { if (d != null) setModal(() => endDate = d); }),
              const SizedBox(height: 12),
              Text('academy.sessions_can_cancel'.tr(),
                  style: _outfit(11, FontWeight.w400, Colors.white.withValues(alpha: 0.35))),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('common.cancel'.tr(), style: _outfit(13, FontWeight.w600,
                  Colors.white.withValues(alpha: 0.5))),
            ),
            _DialogBtn(
              label: 'academy.generate'.tr(),
              color: _kGold,
              textColor: Colors.black,
              onPressed: () async {
                Navigator.pop(context);
                final ok = await provider.triggerGenerateSessions(academyId, startDate, endDate);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(ok ? 'academy.sessions_generated'.tr() : 'academy.failed_generate'.tr()),
                    backgroundColor: ok ? _kGreen : _kRed,
                  ));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRow(String label, DateTime date, Function(DateTime?) onPick) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: _kGreen, onPrimary: Colors.black,
                surface: _kCard, onSurface: Colors.white,
              ),
            ),
            child: child!,
          ),
        );
        onPick(picked);
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: _outfit(13, FontWeight.w500,
                Colors.white.withValues(alpha: 0.6))),
            Text('${date.day}.${date.month}.${date.year}',
                style: _outfit(13, FontWeight.w700, _kGold)),
          ],
        ),
      ),
    );
  }

  void _showAddScheduleDialog() {
    final provider = context.read<AcademyProvider>();
    final academyId = provider.myAcademy?.id;
    if (academyId == null) return;
    if (provider.teams.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('academy.no_teams_please_add'.tr())));
      return;
    }
    provider.fetchBranches(academyId);

    List<String> selectedTeamIds = [provider.teams[0].id];
    List<Map<String, dynamic>> slots = [{
      'day_of_week': DayOfWeek.MONDAY,
      'start_time': const TimeOfDay(hour: 18, minute: 0),
      'end_time': const TimeOfDay(hour: 19, minute: 30),
    }];
    String? selectedBranchId;
    final locationCtrl = TextEditingController(text: 'Main Field');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModal) {
          return Container(
            decoration: const BoxDecoration(
              color: _kCard,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              left: 20, right: 20, top: 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('academy.add_schedule'.tr(), style: _outfit(20, FontWeight.w800, Colors.white)),
                  const SizedBox(height: 20),
                  Text('academy.teams_label'.tr(), style: _outfit(10, FontWeight.w800,
                      Colors.white.withValues(alpha: 0.4), ls: 1.5)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: provider.teams.mapIndexed((i, t) {
                      final sel = selectedTeamIds.contains(t.id);
                      return FilterChip(
                        label: Text(t.name, style: _outfit(12, FontWeight.w600,
                            sel ? _kGreen : Colors.white.withValues(alpha: 0.7))),
                        selected: sel,
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                        selectedColor: _kGreen.withValues(alpha: 0.15),
                        checkmarkColor: _kGreen,
                        side: BorderSide(color: sel ? _kGreen.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.1)),
                        onSelected: (v) => setModal(() {
                          if (v) {
                            selectedTeamIds.add(t.id);
                          } else if (selectedTeamIds.length > 1) selectedTeamIds.remove(t.id);
                        }),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  Text('academy.location_label'.tr(), style: _outfit(10, FontWeight.w800,
                      Colors.white.withValues(alpha: 0.4), ls: 1.5)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    dropdownColor: _kCard,
                    initialValue: selectedBranchId,
                    hint: Text('academy.select_branch'.tr(), style: _outfit(13, FontWeight.w400,
                        Colors.white.withValues(alpha: 0.4))),
                    items: [
                      DropdownMenuItem(
                        value: null,
                        child: Text('academy.no_branch'.tr(), style: _outfit(13, FontWeight.w500, Colors.white)),
                      ),
                      ...provider.branches.map((b) => DropdownMenuItem(
                        value: b.id,
                        child: Text(b.name, style: _outfit(13, FontWeight.w500, Colors.white)),
                      )),
                    ],
                    onChanged: (v) => setModal(() => selectedBranchId = v),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: locationCtrl,
                    style: _outfit(14, FontWeight.w500, Colors.white),
                    decoration: InputDecoration(
                      hintText: 'academy.field_name'.tr(),
                      hintStyle: _outfit(13, FontWeight.w400, Colors.white.withValues(alpha: 0.35)),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('academy.training_days'.tr(), style: _outfit(10, FontWeight.w800,
                      Colors.white.withValues(alpha: 0.4), ls: 1.5)),
                  const SizedBox(height: 8),
                  ...slots.asMap().entries.map((e) {
                    final idx = e.key;
                    final item = e.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButton<DayOfWeek>(
                                  isExpanded: true,
                                  value: item['day_of_week'],
                                  dropdownColor: _kCard,
                                  underline: const SizedBox(),
                                  style: _outfit(13, FontWeight.w600, Colors.white),
                                  items: DayOfWeek.values.map((d) => DropdownMenuItem(
                                    value: d,
                                    child: Text(d.toShortString()),
                                  )).toList(),
                                  onChanged: (v) => setModal(() => item['day_of_week'] = v!),
                                ),
                              ),
                              if (slots.length > 1)
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, color: _kRed, size: 18),
                                  onPressed: () => setModal(() => slots.removeAt(idx)),
                                ),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(child: _timePicker('Start', item['start_time'],
                                  (p) { if (p != null) setModal(() => item['start_time'] = p); }, context)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Text('→', style: _outfit(14, FontWeight.w400,
                                    Colors.white.withValues(alpha: 0.4))),
                              ),
                              Expanded(child: _timePicker('End', item['end_time'],
                                  (p) { if (p != null) setModal(() => item['end_time'] = p); }, context)),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                  TextButton.icon(
                    onPressed: () => setModal(() => slots.add({
                      'day_of_week': DayOfWeek.MONDAY,
                      'start_time': const TimeOfDay(hour: 18, minute: 0),
                      'end_time': const TimeOfDay(hour: 19, minute: 30),
                    })),
                    icon: const Icon(Icons.add_rounded, color: _kGreen, size: 16),
                    label: Text('academy.add_day'.tr(), style: _outfit(12, FontWeight.w600, _kGreen)),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [_kGreen, _kGreenD]),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: _kGreen.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          final finalSlots = slots.map((item) {
                            final start = item['start_time'] as TimeOfDay;
                            final end = item['end_time'] as TimeOfDay;
                            return {
                              'team_ids': selectedTeamIds,
                              'day_of_week': (item['day_of_week'] as DayOfWeek).toShortString(),
                              'start_time': '${start.hour.toString().padLeft(2, "0")}:${start.minute.toString().padLeft(2, "0")}',
                              'end_time': '${end.hour.toString().padLeft(2, "0")}:${end.minute.toString().padLeft(2, "0")}',
                              'location': locationCtrl.text,
                              'branch_id': selectedBranchId,
                            };
                          }).toList();
                          final ok = await provider.createSchedule(academyId, {'schedules': finalSlots});
                          if (ok) Navigator.pop(context);
                        },
                        child: Text('academy.save_schedules'.tr(),
                            style: _outfit(14, FontWeight.w900, Colors.black, ls: 0.5)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showBillingConfigDialog() {
    final provider = context.read<AcademyProvider>();
    final feeCtrl = TextEditingController(
        text: provider.billingConfig?.monthlySubscriptionFee?.toString() ?? '0');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _kCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('academy.billing_configuration'.tr(), style: _outfit(16, FontWeight.w800, Colors.white)),
        content: _dialogField(feeCtrl, 'academy.monthly_fee_kzt'.tr(),
            keyboardType: TextInputType.number),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('common.cancel'.tr(), style: _outfit(13, FontWeight.w600,
                Colors.white.withValues(alpha: 0.5))),
          ),
          _DialogBtn(
            label: 'common.save'.tr(),
            onPressed: () async {
              final id = provider.myAcademy?.id;
              if (id == null) return;
              final ok = await provider.saveBillingConfig(id, {
                'monthly_subscription_fee': double.tryParse(feeCtrl.text) ?? 0,
                'currency': 'KZT',
              });
              if (ok && mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showPlayerBillingReport(String playerId) {
    final provider = context.read<AcademyProvider>();
    final now = DateTime.now();
    final academyId = provider.myAcademy?.id;
    if (academyId == null) return;
    provider.fetchBillingReport(academyId, playerId, now.month, now.year);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Consumer<AcademyProvider>(
        builder: (context, p, _) => SizedBox(
          height: MediaQuery.of(context).size.height * 0.72,
          child: p.isLoading
              ? const Center(child: CircularProgressIndicator(color: _kGreen))
              : p.currentBillingReport == null
                  ? Center(
                      child: Text('academy.no_data_month'.tr(),
                          style: _outfit(14, FontWeight.w500,
                              Colors.white.withValues(alpha: 0.5))))
                  : Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              width: 40, height: 4,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(DateFormat('MMMM yyyy').format(now),
                              style: _outfit(20, FontWeight.w900, Colors.white)),
                          const SizedBox(height: 4),
                          Text(p.currentBillingReport!.playerName,
                              style: _outfit(14, FontWeight.w600, _kBlue)),
                          const SizedBox(height: 20),
                          _reportSection('academy.attendance_section'.tr(), [
                            _billingRow('academy.total_sessions'.tr(), p.currentBillingReport!.attendance.totalSessions.toString()),
                            _billingRow('academy.present'.tr(), p.currentBillingReport!.attendance.present.toString(), _kGreen),
                            _billingRow('academy.absent'.tr(), p.currentBillingReport!.attendance.absent.toString(), _kRed),
                            _billingRow('academy.late'.tr(), p.currentBillingReport!.attendance.late.toString(), _kOrange),
                          ]),
                          const SizedBox(height: 16),
                          _reportSection('academy.fees_section'.tr(), [
                            _billingRow('academy.base_monthly'.tr(), '${p.currentBillingReport!.baseFee} ${p.currentBillingReport!.currency}'),
                            _billingRow('academy.additional'.tr(), '${p.currentBillingReport!.additionalFees} ${p.currentBillingReport!.currency}'),
                            _billingRow('academy.total_owed'.tr(), '${p.currentBillingReport!.totalOwed} ${p.currentBillingReport!.currency}',
                                _kGold, true),
                          ]),
                          const Spacer(),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [_kGreen, _kGreenD]),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () => Navigator.pop(context),
                                child: Text('common.close'.tr(), style: _outfit(14, FontWeight.w800, Colors.black)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }

  Widget _reportSection(String title, List<Widget> rows) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(),
              style: _outfit(9, FontWeight.w800,
                  Colors.white.withValues(alpha: 0.4), ls: 1.2)),
          const SizedBox(height: 10),
          ...rows,
        ],
      ),
    );
  }

  Widget _billingRow(String label, String value, [Color? color, bool bold = false]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: _outfit(13, bold ? FontWeight.w700 : FontWeight.w400,
              Colors.white.withValues(alpha: bold ? 0.85 : 0.6))),
          Text(value, style: _outfit(bold ? 16 : 13,
              bold ? FontWeight.w900 : FontWeight.w600,
              color ?? Colors.white)),
        ],
      ),
    );
  }

  Widget _dialogField(TextEditingController ctrl, String label,
      {String? hint, TextInputType? keyboardType}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: _outfit(14, FontWeight.w500, Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: _outfit(13, FontWeight.w500, Colors.white.withValues(alpha: 0.5)),
        hintStyle: _outfit(13, FontWeight.w400, Colors.white.withValues(alpha: 0.3)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kGreen, width: 1.5),
        ),
      ),
    );
  }
}

// ── Small reusable widgets ─────────────────────────────────────────────────

class _StatData {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatData(this.label, this.value, this.icon, this.color);
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? _kGreen.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? _kGreen.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: active ? _kGreen : Colors.white.withValues(alpha: 0.6)),
            const SizedBox(width: 5),
            Text(label,
                style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: active ? _kGreen : Colors.white.withValues(alpha: 0.6))),
          ],
        ),
      ),
    );
  }
}

class _PrimaryBtn extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _PrimaryBtn({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_kGreen, _kGreenD]),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: _kGreen.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Text(label,
            style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.black, letterSpacing: 1.1)),
      ),
    );
  }
}

class _DialogBtn extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color color;
  final Color textColor;

  const _DialogBtn({
    required this.label,
    required this.onPressed,
    this.color = _kGreen,
    this.textColor = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(label,
            style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
      ),
    );
  }
}

Widget _timePicker(String label, TimeOfDay time, Function(TimeOfDay?) onPick, BuildContext ctx) {
  return InkWell(
    onTap: () async {
      final picked = await showTimePicker(context: ctx, initialTime: time);
      onPick(picked);
    },
    borderRadius: BorderRadius.circular(8),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.outfit(fontSize: 10, color: Colors.white.withValues(alpha: 0.4))),
          Text(time.format(ctx),
              style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
        ],
      ),
    ),
  );
}

// ── Extension helpers ──────────────────────────────────────────────────────
extension _IterableIndexed<T> on Iterable<T> {
  Iterable<R> mapIndexed<R>(R Function(int i, T e) fn) sync* {
    var i = 0;
    for (final e in this) {
      yield fn(i++, e);
    }
  }
}
