import 'package:flutter/material.dart';
import '../../match_reports/providers/match_report_provider.dart';

class PlayerCareerStats {
  final int matchesPlayed;
  final int totalGoals;
  final int totalAssists;
  final int totalYellowCards;
  final int totalRedCards;
  final int totalMvpAwards;

  PlayerCareerStats({
    this.matchesPlayed = 0,
    this.totalGoals = 0,
    this.totalAssists = 0,
    this.totalYellowCards = 0,
    this.totalRedCards = 0,
    this.totalMvpAwards = 0,
  });
}

class PlayerStatsProvider extends ChangeNotifier {
  final MatchReportProvider _reportProvider;

  PlayerStatsProvider(this._reportProvider);

  PlayerCareerStats getCareerStats(String playerId) {
    int matches = 0;
    int goals = 0;
    int assists = 0;
    int yellow = 0;
    int red = 0;
    int mvps = 0;

    for (final report in _reportProvider.reports) {
      bool played = false;
      for (final stat in report.playerStats) {
        if (stat.playerId == playerId) {
          played = true;
          goals += stat.goals;
          assists += stat.assists;
          yellow += stat.yellowCards;
          red += stat.redCards;
          if (stat.isMvp) mvps++;
        }
      }
      if (played) matches++;
    }

    return PlayerCareerStats(
      matchesPlayed: matches,
      totalGoals: goals,
      totalAssists: assists,
      totalYellowCards: yellow,
      totalRedCards: red,
      totalMvpAwards: mvps,
    );
  }
}
