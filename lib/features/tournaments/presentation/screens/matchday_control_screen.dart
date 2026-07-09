import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/tournament_provider.dart';
import '../../data/models/tournament_match.dart';
import '../../../../core/theme/premium_theme.dart';
import '../../../../core/presentation/widgets/premium_widgets.dart';

class MatchdayControlScreen extends StatefulWidget {
  final String tournamentId;
  const MatchdayControlScreen({super.key, required this.tournamentId});

  @override
  State<MatchdayControlScreen> createState() => _MatchdayControlScreenState();
}

class _MatchdayControlScreenState extends State<MatchdayControlScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TournamentProvider>().fetchTournamentMatches(widget.tournamentId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final provider = context.watch<TournamentProvider>();
    final matches = provider.matches;
    final isLoading = provider.isLoading;

    return Scaffold(
      backgroundColor: PremiumTheme.surfaceBase(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: cs.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Быстрый счет (Live)',
          style: GoogleFonts.outfit(
            color: cs.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: isLoading && matches.isEmpty
          ? const Center(child: CircularProgressIndicator(color: PremiumTheme.neonGreen))
          : matches.isEmpty
              ? Center(
                  child: Text(
                    'Матчей пока не запланировано',
                    style: GoogleFonts.outfit(color: cs.onSurfaceVariant, fontSize: 14),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: matches.length,
                  itemBuilder: (context, index) {
                    final match = matches[index];
                    return _buildMatchControlCard(match, provider, cs);
                  },
                ),
    );
  }

  Widget _buildMatchControlCard(TournamentMatch match, TournamentProvider provider, ColorScheme cs) {
    final homeScore = match.homeScore;
    final awayScore = match.awayScore;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PremiumCard(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  match.fieldName ?? 'Поле не указано',
                  style: GoogleFonts.outfit(fontSize: 10, color: cs.onSurfaceVariant, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: match.status.toUpperCase() == 'LIVE'
                        ? PremiumTheme.neonGreen.withValues(alpha: 0.1)
                        : cs.onSurface.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: match.status.toUpperCase() == 'LIVE'
                          ? PremiumTheme.neonGreen.withValues(alpha: 0.2)
                          : cs.onSurface.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Text(
                    match.status.toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: match.status.toUpperCase() == 'LIVE'
                          ? PremiumTheme.neonGreen
                          : cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                // Home Team & Adjuster
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        match.homeTeamName ?? 'Хозяева',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: cs.onSurface),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildAdjustButton(
                            icon: Icons.remove,
                            onTap: () {
                              if (homeScore > 0) {
                                provider.quickUpdateMatchResult(widget.tournamentId, match.id.toString(), homeScore - 1, awayScore);
                              }
                            },
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '$homeScore',
                            style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w900, color: cs.onSurface),
                          ),
                          const SizedBox(width: 12),
                          _buildAdjustButton(
                            icon: Icons.add,
                            onTap: () {
                              provider.quickUpdateMatchResult(widget.tournamentId, match.id.toString(), homeScore + 1, awayScore);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 40,
                  width: 1,
                  color: cs.onSurface.withValues(alpha: 0.08),
                ),
                // Away Team & Adjuster
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        match.awayTeamName ?? 'Гости',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: cs.onSurface),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildAdjustButton(
                            icon: Icons.remove,
                            onTap: () {
                              if (awayScore > 0) {
                                provider.quickUpdateMatchResult(widget.tournamentId, match.id.toString(), homeScore, awayScore - 1);
                              }
                            },
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '$awayScore',
                            style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w900, color: cs.onSurface),
                          ),
                          const SizedBox(width: 12),
                          _buildAdjustButton(
                            icon: Icons.add,
                            onTap: () {
                              provider.quickUpdateMatchResult(widget.tournamentId, match.id.toString(), homeScore, awayScore + 1);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatusButton('SCHEDULED', 'ОЖИДАНИЕ', match, provider, cs),
                _buildStatusButton('LIVE', 'В ЭФИРЕ', match, provider, cs),
                _buildStatusButton('FINISHED', 'ЗАВЕРШЕН', match, provider, cs),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdjustButton({required IconData icon, required VoidCallback onTap}) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.onSurface.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          child: Icon(icon, size: 16, color: cs.onSurface),
        ),
      ),
    );
  }

  Widget _buildStatusButton(String status, String label, TournamentMatch match, TournamentProvider provider, ColorScheme cs) {
    final isSelected = match.status.toUpperCase() == status;
    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          provider.updateMatchDetails(widget.tournamentId, match.id.toString(), {'status': status.toLowerCase()});
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? PremiumTheme.neonGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? PremiumTheme.neonGreen : cs.onSurface.withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.black : cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
