class QuizRoom {
  final String roomId;
  final String hostId;
  final int currentQuestionIndex;
  final List<QuizQuestion> questions;
  final Map<String, Player> players;

  QuizRoom({
    required this.roomId,
    required this.hostId,
    required this.currentQuestionIndex,
    required this.questions,
    required this.players,
  });

  factory QuizRoom.fromJson(Map<String, dynamic> json) {
    return QuizRoom(
      roomId: json['roomId'] ?? '',
      hostId: json['hostId'] ?? '',
      currentQuestionIndex: json['currentQuestionIndex'] ?? 0,
      questions:
          (json['questions'] as List<dynamic>?)
              ?.map((q) => QuizQuestion.fromJson(q))
              .toList() ??
          [],
      players:
          (json['players'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, Player.fromJson(value)),
          ) ??
          {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roomId': roomId,
      'hostId': hostId,
      'currentQuestionIndex': currentQuestionIndex,
      'questions': questions.map((q) => q.toJson()).toList(),
      'players': players.map((key, value) => MapEntry(key, value.toJson())),
    };
  }
}

class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      question: json['question'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      correctIndex: json['correctIndex'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'options': options,
      'correctIndex': correctIndex,
    };
  }
}

class Player {
  final String name;
  final int score;

  Player({required this.name, required this.score});

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(name: json['name'] ?? '', score: json['score'] ?? 0);
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'score': score};
  }
}

class QuizResult {
  final String playerId;
  final String name;
  final int score;
  final int totalQuestions;
  final int percentage;

  QuizResult({
    required this.playerId,
    required this.name,
    required this.score,
    required this.totalQuestions,
    required this.percentage,
  });

  factory QuizResult.fromJson(Map<String, dynamic> json) {
    return QuizResult(
      playerId: json['playerId'] ?? '',
      name: json['name'] ?? '',
      score: json['score'] ?? 0,
      totalQuestions: json['totalQuestions'] ?? 0,
      percentage: json['percentage'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'playerId': playerId,
      'name': name,
      'score': score,
      'totalQuestions': totalQuestions,
      'percentage': percentage,
    };
  }
}

class QuizState {
  final String? currentRoomId;
  final bool isHost;
  final QuizQuestion? currentQuestion;
  final int? currentQuestionIndex;
  final Map<String, Player> players;
  final bool isQuizActive;
  final bool isWaitingForAnswer;
  final List<QuizResult> quizResults;

  QuizState({
    this.currentRoomId,
    this.isHost = false,
    this.currentQuestion,
    this.currentQuestionIndex,
    this.players = const {},
    this.isQuizActive = false,
    this.isWaitingForAnswer = false,
    this.quizResults = const [],
  });

  QuizState copyWith({
    String? currentRoomId,
    bool? isHost,
    QuizQuestion? currentQuestion,
    int? currentQuestionIndex,
    Map<String, Player>? players,
    bool? isQuizActive,
    bool? isWaitingForAnswer,
    List<QuizResult>? quizResults,
  }) {
    return QuizState(
      currentRoomId: currentRoomId ?? this.currentRoomId,
      isHost: isHost ?? this.isHost,
      currentQuestion: currentQuestion ?? this.currentQuestion,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      players: players ?? this.players,
      isQuizActive: isQuizActive ?? this.isQuizActive,
      isWaitingForAnswer: isWaitingForAnswer ?? this.isWaitingForAnswer,
      quizResults: quizResults ?? this.quizResults,
    );
  }
}
