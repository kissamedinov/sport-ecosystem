import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/tournament_provider.dart';
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
    });
  }

  void _refresh() {
    context.read<TournamentProvider>().fetchTournaments(
      city: _selectedCity == 'All Cities' ? null : _selectedCity,
      year: _selectedYear,
      mine: _tabController.index == 1,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          isChild ? '🏆 MY CHAMPIONSHIPS' : 'TOURNAMENTS', 
          style: const TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold, fontSize: 16)
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: PremiumTheme.neonGreen,
          labelColor: PremiumTheme.neonGreen,
          unselectedLabelColor: Colors.white38,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1),
          tabs: const [
            Tab(text: 'EXPLORE'),
            Tab(text: 'MY EVENTS'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white54),
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
          if (isChild) _buildChildGreeting(user?.name ?? 'Champion'),
          _buildFilterBar(),
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
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: provider.tournaments.length,
                  itemBuilder: (context, index) {
                    final tournament = provider.tournaments[index];
                    return _buildTournamentCard(tournament);
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
                color: isSelected ? PremiumTheme.neonGreen : Colors.white54,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              checkmarkColor: PremiumTheme.neonGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isSelected ? PremiumTheme.neonGreen.withValues(alpha: 0.5) : Colors.transparent)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTournamentCard(dynamic tournament) {
    return PremiumCard(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TournamentDetailsPage(tournamentId: tournament.id),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: PremiumTheme.neonGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: PremiumTheme.neonGreen.withValues(alpha: 0.2)),
                ),
                child: const Icon(Icons.emoji_events, color: PremiumTheme.neonGreen, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tournament.name.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 12, color: Colors.white54),
                        const SizedBox(width: 4),
                        Text(
                          tournament.location,
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: tournament.displayStatus == 'ACTIVE'
                      ? PremiumTheme.neonGreen.withValues(alpha: 0.1)
                      : (tournament.displayStatus == 'FINISHED' ? Colors.white10 : Colors.blue.withValues(alpha: 0.1)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  tournament.displayStatus,
                  style: TextStyle(
                    color: tournament.displayStatus == 'ACTIVE'
                        ? PremiumTheme.neonGreen
                        : (tournament.displayStatus == 'FINISHED' ? Colors.white54 : Colors.blueAccent),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoItem(Icons.calendar_today, tournament.startDate),
              _buildInfoItem(Icons.sports_soccer, tournament.format),
              _buildInfoItem(Icons.groups, tournament.ageCategory),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 1,
            color: Colors.white10,
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'VIEW DETAILS',
                style: TextStyle(
                  color: PremiumTheme.neonGreen,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              SizedBox(width: 4),
              Icon(Icons.arrow_forward_ios, size: 10, color: PremiumTheme.neonGreen),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 10, color: Colors.white38),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
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
            color: isChild ? PremiumTheme.neonGreen.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.1)
          ),
          const SizedBox(height: 16),
          Text(
            isChild ? 'NO GAMES SCHEDULED YET' : 'NO TOURNAMENTS YET',
            style: const TextStyle(color: Colors.white54, letterSpacing: 2, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            isChild ? 'Ask your coach about upcoming cups! ⚽' : 'Be the first to organize an event!',
            style: const TextStyle(color: Colors.white24, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildChildGreeting(String name) {
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
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1),
                ),
                const Text(
                  'Ready for your next big match?',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
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
              style: const TextStyle(color: Colors.white70),
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
