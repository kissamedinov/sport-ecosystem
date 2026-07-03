import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../data/models/tournament_match.dart';
import '../screens/match_center_screen.dart';

// Neon green accent
const Color _neon = Color(0xFF00E676);

class TournamentBracketWidget extends StatelessWidget {
  final List<TournamentMatch> matches;
  final String tournamentId;

  const TournamentBracketWidget({
    Key? key,
    required this.matches,
    required this.tournamentId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Filter only playoff matches (no groupId)
    final playoffMatches = matches.where((m) => m.groupId == null).toList();

    if (playoffMatches.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.account_tree_outlined, size: 48, color: Colors.white.withValues(alpha: 0.3)),
              const SizedBox(height: 12),
              Text(
                'tournament.bracket_not_created'.tr(),
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    // Categorize matches by roundNumber and bracketPosition
    TournamentMatch? sf1 = _findMatch(playoffMatches, 1, 0); // A1 vs B2
    TournamentMatch? sf2 = _findMatch(playoffMatches, 1, 1); // B1 vs A2
    TournamentMatch? finalMatch = _findMatch(playoffMatches, 2, 0); // Final
    TournamentMatch? thirdPlace = _findMatch(playoffMatches, 2, 1); // 3rd place

    // Placement matches (5-8)
    TournamentMatch? sf5 = _findMatch(playoffMatches, 1, 2);
    TournamentMatch? sf6 = _findMatch(playoffMatches, 1, 3);
    TournamentMatch? fifth = _findMatch(playoffMatches, 2, 2);
    TournamentMatch? seventh = _findMatch(playoffMatches, 2, 3);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === MAIN BRACKET: Semis → Final + 3rd ===
            if (sf1 != null || sf2 != null || finalMatch != null) ...[
              _sectionLabel('🏆 ОСНОВНАЯ СЕТКА'),
              const SizedBox(height: 12),
              _buildMainBracket(context, sf1, sf2, finalMatch, thirdPlace),
              const SizedBox(height: 20),
            ],

            // === PLACEMENT: 5-8 ===
            if (sf5 != null || sf6 != null || fifth != null || seventh != null) ...[
              _sectionLabel('📋 МАТЧИ ЗА МЕСТА 5-8'),
              const SizedBox(height: 12),
              _buildPlacementBracket(context, sf5, sf6, fifth, seventh),
            ],
          ],
        ),
      ),
    );
  }

  TournamentMatch? _findMatch(List<TournamentMatch> list, int round, int pos) {
    try {
      return list.firstWhere((m) => m.roundNumber == round && m.bracketPosition == pos);
    } catch (_) {
      return null;
    }
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: _neon,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildMainBracket(
    BuildContext context,
    TournamentMatch? sf1,
    TournamentMatch? sf2,
    TournamentMatch? final_,
    TournamentMatch? third,
  ) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // LEFT: Semis
          Expanded(
            child: Column(
              children: [
                _matchLabel('1/2 финала'),
                if (sf1 != null) _buildCard(context, sf1, '1/2 финала', pos: 0),
                const SizedBox(height: 8),
                if (sf2 != null) _buildCard(context, sf2, '1/2 финала', pos: 1),
              ],
            ),
          ),
          // CENTER: connectors
          _buildConnectors(),
          // RIGHT: Final + 3rd
          Expanded(
            child: Column(
              children: [
                _matchLabel('Финал'),
                if (final_ != null) _buildCard(context, final_, 'Финал 🏆', isFinal: true),
                const SizedBox(height: 8),
                _matchLabel('За 3 место'),
                if (third != null) _buildCard(context, third, 'За 3 место 🥉'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlacementBracket(
    BuildContext context,
    TournamentMatch? sf5,
    TournamentMatch? sf6,
    TournamentMatch? fifth,
    TournamentMatch? seventh,
  ) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Column(
              children: [
                _matchLabel('Полуфиналы 5-8'),
                if (sf5 != null) _buildCard(context, sf5, '1/2 за 5-8', pos: 2),
                const SizedBox(height: 8),
                if (sf6 != null) _buildCard(context, sf6, '1/2 за 5-8', pos: 3),
              ],
            ),
          ),
          _buildConnectors(),
          Expanded(
            child: Column(
              children: [
                _matchLabel('За 5-6 место'),
                if (fifth != null) _buildCard(context, fifth, 'За 5-6 место'),
                const SizedBox(height: 8),
                _matchLabel('За 7-8 место'),
                if (seventh != null) _buildCard(context, seventh, 'За 7-8 место'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _matchLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.4),
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildConnectors() {
    return SizedBox(
      width: 32,
      child: CustomPaint(
        painter: _ConnectorPainter(),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    TournamentMatch match,
    String stageLabel, {
    bool isFinal = false,
    int? pos,
  }) {
    final bool isFinished = match.status == 'FINISHED' || match.status == 'finished';
    final bool isLive = match.status == 'LIVE';
    final bool hasHomeWon = isFinished && match.homeScore > match.awayScore;
    final bool hasAwayWon = isFinished && match.awayScore > match.homeScore;

    String homeName = match.homeTeamName ?? _placeholder(match.roundNumber, match.bracketPosition, true);
    String awayName = match.awayTeamName ?? _placeholder(match.roundNumber, match.bracketPosition, false);
    // Treat backend "Home Team" / "Away Team" as placeholder
    if (homeName == 'Home Team') homeName = _placeholder(match.roundNumber, match.bracketPosition, true);
    if (awayName == 'Away Team') awayName = _placeholder(match.roundNumber, match.bracketPosition, false);

    final bool homeIsPlaceholder = match.homeTeamName == null || match.homeTeamName == 'Home Team';
    final bool awayIsPlaceholder = match.awayTeamName == null || match.awayTeamName == 'Away Team';

    final Color cardBg = isFinal
        ? const Color(0xFF1A2835)
        : const Color(0xFF141E28);
    final Color borderColor = isFinal
        ? _neon.withValues(alpha: 0.3)
        : isLive
            ? _neon
            : Colors.white.withValues(alpha: 0.08);

    final String dateStr = match.matchDate != null
        ? DateFormat('dd.MM HH:mm').format(match.matchDate!.toLocal())
        : '–';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MatchCenterScreen(
              matchId: match.id,
              tournamentId: tournamentId,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: isFinal ? 1.5 : 1.0),
          boxShadow: isFinal
              ? [BoxShadow(color: _neon.withValues(alpha: 0.08), blurRadius: 12, spreadRadius: 0)]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stage label
            Text(
              stageLabel.toUpperCase(),
              style: TextStyle(
                color: isFinal ? _neon : Colors.white.withValues(alpha: 0.35),
                fontSize: 8,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 6),
            // Home team row
            _teamRow(homeName, isFinished ? '${match.homeScore}' : '–', homeIsPlaceholder, hasHomeWon),
            const SizedBox(height: 4),
            // Divider with score
            if (isFinished)
              Center(
                child: Text(
                  '${match.homeScore} : ${match.awayScore}',
                  style: const TextStyle(color: _neon, fontSize: 11, fontWeight: FontWeight.w900),
                ),
              )
            else
              Divider(color: Colors.white.withValues(alpha: 0.06), height: 8),
            const SizedBox(height: 4),
            // Away team row
            _teamRow(awayName, isFinished ? '${match.awayScore}' : '–', awayIsPlaceholder, hasAwayWon),
            const SizedBox(height: 6),
            // Date row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (isLive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: _neon.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: const Text('LIVE', style: TextStyle(color: _neon, fontSize: 8, fontWeight: FontWeight.bold)),
                  )
                else
                  Text(
                    dateStr,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.35),
                      fontSize: 9,
                    ),
                  ),
                if (match.fieldName != null)
                  Text(
                    match.fieldName!,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.25), fontSize: 8),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _teamRow(String name, String score, bool isPlaceholder, bool isWinner) {
    return Row(
      children: [
        Icon(
          isWinner ? Icons.star : Icons.shield_outlined,
          size: 12,
          color: isWinner ? const Color(0xFFFFD700) : Colors.white.withValues(alpha: 0.3),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            name.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isPlaceholder
                  ? Colors.white.withValues(alpha: 0.25)
                  : isWinner
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.8),
              fontSize: 11,
              fontWeight: isWinner ? FontWeight.w800 : FontWeight.w500,
              fontStyle: isPlaceholder ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ),
        if (!isPlaceholder)
          Text(
            score,
            style: TextStyle(
              color: isWinner ? const Color(0xFFFFD700) : Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
  }

  String _placeholder(int? round, int? pos, bool isHome) {
    if (round == 1) {
      if (pos == 0) return isHome ? 'A1' : 'B2';
      if (pos == 1) return isHome ? 'B1' : 'A2';
      if (pos == 2) return isHome ? 'A3' : 'B4';
      if (pos == 3) return isHome ? 'B3' : 'A4';
    } else if (round == 2) {
      if (pos == 0) return isHome ? 'Победитель ПФ1' : 'Победитель ПФ2';
      if (pos == 1) return isHome ? 'Проигравший ПФ1' : 'Проигравший ПФ2';
      if (pos == 2) return isHome ? 'Победитель ПФ3' : 'Победитель ПФ4';
      if (pos == 3) return isHome ? 'Проигравший ПФ3' : 'Проигравший ПФ4';
    }
    return 'TBD';
  }
}

/// Simple bracket connector lines painter
class _ConnectorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final double midX = size.width / 2;
    final double topY = size.height * 0.25;
    final double bottomY = size.height * 0.75;
    final double midY = size.height * 0.5;

    // Top horizontal out from left
    canvas.drawLine(Offset(0, topY), Offset(midX, topY), paint);
    // Bottom horizontal out from left
    canvas.drawLine(Offset(0, bottomY), Offset(midX, bottomY), paint);
    // Vertical connector
    canvas.drawLine(Offset(midX, topY), Offset(midX, bottomY), paint);
    // Horizontal out to right at middle
    canvas.drawLine(Offset(midX, midY), Offset(size.width, midY), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Keep legacy function name for backward compat
String getPlayoffPlaceholderName(TournamentMatch match, bool isHome) {
  if (match.roundNumber == 1) {
    if (match.bracketPosition == 0) return isHome ? 'A1' : 'B2';
    if (match.bracketPosition == 1) return isHome ? 'B1' : 'A2';
    if (match.bracketPosition == 2) return isHome ? 'A3' : 'B4';
    if (match.bracketPosition == 3) return isHome ? 'B3' : 'A4';
  } else if (match.roundNumber == 2) {
    if (match.bracketPosition == 0) return isHome ? 'Победитель ПФ1' : 'Победитель ПФ2';
    if (match.bracketPosition == 1) return isHome ? 'Проигравший ПФ1' : 'Проигравший ПФ2';
  }
  return 'TBD';
}
