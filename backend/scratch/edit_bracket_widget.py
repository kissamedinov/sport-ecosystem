import os

def main():
    filepath = 'lib/features/tournaments/presentation/widgets/tournament_bracket_widget.dart'
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. Append getPlayoffPlaceholderName helper at bottom of the file
    target1 = """  @override
  bool shouldRepaint(covariant BracketConnectorsPainter oldDelegate) {
    return oldDelegate.roundMatches != roundMatches || oldDelegate.sortedRounds != sortedRounds;
  }
}"""
    
    replacement1 = """  @override
  bool shouldRepaint(covariant BracketConnectorsPainter oldDelegate) {
    return oldDelegate.roundMatches != roundMatches || oldDelegate.sortedRounds != sortedRounds;
  }
}

String getPlayoffPlaceholderName(TournamentMatch match, bool isHome) {
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
  return 'tournament.awaiting_winner'.tr();
}"""

    if target1 in content and "getPlayoffPlaceholderName" not in content:
        content = content.replace(target1, replacement1)
        print("Helper function appended!")

    # 2. Replace homeTeamName fallback
    target2 = "match.homeTeamName ?? 'tournament.awaiting_winner'.tr(),"
    replacement2 = "match.homeTeamName ?? getPlayoffPlaceholderName(match, true),"
    if target2 in content:
        content = content.replace(target2, replacement2)
        print("Home team fallback updated!")

    # 3. Replace awayTeamName fallback
    target3 = "match.awayTeamName ?? 'tournament.awaiting_winner'.tr(),"
    replacement3 = "match.awayTeamName ?? getPlayoffPlaceholderName(match, false),"
    if target3 in content:
        content = content.replace(target3, replacement3)
        print("Away team fallback updated!")

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Done editing tournament_bracket_widget.dart!")

if __name__ == '__main__':
    main()
