class QuizQuestion {
  final String id;
  final String text;
  final List<String> options;
  final int correctIndex;
  final String? explanation;

  QuizQuestion({
    required this.id,
    required this.text,
    required this.options,
    required this.correctIndex,
    this.explanation,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id'],
      text: json['question_text'],
      options: List<String>.from(json['options']),
      correctIndex: json['correct_option_index'],
      explanation: json['explanation'],
    );
  }
}

class DailyQuiz {
  final String id;
  final DateTime date;
  final List<QuizQuestion> questions;
  final Map<String, dynamic>? userAttempt;
  final int userStreak;
  final int userPoints;
  final int userRank;

  DailyQuiz({
    required this.id,
    required this.date,
    required this.questions,
    this.userAttempt,
    this.userStreak = 0,
    this.userPoints = 0,
    this.userRank = 0,
  });

  factory DailyQuiz.fromJson(Map<String, dynamic> json) {
    return DailyQuiz(
      id: json['id'],
      date: DateTime.parse(json['date']),
      questions: (json['questions'] as List)
          .map((q) => QuizQuestion.fromJson(q))
          .toList(),
      userAttempt: json['user_attempt'],
      userStreak: json['user_streak'] ?? 0,
      userPoints: json['user_points'] ?? 0,
      userRank: json['user_rank'] ?? 0,
    );
  }
}

class QuizLeaderboardEntry {
  final int rank;
  final String name;
  final int points;
  final int streak;
  final String userId;

  QuizLeaderboardEntry({
    required this.rank,
    required this.name,
    required this.points,
    required this.streak,
    required this.userId,
  });

  factory QuizLeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return QuizLeaderboardEntry(
      rank: json['rank'] as int,
      name: json['name'] as String,
      points: json['points'] as int,
      streak: json['streak'] as int,
      userId: json['user_id'] as String,
    );
  }
}
