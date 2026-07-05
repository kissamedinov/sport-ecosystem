import os

def main():
    filepath = 'lib/features/tournaments/presentation/widgets/shareable_schedule_dialog.dart'
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. Update _buildMatchRow to render playoff placeholders and scores on the right
    target_match_row = """  // 1-Field Layout Row
  Widget _buildMatchRow(TournamentMatch match) {
    final timeStr = match.matchDate != null ? DateFormat('HH:mm').format(match.matchDate!.toLocal()) : 'TBD';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _itemBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _itemBorderColor),
      ),
      child: Row(
        children: [
          // Time badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: PremiumTheme.neonGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              timeStr,
              style: const TextStyle(color: PremiumTheme.neonGreen, fontWeight: FontWeight.w900, fontSize: 11),
            ),
          ),
          const SizedBox(width: 14),
          // Teams
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.shield, size: 12, color: _mutedTextColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        match.homeTeamName ?? 'tournament.awaiting_winner'.tr(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: match.homeTeamName == null ? _mutedTextColor.withValues(alpha: 0.5) : _secondaryTextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.shield_outlined, size: 12, color: _mutedTextColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        match.awayTeamName ?? 'tournament.awaiting_winner'.tr(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: match.awayTeamName == null ? _mutedTextColor.withValues(alpha: 0.5) : _secondaryTextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }"""

    replacement_match_row = """  // 1-Field Layout Row
  Widget _buildMatchRow(TournamentMatch match) {
    final timeStr = match.matchDate != null ? DateFormat('HH:mm').format(match.matchDate!.toLocal()) : 'TBD';
    final homePlaceholder = _getPlayoffPlaceholder(match, true);
    final awayPlaceholder = _getPlayoffPlaceholder(match, false);
    final homeName = match.homeTeamName ?? homePlaceholder;
    final awayName = match.awayTeamName ?? awayPlaceholder;
    final isFinished = match.status == 'FINISHED';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _itemBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _itemBorderColor),
      ),
      child: Row(
        children: [
          // Time badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: PremiumTheme.neonGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              timeStr,
              style: const TextStyle(color: PremiumTheme.neonGreen, fontWeight: FontWeight.w900, fontSize: 11),
            ),
          ),
          const SizedBox(width: 14),
          // Teams
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.shield, size: 12, color: _mutedTextColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        homeName.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: match.homeTeamName == null ? _mutedTextColor.withValues(alpha: 0.5) : _secondaryTextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.shield_outlined, size: 12, color: _mutedTextColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        awayName.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: match.awayTeamName == null ? _mutedTextColor.withValues(alpha: 0.5) : _secondaryTextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Scores column
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                isFinished ? '${match.homeScore}' : '-',
                style: TextStyle(
                  color: isFinished ? PremiumTheme.neonGreen : _secondaryTextColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isFinished ? '${match.awayScore}' : '-',
                style: TextStyle(
                  color: isFinished ? PremiumTheme.neonGreen : _secondaryTextColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }"""

    if target_match_row in content:
        content = content.replace(target_match_row, replacement_match_row)
        print("Match row updated!")
    else:
        print("Match row target not found!")

    # 2. Update _buildCompactMatchCard to show placeholder names and score (matching bottom: 10)
    target_compact = """  // Multi-Field Layout Card
  Widget _buildCompactMatchCard(TournamentMatch match) {
    final timeStr = match.matchDate != null ? DateFormat('HH:mm').format(match.matchDate!.toLocal()) : 'TBD';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _itemBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _itemBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Time
          Text(
            timeStr,
            style: const TextStyle(color: PremiumTheme.neonGreen, fontWeight: FontWeight.bold, fontSize: 10),
          ),
          const SizedBox(height: 6),
          // Home
          Text(
            match.homeTeamName ?? 'TBD',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: match.homeTeamName == null ? _mutedTextColor.withValues(alpha: 0.5) : _secondaryTextColor,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'vs',
            style: TextStyle(color: _mutedTextColor, fontSize: 7, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 2),
          // Away
          Text(
            match.awayTeamName ?? 'TBD',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: match.awayTeamName == null ? _mutedTextColor.withValues(alpha: 0.5) : _secondaryTextColor,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }"""

    replacement_compact = """  // Multi-Field Layout Card
  Widget _buildCompactMatchCard(TournamentMatch match) {
    final timeStr = match.matchDate != null ? DateFormat('HH:mm').format(match.matchDate!.toLocal()) : 'TBD';
    final homePlaceholder = _getPlayoffPlaceholder(match, true);
    final awayPlaceholder = _getPlayoffPlaceholder(match, false);
    final homeName = match.homeTeamName ?? homePlaceholder;
    final awayName = match.awayTeamName ?? awayPlaceholder;
    final isFinished = match.status == 'FINISHED';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _itemBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _itemBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Time
          Text(
            timeStr,
            style: const TextStyle(color: PremiumTheme.neonGreen, fontWeight: FontWeight.bold, fontSize: 10),
          ),
          const SizedBox(height: 6),
          // Home
          Text(
            homeName.toUpperCase(),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: match.homeTeamName == null ? _mutedTextColor.withValues(alpha: 0.5) : _secondaryTextColor,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            isFinished ? '${match.homeScore} : ${match.awayScore}' : 'vs',
            style: TextStyle(
              color: isFinished ? PremiumTheme.neonGreen : _mutedTextColor,
              fontSize: isFinished ? 9 : 7,
              fontWeight: isFinished ? FontWeight.bold : FontWeight.normal,
              fontStyle: isFinished ? FontStyle.normal : FontStyle.italic,
            ),
          ),
          const SizedBox(height: 2),
          // Away
          Text(
            awayName.toUpperCase(),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: match.awayTeamName == null ? _mutedTextColor.withValues(alpha: 0.5) : _secondaryTextColor,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }"""

    if target_compact in content:
        content = content.replace(target_compact, replacement_compact)
        print("Compact card updated!")
    else:
        print("Compact card target not found!")

    # 3. Append _getPlayoffPlaceholder helper before the last closing brace
    class_end = "}"
    idx = content.rfind(class_end)
    if idx != -1:
        helper_code = """  String _getPlayoffPlaceholder(TournamentMatch match, bool isHome) {
    if (match.groupId != null) return 'Awaiting';
    if (match.roundNumber == 1) {
      if (match.bracketPosition == 0) {
        return isHome ? "A1" : "B2";
      } else if (match.bracketPosition == 1) {
        return isHome ? "B1" : "A2";
      } else if (match.bracketPosition == 2) {
        return isHome ? "A3" : "B3";
      } else if (match.bracketPosition == 3) {
        return isHome ? "A4" : "B4";
      }
    } else if (match.roundNumber == 2) {
      if (match.bracketPosition == 0) {
        return isHome ? "Победитель ПФ1" : "Победитель ПФ2";
      } else if (match.bracketPosition == 1) {
        return isHome ? "Проигравший ПФ1" : "Проигравший ПФ2";
      }
    }
    return 'Awaiting';
  }
}"""
        content = content[:idx] + helper_code
        print("Placeholder helper appended!")
    else:
        print("Closing brace not found!")

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Done!")

if __name__ == '__main__':
    main()
