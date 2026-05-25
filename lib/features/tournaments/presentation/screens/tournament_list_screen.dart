import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/tournament_provider.dart';
import '../../../../features/academies/providers/academy_provider.dart';
import '../../../auth/providers/auth_provider.dart';
import 'create_tournament_screen.dart';
import 'tournament_details_page.dart';
import '../../../../core/theme/premium_theme.dart';
import '../../../../core/presentation/widgets/premium_widgets.dart';

class TournamentListScreen extends StatefulWidget {
  final int initialIndex;
  const TournamentListScreen({super.key, this.initialIndex = 0});

  @override
  State<TournamentListScreen> createState() => _TournamentListScreenState();
}

class _TournamentListScreenState extends State<TournamentListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedCity;
  int? _selectedYear;

  final List<String> _kazakhstanCities = [
    'All Cities', 'Astana', 'Almaty', 'Shymkent', 'Karaganda', 'Aktobe', 'Taraz', 'Pavlodar', 'Semey'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialIndex);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _refresh();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refresh();
      context.read<AcademyProvider>().fetchMyAcademy();
    });
  }

  void _refresh() {
    final user = context.read<AuthProvider>().user;
    final isChild = user != null && (
      user.roles?.contains('PLAYER_CHILD') == true ||
      user.roles?.contains('PLAYER_YOUTH') == true
    );

    context.read<TournamentProvider>().fetchTournaments(
      city: _selectedCity == 'All Cities' ? null : _selectedCity,
      year: _selectedYear,
      mine: isChild ? true : (_tabController.index == 1),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final user = context.watch<AuthProvider>().user;
    final canCreate = user != null && (
      user.roles?.contains('TOURNAMENT_ORGANIZER') == true ||
      user.roles?.contains('ADMIN') == true
    );
    final isChild = user != null && (
      user.roles?.contains('PLAYER_CHILD') == true ||
      user.roles?.contains('PLAYER_YOUTH') == true
    );

    return Scaffold(
      backgroundColor: PremiumTheme.surfaceBase(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          isChild ? '⭐ MY CHAMPIONSHIPS' : 'TOURNAMENTS',
          style: const TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold, fontSize: 16)
        ),
        bottom: isChild ? null : TabBar(
          controller: _tabController,
          indicatorColor: PremiumTheme.neonGreen,
          labelColor: PremiumTheme.neonGreen,
          unselectedLabelColor: cs.onSurfaceVariant,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1),
          tabs: const [
            Tab(text: 'EXPLORE'),
            Tab(text: 'MY EVENTS'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      floatingActionButton: canCreate ? FloatingActionButton(
        backgroundColor: PremiumTheme.neonGreen,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateTournamentScreen()),
          ).then((_) => _refresh());
        },
        child: const Icon(Icons.add, color: Colors.black),
      ) : null,
      body: Column(
        children: [
          if (isChild) ...[
            _buildChildGreeting(user.name ?? 'Champion'),
            const SizedBox(height: 10),
          ],
          if (!isChild) _buildFilterBar(),
          Expanded(
            child: Consumer<TournamentProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator(color: PremiumTheme.neonGreen));
                }
                if (provider.error != null) {
                  return _buildErrorState(provider.error!);
                }
                if (provider.tournaments.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                  itemCount: provider.tournaments.length + 1,
                  itemBuilder: (context, index) {
                    if (index == provider.tournaments.length) {
                      return const SizedBox(height: 180);
                    }
                    final tournament = provider.tournaments[index];
                    return _buildTournamentCard(tournament, isChild);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _kazakhstanCities.length,
        itemBuilder: (context, index) {
          final city = _kazakhstanCities[index];
          final isSelected = (_selectedCity ?? 'All Cities') == city;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(city),
              selected: isSelected,
              onSelected: (val) {
                setState(() => _selectedCity = val ? city : null);
                _refresh();
              },
              backgroundColor: PremiumTheme.surfaceCard(context),
              selectedColor: PremiumTheme.neonGreen.withValues(alpha: 0.2),
              labelStyle: TextStyle(
                color: isSelected ? PremiumTheme.neonGreen : cs.onSurfaceVariant,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              checkmarkColor: PremiumTheme.neonGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: isSelected ? PremiumTheme.neonGreen.withValues(alpha: 0.5) : Colors.transparent),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTournamentCard(dynamic tournament, bool isChild) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final statusColor = tournament.displayStatus == 'ACTIVE'
        ? const Color(0xFF00E676)
        : (tournament.displayStatus == 'FINISHED'
            ? cs.onSurfaceVariant
            : const Color(0xFF42A5F5));

    final cardBg = isDark
        ? (tournament.displayStatus == 'ACTIVE'
            ? const Color(0xFF0A1F0A)
            : (tournament.displayStatus == 'FINISHED'
                ? const Color(0xFF111418)
                : const Color(0xFF0D1B2A)))
        : PremiumTheme.surfaceCard(context);

    final borderColor = isDark
        ? (tournament.displayStatus == 'ACTIVE'
            ? const Color(0xFF1B5E20)
            : (tournament.displayStatus == 'FINISHED'
                ? const Color(0xFF2A2F36)
                : const Color(0xFF1E3A5F)))
        : statusColor.withValues(alpha: 0.2);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TournamentDetailsPage(tournamentId: tournament.id)),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: statusColor.withValues(alpha: 0.25)),
                      ),
                      child: tournament.logoUrl != null && tournament.logoUrl!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.network(tournament.logoUrl!, fit: BoxFit.cover),
                            )
                          : Icon(
                              isChild ? Icons.star_rounded : Icons.emoji_events_rounded,
                              color: statusColor,
                              size: 22,
                            ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tournament.name.toUpperCase(),
                            style: TextStyle(color: cs.onSurface, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 0.5, height: 1.2),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Icon(Icons.location_on_rounded, size: 11, color: cs.onSurfaceVariant),
                              const SizedBox(width: 3),
                              Text(
                                tournament.location,
                                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tournament.displayStatus,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoChip(Icons.calendar_today_rounded, tournament.startDate, statusColor),
                    _buildInfoChip(Icons.sports_soccer_rounded, tournament.format, statusColor),
                    _buildInfoChip(Icons.groups_rounded, tournament.ageCategory, statusColor),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'DETAILS',
                          style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.8),
                        ),
                        const SizedBox(width: 2),
                        Icon(Icons.arrow_forward_ios_rounded, size: 9, color: statusColor),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String value, Color color) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10, color: color.withValues(alpha: 0.6)),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 10, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final cs = Theme.of(context).colorScheme;
    final user = context.read<AuthProvider>().user;
    final isChild = user != null && (
      user.roles?.contains('PLAYER_CHILD') == true ||
      user.roles?.contains('PLAYER_YOUTH') == true
    );

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isChild ? Icons.star_rounded : Icons.emoji_events_outlined,
            size: 80,
            color: isChild ? PremiumTheme.neonGreen.withValues(alpha: 0.2) : cs.onSurface.withValues(alpha: 0.12),
          ),
          const SizedBox(height: 16),
          Text(
            isChild ? 'NO GAMES SCHEDULED YET' : 'NO TOURNAMENTS YET',
            style: TextStyle(color: cs.onSurfaceVariant, letterSpacing: 2, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            isChild ? 'Ask your coach about upcoming cups! ⚽' : 'Be the first to organize an event!',
            style: TextStyle(color: cs.onSurface.withValues(alpha: 0.45), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildChildGreeting(String name) {
    final cs = Theme.of(context).colorScheme;
    final academy = context.watch<AcademyProvider>().myAcademy;
    final academyName = academy?.name ?? 'ORLEON';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            PremiumTheme.neonGreen.withValues(alpha: 0.15),
            PremiumTheme.electricBlue.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PremiumTheme.neonGreen.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Text('⭐', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HELLO, $name!',
                  style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1),
                ),
                Text(
                  'REPRESENTING: ${academyName.toUpperCase()}',
                  style: const TextStyle(color: PremiumTheme.neonGreen, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
                const SizedBox(height: 2),
                Text(
                  'Ready for your next big match?',
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: PremiumTheme.danger),
            const SizedBox(height: 16),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            PremiumButton(
              text: 'RETRY',
              onPressed: () => context.read<TournamentProvider>().fetchTournaments(),
            ),
          ],
        ),
      ),
    );
  }
}
