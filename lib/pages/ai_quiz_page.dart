import 'package:flutter/material.dart';
import '../services/groq_service.dart';
import 'dart:convert';

class AIQuizPage extends StatefulWidget {
  const AIQuizPage({super.key});

  @override
  State<AIQuizPage> createState() => _AIQuizPageState();
}

class _AIQuizPageState extends State<AIQuizPage> {
  final GroqService _groqService = GroqService();
  final TextEditingController _topicController = TextEditingController();
  final TextEditingController _questionCountController = TextEditingController(
    text: '5',
  );

  bool _isLoadingQuestions = false;
  bool _isQuizStarted = false;
  List<AIQuizQuestion> _questions = [];
  int _currentQuestionIndex = 0;
  int _selectedAnswerIndex = -1;
  int _score = 0;
  bool _isAnswered = false;
  bool _isQuizCompleted = false;
  List<int> _userAnswers = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'AI Quiz',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2D2D2D),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: _isQuizCompleted
            ? _buildQuizResults()
            : _isQuizStarted
            ? _buildQuizInterface()
            : _buildQuizSetup(),
      ),
    );
  }

  Widget _buildQuizSetup() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFFA726).withOpacity(0.1),
                  const Color(0xFFFFB74D).withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFFFA726).withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFA726),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFA726).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.psychology_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Create Your AI Quiz',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF2D2D2D),
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Let AI generate personalized quiz questions for you',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Icon(
                Icons.subject_rounded,
                color: const Color(0xFFFFA726),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Topic',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: TextField(
              controller: _topicController,
              decoration: InputDecoration(
                hintText: 'Enter topic (e.g., Physics, Mathematics, History)',
                hintStyle: TextStyle(color: Colors.grey[500]),
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
                prefixIcon: Icon(
                  Icons.subject_rounded,
                  color: const Color(0xFFFFA726),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Icon(
                Icons.quiz_rounded,
                color: const Color(0xFFFFA726),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Number of Questions',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: TextField(
              controller: _questionCountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Enter number of questions (1-10)',
                hintStyle: TextStyle(color: Colors.grey[500]),
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
                prefixIcon: Icon(
                  Icons.quiz_rounded,
                  color: const Color(0xFFFFA726),
                ),
              ),
            ),
          ),
          const Spacer(),
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isLoadingQuestions
                    ? [Colors.grey[400]!, Colors.grey[500]!]
                    : [const Color(0xFFFFA726), const Color(0xFFFFB74D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _isLoadingQuestions
                      ? Colors.grey.withOpacity(0.2)
                      : const Color(0xFFFFA726).withOpacity(0.3),
                  blurRadius: _isLoadingQuestions ? 6 : 12,
                  offset: Offset(0, _isLoadingQuestions ? 2 : 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _isLoadingQuestions ? null : _generateQuiz,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isLoadingQuestions) ...[
                        const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Generating Quiz...',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.psychology_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Generate AI Quiz',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizInterface() {
    final question = _questions[_currentQuestionIndex];

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinearProgressIndicator(
            value: (_currentQuestionIndex + 1) / _questions.length,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFA726)),
          ),
          const SizedBox(height: 16),
          Text(
            'Question ${_currentQuestionIndex + 1} of ${_questions.length}',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            question.question,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D2D2D),
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView.builder(
              itemCount: question.options.length,
              itemBuilder: (context, index) {
                Color borderColor = Colors.grey[300]!;
                Color backgroundColor = Colors.white;

                if (_isAnswered) {
                  if (index == question.correctIndex) {
                    borderColor = Colors.green;
                    backgroundColor = Colors.green.withOpacity(0.1);
                  } else if (index == _selectedAnswerIndex &&
                      index != question.correctIndex) {
                    borderColor = Colors.red;
                    backgroundColor = Colors.red.withOpacity(0.1);
                  }
                } else if (index == _selectedAnswerIndex) {
                  borderColor = const Color(0xFFFFA726);
                  backgroundColor = const Color(0xFFFFA726).withOpacity(0.1);
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    border: Border.all(color: borderColor, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    title: Text(
                      question.options[index],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: _isAnswered ? null : () => _selectAnswer(index),
                    trailing: _isAnswered
                        ? (index == question.correctIndex
                              ? const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                )
                              : (index == _selectedAnswerIndex &&
                                        index != question.correctIndex
                                    ? const Icon(
                                        Icons.cancel,
                                        color: Colors.red,
                                      )
                                    : null))
                        : null,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          if (_isAnswered)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFFFFA726), const Color(0xFFFFB74D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFA726).withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _nextQuestion,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _currentQuestionIndex == _questions.length - 1
                                ? Icons.assessment_rounded
                                : Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _currentQuestionIndex == _questions.length - 1
                              ? 'View Results'
                              : 'Next Question',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuizResults() {
    final percentage = (_score / _questions.length * 100).round();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Results Header Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFFA726).withOpacity(0.1),
                  const Color(0xFFFFB74D).withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFFFA726).withOpacity(0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFA726).withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                // Score Circle
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getResultColor(percentage),
                        _getResultColor(percentage).withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _getResultColor(percentage).withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$percentage%',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Score',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Result Title
                Text(
                  _getResultTitle(percentage),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D2D2D),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You scored $_score out of ${_questions.length} questions correctly',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Statistics Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withOpacity(0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFA726).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.analytics_rounded,
                        color: Color(0xFFFFA726),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Quiz Statistics',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D2D2D),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildStatRow(
                  'Total Questions',
                  '${_questions.length}',
                  Icons.quiz_rounded,
                  const Color(0xFFFFA726),
                ),
                const SizedBox(height: 16),
                _buildStatRow(
                  'Correct Answers',
                  '$_score',
                  Icons.check_circle_rounded,
                  Colors.green,
                ),
                const SizedBox(height: 16),
                _buildStatRow(
                  'Wrong Answers',
                  '${_questions.length - _score}',
                  Icons.cancel_rounded,
                  Colors.red,
                ),
                const SizedBox(height: 16),
                _buildStatRow(
                  'Accuracy Rate',
                  '$percentage%',
                  Icons.track_changes_rounded,
                  _getResultColor(percentage),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Back Button
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFA726), Color(0xFFFFB74D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFA726).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Back to Practice',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _generateQuiz() async {
    if (_topicController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a topic')));
      return;
    }

    final questionCount = int.tryParse(_questionCountController.text) ?? 5;
    if (questionCount < 1 || questionCount > 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Number of questions must be between 1 and 10'),
        ),
      );
      return;
    }

    setState(() {
      _isLoadingQuestions = true;
    });

    try {
      final prompt =
          '''
Generate exactly $questionCount multiple choice questions about "${_topicController.text}".

Format your response as a valid JSON array where each question has:
- "question": the question text
- "options": array of exactly 4 answer choices  
- "correctIndex": index (0-3) of the correct answer
- "explanation": brief explanation of the correct answer

Example format:
[
  {
    "question": "What is 2+2?",
    "options": ["3", "4", "5", "6"],
    "correctIndex": 1,
    "explanation": "2+2 equals 4"
  }
]

Make the questions educational and appropriate difficulty level. Ensure valid JSON format.
''';

      final response = await _groqService.sendMessage(prompt);

      // Try to extract JSON from the response
      String jsonString = response;
      if (response.contains('```json')) {
        final startIndex = response.indexOf('```json') + 7;
        final endIndex = response.indexOf('```', startIndex);
        if (endIndex != -1) {
          jsonString = response.substring(startIndex, endIndex).trim();
        }
      } else if (response.contains('[')) {
        final startIndex = response.indexOf('[');
        final endIndex = response.lastIndexOf(']') + 1;
        if (endIndex > startIndex) {
          jsonString = response.substring(startIndex, endIndex).trim();
        }
      }

      final List<dynamic> questionsJson = json.decode(jsonString);
      final questions = questionsJson
          .map((q) => AIQuizQuestion.fromJson(q))
          .toList();

      setState(() {
        _questions = questions;
        _isLoadingQuestions = false;
        _isQuizStarted = true;
        _currentQuestionIndex = 0;
        _score = 0;
        _userAnswers = List.filled(questions.length, -1);
      });
    } catch (e) {
      setState(() {
        _isLoadingQuestions = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating quiz: ${e.toString()}')),
        );
      }
    }
  }

  void _selectAnswer(int index) {
    setState(() {
      _selectedAnswerIndex = index;
      _isAnswered = true;
      _userAnswers[_currentQuestionIndex] = index;

      if (index == _questions[_currentQuestionIndex].correctIndex) {
        _score++;
      }
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswerIndex = -1;
        _isAnswered = false;
      });
    } else {
      setState(() {
        _isQuizCompleted = true;
      });
    }
  }

  Widget _buildStatRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Color _getResultColor(int percentage) {
    if (percentage >= 80) return const Color(0xFF4CAF50); // Green for excellent
    if (percentage >= 60) return const Color(0xFFFFA726); // Orange for good
    return const Color(0xFFEF5350); // Red for needs improvement
  }

  String _getResultTitle(int percentage) {
    if (percentage >= 80) return '🎉 Excellent!';
    if (percentage >= 60) return '👍 Good Job!';
    return '💪 Keep Practicing!';
  }

  @override
  void dispose() {
    _topicController.dispose();
    _questionCountController.dispose();
    super.dispose();
  }
}

class AIQuizQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  AIQuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  factory AIQuizQuestion.fromJson(Map<String, dynamic> json) {
    return AIQuizQuestion(
      question: json['question'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      correctIndex: json['correctIndex'] ?? 0,
      explanation: json['explanation'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'options': options,
      'correctIndex': correctIndex,
      'explanation': explanation,
    };
  }
}
