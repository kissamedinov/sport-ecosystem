import os

def main():
    filepath = 'lib/features/tournaments/presentation/screens/tournament_details_page.dart'
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Append helpers to the very end of the file if they are not already there
    helpers = """

String _cleanGroupName(String? groupName, String? groupId) {
  if (groupId != null && _TournamentDetailsPageState._groupLettersMap.containsKey(groupId)) {
    return _TournamentDetailsPageState._groupLettersMap[groupId]!;
  }
  if (groupName != null && _TournamentDetailsPageState._groupLettersMap.containsKey(groupName)) {
    return _TournamentDetailsPageState._groupLettersMap[groupName]!;
  }
  final name = groupName ?? groupId;
  if (name == null) return "A";
  final upper = name.toUpperCase();
  if (upper.startsWith("GROUP") || upper.startsWith("ГРУППА")) {
    final parts = name.split(" ");
    if (parts.length > 1) {
      final letter = parts.last.toUpperCase();
      if (letter == "A" || letter == "А") return "A";
      if (letter == "B" || letter == "Б") return "B";
      return letter;
    }
  }
  if (name.length > 8) {
    return name.split("-").last.toUpperCase();
  }
  return name.toUpperCase();
}

String _getPlayoffPlaceholderName(TournamentMatch match, bool isHome) {
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
}
"""

    if "String _cleanGroupName" not in content:
        content = content.rstrip() + helpers
        print("Helpers appended successfully!")
    else:
        print("Helpers already exist!")

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Done!")

if __name__ == '__main__':
    main()
