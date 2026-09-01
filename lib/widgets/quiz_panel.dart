import 'package:flutter/material.dart';

import '../data/quiz_data.dart';
import '../theme/app_theme.dart';
import '../utils/app_prefs.dart';

class QuizPanel extends StatefulWidget {
  const QuizPanel({super.key});

  @override
  State<QuizPanel> createState() => _QuizPanelState();
}

class _QuizPanelState extends State<QuizPanel> {
  int _currentQuestion = 0;
  int _score = 0;
  bool _showScore = false;
  int? _bestScore;
  final List<String?> _userAnswers = List.filled(quizQuestions.length, null);

  @override
  void initState() {
    super.initState();
    AppPrefs.loadBestScore().then((value) {
      if (mounted) setState(() => _bestScore = value);
    });
  }

  void _handleAnswer(String answer) {
    setState(() {
      final wasAnswered = _userAnswers[_currentQuestion] != null;
      _userAnswers[_currentQuestion] = answer;
      if (!wasAnswered && answer == quizQuestions[_currentQuestion].correctAnswer) {
        _score++;
      }
    });
  }

  void _goNext() {
    if (_currentQuestion < quizQuestions.length - 1) {
      setState(() => _currentQuestion++);
    } else if (_userAnswers.every((a) => a != null)) {
      setState(() => _showScore = true);
      AppPrefs.saveBestScoreIfHigher(_score).then((_) {
        AppPrefs.loadBestScore().then((value) {
          if (mounted) setState(() => _bestScore = value);
        });
      });
    }
  }

  void _goPrevious() {
    if (_currentQuestion > 0) {
      setState(() => _currentQuestion--);
    }
  }

  void _reset() {
    setState(() {
      _currentQuestion = 0;
      _score = 0;
      _showScore = false;
      for (var i = 0; i < _userAnswers.length; i++) {
        _userAnswers[i] = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      children: [
        const Text(
          'Solar System Quiz',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.primary),
        ),
        const SizedBox(height: 20),
        if (_showScore) _buildScoreCard() else _buildQuestionCard(),
      ],
    );
  }

  Widget _buildScoreCard() {
    final message = _score == quizQuestions.length
        ? "Perfect score! You're a solar system expert! 🌟"
        : _score >= quizQuestions.length / 2
            ? 'Good job! Keep learning about our solar system! 🌎'
            : 'Keep exploring and learning about our solar system! 🚀';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quiz Complete!', style: TextStyle(fontSize: 22, color: Colors.white)),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _score / quizQuestions.length,
              minHeight: 8,
              backgroundColor: Colors.white12,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text('Your score: $_score out of ${quizQuestions.length}',
              style: const TextStyle(fontSize: 18, color: Colors.white)),
          if (_bestScore != null) ...[
            const SizedBox(height: 4),
            Text(
              _bestScore == _score && _score > 0
                  ? 'That\'s your best score yet! 🏆'
                  : 'Best score: $_bestScore out of ${quizQuestions.length}',
              style: const TextStyle(fontSize: 13, color: AppColors.primary),
            ),
          ],
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: Color(0xFFD1D5DB))),
          const SizedBox(height: 20),
          const Text('Review Your Answers:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
          const SizedBox(height: 12),
          ...List.generate(quizQuestions.length, (index) {
            final q = quizQuestions[index];
            final correct = _userAnswers[index] == q.correctAnswer;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: correct
                    ? const Color(0xFF22C55E).withValues(alpha: 0.1)
                    : const Color(0xFFEF4444).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(q.question, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text('Your answer: ${_userAnswers[index]}',
                      style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
                  Text('Correct answer: ${q.correctAnswer}',
                      style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          FilledButton(onPressed: _reset, child: const Text('Try Again')),
        ],
      ),
    );
  }

  Widget _buildQuestionCard() {
    final q = quizQuestions[_currentQuestion];
    final answered = _userAnswers[_currentQuestion];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _currentQuestion / quizQuestions.length,
              minHeight: 8,
              backgroundColor: Colors.white12,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(q.question, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
          const SizedBox(height: 16),
          ...q.options.map((option) {
            final isSelected = answered == option;
            final isCorrect = option == q.correctAnswer;
            Color? bg;
            Color fg = Colors.white;
            if (answered != null && isSelected) {
              bg = isCorrect ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: (answered != null && !isSelected) ? null : () => _handleAnswer(option),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: bg,
                    foregroundColor: fg,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Text(option),
                ),
              ),
            );
          }),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton(
                onPressed: _currentQuestion == 0 ? null : _goPrevious,
                child: const Text('Previous'),
              ),
              Text('Question ${_currentQuestion + 1} of ${quizQuestions.length}',
                  style: const TextStyle(color: Color(0xFF9CA3AF))),
              OutlinedButton(
                onPressed: answered == null ? null : _goNext,
                child: Text(_currentQuestion == quizQuestions.length - 1 ? 'Finish' : 'Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
