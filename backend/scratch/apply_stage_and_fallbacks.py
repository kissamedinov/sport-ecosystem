import os

def main():
    # 1. Update shareable_schedule_dialog.dart
    filepath_dialog = 'lib/features/tournaments/presentation/widgets/shareable_schedule_dialog.dart'
    with open(filepath_dialog, 'r', encoding='utf-8') as f:
        content_dialog = f.read()

    # Add stage name helper if not present
    stage_helper = """  String _getMatchStageName(BuildContext context, TournamentMatch match) {
    if (match.groupId != null) {
      final provider = context.read<TournamentProvider>();
      TournamentStanding? standing;
      for (var s in provider.standings) {
        if (s.groupId == match.groupId) {
          standing = s;
          break;
        }
      }
      final clean = (standing != null && standing.groupName != null) ? standing.groupName! : 'Группа';
      if (clean.length > 8) {
        return 'Группа ' + clean.split("-").last.toUpperCase();
      }
      return 'Группа ' + clean.toUpperCase();
    }
    if (match.roundNumber == 1) {
      if (match.bracketPosition == 0 || match.bracketPosition == 1) {
        return '1/2 финала';
      } else if (match.bracketPosition == 2) {
        return 'За 5-6 место';
      } else if (match.bracketPosition == 3) {
        return 'За 7-8 место';
      }
    } else if (match.roundNumber == 2) {
      if (match.bracketPosition == 0) {
        return 'Финал';
      } else if (match.bracketPosition == 1) {
        return 'За 3 место';
      }
    }
    return 'Плей-офф';
  }
"""

    if "_getMatchStageName" not in content_dialog:
        # Insert before the last brace
        idx = content_dialog.rfind("}")
        if idx != -1:
            content_dialog = content_dialog[:idx] + stage_helper + "}\n"
            print("Stage helper added to dialog!")

    # Fix the homeName / awayName to check for 'Home Team' / 'Away Team'
    target_names = """    final homePlaceholder = _getPlayoffPlaceholder(match, true);
    final awayPlaceholder = _getPlayoffPlaceholder(match, false);
    final homeName = match.homeTeamName ?? homePlaceholder;
    final awayName = match.awayTeamName ?? awayPlaceholder;"""

    replacement_names = """    final homePlaceholder = _getPlayoffPlaceholder(match, true);
    final awayPlaceholder = _getPlayoffPlaceholder(match, false);
    final homeName = (match.homeTeamName == null || match.homeTeamName == 'Home Team') ? homePlaceholder : match.homeTeamName!;
    final awayName = (match.awayTeamName == null || match.awayTeamName == 'Away Team') ? awayPlaceholder : match.awayTeamName!;"""

    if target_names in content_dialog:
        content_dialog = content_dialog.replace(target_names, replacement_names)
        print("Dialog placeholder fallbacks updated!")

    # In compact card as well:
    target_names_compact = """    final homePlaceholder = _getPlayoffPlaceholder(match, true);
    final awayPlaceholder = _getPlayoffPlaceholder(match, false);
    final homeName = match.homeTeamName ?? homePlaceholder;
    final awayName = match.awayTeamName ?? awayPlaceholder;"""

    if target_names_compact in content_dialog:
        content_dialog = content_dialog.replace(target_names_compact, replacement_names)

    # Insert stage indicator above home team name in _buildMatchRow
    target_match_row_design = """          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.shield, size: 12, color: _mutedTextColor),"""

    replacement_match_row_design = """          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getMatchStageName(context, match).toUpperCase(),
                  style: const TextStyle(
                    color: PremiumTheme.neonGreen,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.shield, size: 12, color: _mutedTextColor),"""

    if target_match_row_design in content_dialog:
        content_dialog = content_dialog.replace(target_match_row_design, replacement_match_row_design)
        print("Stage label added to dialog match row!")

    # Insert stage indicator in _buildCompactMatchCard
    target_compact_design = """          // Time
          Text(
            timeStr,
            style: const TextStyle(color: PremiumTheme.neonGreen, fontWeight: FontWeight.bold, fontSize: 10),
          ),
          const SizedBox(height: 6),"""

    replacement_compact_design = """          // Time
          Text(
            timeStr,
            style: const TextStyle(color: PremiumTheme.neonGreen, fontWeight: FontWeight.bold, fontSize: 10),
          ),
          const SizedBox(height: 2),
          Text(
            _getMatchStageName(context, match).toUpperCase(),
            style: TextStyle(
              color: _mutedTextColor.withValues(alpha: 0.6),
              fontSize: 7,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),"""

    if target_compact_design in content_dialog:
        content_dialog = content_dialog.replace(target_compact_design, replacement_compact_design)
        print("Stage label added to dialog compact card!")

    with open(filepath_dialog, 'w', encoding='utf-8') as f:
        f.write(content_dialog)


    # 2. Update tournament_details_page.dart
    filepath_details = 'lib/features/tournaments/presentation/screens/tournament_details_page.dart'
    with open(filepath_details, 'r', encoding='utf-8') as f:
        content_details = f.read()

    # Append stage name helper at bottom of the file if not present
    details_stage_helper = """

String _getMatchStageName(TournamentMatch match) {
  if (match.groupId != null) {
    final clean = _cleanGroupName(null, match.groupId);
    return 'Группа $clean';
  }
  if (match.roundNumber == 1) {
    if (match.bracketPosition == 0 || match.bracketPosition == 1) {
      return '1/2 финала';
    } else if (match.bracketPosition == 2) {
      return 'За 5-6 место';
    } else if (match.bracketPosition == 3) {
      return 'За 7-8 место';
    }
  } else if (match.roundNumber == 2) {
    if (match.bracketPosition == 0) {
      return 'Финал';
    } else if (match.bracketPosition == 1) {
      return 'За 3 место';
    }
  }
  return 'Плей-офф';
}
"""

    if "_getMatchStageName" not in content_details:
        content_details = content_details.rstrip() + details_stage_helper
        print("Stage helper added to details page!")

    # Fix placeholder check in _buildMatchItem
    target_names_details = """                              (match.homeTeamName ?? _getPlayoffPlaceholderName(match, true)).toUpperCase(),"""
    replacement_names_details = """                              ((match.homeTeamName == null || match.homeTeamName == 'Home Team') ? _getPlayoffPlaceholderName(match, true) : match.homeTeamName!).toUpperCase(),"""
    
    if target_names_details in content_details:
        content_details = content_details.replace(target_names_details, replacement_names_details)
        print("Details page home fallback updated!")

    target_away_details = """                              (match.awayTeamName ?? _getPlayoffPlaceholderName(match, false)).toUpperCase(),"""
    replacement_away_details = """                              ((match.awayTeamName == null || match.awayTeamName == 'Away Team') ? _getPlayoffPlaceholderName(match, false) : match.awayTeamName!).toUpperCase(),"""

    if target_away_details in content_details:
        content_details = content_details.replace(target_away_details, replacement_away_details)
        print("Details page away fallback updated!")

    # Insert stage indicator in _buildMatchItem next to the date
    target_match_item_design = """                    Text(
                      dateStr,
                      style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5), fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),"""

    replacement_match_item_design = """                    Text(
                      dateStr,
                      style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5), fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: cs.onSurface.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _getMatchStageName(match).toUpperCase(),
                        style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.5),
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),"""

    if target_match_item_design in content_details:
        content_details = content_details.replace(target_match_item_design, replacement_match_item_design)
        print("Stage label added to details match list item!")

    with open(filepath_details, 'w', encoding='utf-8') as f:
        f.write(content_details)

    print("All stages and fallback changes applied successfully!")

if __name__ == '__main__':
    main()
