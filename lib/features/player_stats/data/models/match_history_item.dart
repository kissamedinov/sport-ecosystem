class MatchHistoryItem {
  final String matchId;
  final String tournamentName;
  final String opponent;
  final int goals;
  final int assists;
  final int yellowCards;
  final int redCards;
  final bool isBestPlayer;
  final DateTime? date;

  MatchHistoryItem({
    required this.matchId,
    required this.tournamentName,
    required this.opponent,
    required this.goals,
    required this.assists,
    required this.yellowCards,
    required this.redCards,
    required this.isBestPlayer,
    this.date,
  });

  factory MatchHistoryItem.fromJson(Map<String, dynamic> json) {
    return MatchHistoryItem(
      matchId: json['match_id'],
      tournamentName: json['tournament_name'] ?? 'Unknown Tournament',
      opponent: json['opponent'] ?? 'Unknown Opponent',
      goals: json['goals'] ?? 0,
      assists: json['assists'] ?? 0,
      yellowCards: json['yellow_cards'] ?? 0,
      redCards: json['red_cards'] ?? 0,
      isBestPlayer: json['is_best_player'] ?? false,
      date: json['date'] != null ? DateTime.tryParse(json['date']) : null,
    );
  }
}
