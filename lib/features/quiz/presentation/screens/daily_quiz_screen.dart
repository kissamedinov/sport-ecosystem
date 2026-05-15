import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:mobile/core/theme/premium_theme.dart';
import 'package:mobile/core/presentation/widgets/orleon_widgets.dart';
import '../../providers/quiz_provider.dart';
import '../../data/models/quiz_model.dart';

class DailyQuizScreen extends StatefulWidget {
  const DailyQuizScreen({super.key});

  @override
  State<DailyQuizScreen> createState() => _DailyQuizScreenState();
}

class _DailyQuizScreenState extends State<DailyQuizScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  int _score = 0;
  int? _selectedOption;
  bool _isAnswered = false;
  bool _isFinished = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuizProvider>().fetchDailyQuiz();
    });
  }

  void _handleAnswer(int index, int correctIndex) {
    if (_isAnswered) return;

    setState(() {
      _selectedOption = index;
      _isAnswered = true;
      if (index == correctIndex) {
        _score++;
        HapticFeedback.lightImpact();
      } else {
        HapticFeedback.heavyImpact();
      }
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (_currentPage < 6) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
        setState(() {
          _currentPage++;
          _selectedOption = null;
          _isAnswered = false;
        });
      } else {
        setState(() {
          _isFinished = true;
        });
        context.read<QuizProvider>().submitScore(_score);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PremiumTheme.surfaceBase(context),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.2,
            colors: [
              PremiumTheme.neonGreen.withValues(alpha: 0.05),
              PremiumTheme.surfaceBase(context),
            ],
          ),
        ),
        child: SafeArea(
          child: Consumer<QuizProvider>(
            builder: (context, provider, _) {
              if (provider.isLoading) {
                return const Center(child: CircularProgressIndicator(color: PremiumTheme.neonGreen));
              }
              if (provider.error != null) {
                return _buildErrorState(provider.error!);
              }
              if (provider.currentQuiz == null) {
                return const Center(child: Text("No quiz available"));
              }

              if (_isFinished) return _buildResultScreen();

              final questions = provider.currentQuiz!.questions;
              return Column(
                children: [
                  _buildHeader(questions.length),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: questions.length,
                      itemBuilder: (context, index) {
                        return _buildQuestionPage(questions[index]);
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(int total) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
                onPressed: () => Navigator.pop(context),
              ),
              Text(
                "DAILY KICK-OFF QUIZ",
                style: TextStyle(
                  color: PremiumTheme.neonGreen.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(width: 48), // Spacer
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: List.generate(total, (index) {
              bool isPassed = index < _currentPage;
              bool isCurrent = index == _currentPage;
              return Expanded(
                child: Container(
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: isPassed 
                        ? PremiumTheme.neonGreen 
                        : (isCurrent ? PremiumTheme.neonGreen.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.1)),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionPage(QuizQuestion question) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          OrleonCard(
            padding: const EdgeInsets.all(24),
            child: Text(
              question.text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 40),
          ...List.generate(question.options.length, (index) {
            final optionText = question.options[index];
            bool isCorrect = index == question.correctIndex;
            bool isSelected = index == _selectedOption;
            
            Color borderColor = Colors.white.withValues(alpha: 0.1);
            Color bgColor = Colors.white.withValues(alpha: 0.05);
            
            if (_isAnswered) {
              if (isCorrect) {
                borderColor = PremiumTheme.neonGreen;
                bgColor = PremiumTheme.neonGreen.withValues(alpha: 0.1);
              } else if (isSelected) {
                borderColor = Colors.redAccent;
                bgColor = Colors.redAccent.withValues(alpha: 0.1);
              }
            } else if (isSelected) {
              borderColor = PremiumTheme.neonGreen.withValues(alpha: 0.5);
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => _handleAnswer(index, question.correctIndex),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor, width: 2),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: borderColor),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          String.fromCharCode(65 + index),
                          style: TextStyle(
                            color: isSelected || (isCorrect && _isAnswered) ? borderColor : Colors.white38,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          optionText,
                          style: TextStyle(
                            color: isSelected || (isCorrect && _isAnswered) ? Colors.white : Colors.white70,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (_isAnswered && isCorrect)
                        const Icon(Icons.check_circle, color: PremiumTheme.neonGreen, size: 20),
                      if (_isAnswered && isSelected && !isCorrect)
                        const Icon(Icons.cancel, color: Colors.redAccent, size: 20),
                    ],
                  ),
                ),
              ),
            );
          }),
          if (_isAnswered && question.explanation != null) ...[
            const SizedBox(height: 20),
            Text(
              "TIP: ${question.explanation}",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: PremiumTheme.neonGreen.withValues(alpha: 0.7),
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "⚽",
              style: TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 24),
            const Text(
              "WORKOUT COMPLETE!",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "You scored $_score out of 7 points today",
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 48),
            OrleonCard(
              padding: const EdgeInsets.all(24),
              gradient: LinearGradient(
                colors: [
                  PremiumTheme.neonGreen.withValues(alpha: 0.2),
                  PremiumTheme.neonGreen.withValues(alpha: 0.05),
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.bolt, color: PremiumTheme.neonGreen, size: 32),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "DAILY STREAK: 1 DAY",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          "Come back tomorrow for +50 XP",
                          style: TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: PremiumTheme.neonGreen,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text("BACK TO PROFILE", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.redAccent, size: 48),
          const SizedBox(height: 16),
          const Text("CONNECTION ERROR", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(error, style: const TextStyle(color: Colors.white38, fontSize: 12), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () => context.read<QuizProvider>().fetchDailyQuiz(),
            child: const Text("RETRY", style: TextStyle(color: PremiumTheme.neonGreen)),
          ),
        ],
      ),
    );
  }
}
