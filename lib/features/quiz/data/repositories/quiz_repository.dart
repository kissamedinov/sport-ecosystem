import 'package:mobile/core/api/api_client.dart';
import '../models/quiz_model.dart';

class QuizRepository {
  final ApiClient _apiClient;

  QuizRepository(this._apiClient);

  Future<DailyQuiz> getDailyQuiz() async {
    final response = await _apiClient.get('/quizzes/daily');
    return DailyQuiz.fromJson(response.data);
  }

  Future<void> submitQuizAttempt(int score) async {
    await _apiClient.post('/quizzes/daily/submit', data: {
      'score': score,
      'total_questions': 7,
    });
  }
}
