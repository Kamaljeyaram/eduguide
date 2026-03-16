import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/quiz_models.dart';

class QuizService extends ChangeNotifier {
  IO.Socket? _socket;
  QuizState _state = QuizState();
  final StreamController<String> _messageController =
      StreamController<String>.broadcast();

  // Replace with your backend URL
  static const String _serverUrl =
      'https://quiz-backend-xj7z.onrender.com/'; // Change this to your actual hosted server URL

  QuizState get state => _state;
  Stream<String> get messages => _messageController.stream;

  void _initSocket() {
    _socket = IO.io(
      _serverUrl,
      IO.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .enableAutoConnect()
          .enableReconnection()
          .build(),
    );

    _socket!.on('connect', (_) {
      debugPrint('Connected to quiz server');
    });

    _socket!.on('disconnect', (_) {
      debugPrint('Disconnected from quiz server');
    });

    _socket!.on('roomCreated', (data) {
      debugPrint('Room created: $data');
      _state = _state.copyWith(
        currentRoomId: data['roomId'],
        isHost: true,
        isQuizActive: true, // Set quiz as active when room is created
      );
      notifyListeners();
    });

    _socket!.on('playersUpdated', (data) {
      debugPrint('Players updated: $data');
      final players = <String, Player>{};
      (data as Map<String, dynamic>).forEach((key, value) {
        players[key] = Player.fromJson(value);
      });
      _state = _state.copyWith(players: players);
      notifyListeners();
    });

    _socket!.on('newQuestion', (data) {
      debugPrint('New question: $data');
      final question = QuizQuestion(
        question: data['question'],
        options: List<String>.from(data['options']),
        correctIndex: -1, // Don't expose correct answer to client
      );
      _state = _state.copyWith(
        currentQuestion: question,
        currentQuestionIndex: data['index'],
        isWaitingForAnswer: false,
      );
      notifyListeners();
    });

    _socket!.on('answerResult', (data) {
      debugPrint('Answer result: $data');
      final isCorrect = data['correct'] ?? false;
      final currentScore = data['currentScore'] ?? 0;

      _messageController.add(
        isCorrect
            ? 'Correct! Your score: $currentScore'
            : 'Wrong answer. Your score: $currentScore',
      );

      _state = _state.copyWith(isWaitingForAnswer: false);
      notifyListeners();
    });

    _socket!.on('quizEnded', (data) {
      debugPrint('Quiz ended: $data');

      // Extract results from the new backend format
      final results = data['results'] as List<dynamic>? ?? [];
      final players = <String, Player>{};

      // Convert results to player format
      for (var result in results) {
        final playerId = result['playerId'] as String;
        players[playerId] = Player(
          name: result['name'] as String,
          score: result['score'] as int,
        );
      }

      _state = _state.copyWith(
        players: players.isNotEmpty ? players : _state.players,
        isQuizActive: false,
        currentQuestion: null,
        isWaitingForAnswer: false,
        quizResults: results.map((r) => QuizResult.fromJson(r)).toList(),
      );

      final endedBy = data['endedBy'] as String? ?? 'unknown';
      final totalQuestions = data['totalQuestions'] as int? ?? 0;

      _messageController.add(
        'Quiz ended by $endedBy! Total questions: $totalQuestions',
      );
      notifyListeners();
    });

    _socket!.on('errorMessage', (message) {
      debugPrint('Error: $message');
      _messageController.add('Error: $message');
    });
  }

  String generateRoomId() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  void createRoom() {
    if (_socket == null) _initSocket();

    final roomId = generateRoomId();
    _socket!.emit('createRoom', {'roomId': roomId});
  }

  void joinRoom(String roomId, String playerName) {
    if (_socket == null) _initSocket();

    _socket!.emit('joinRoom', {'roomId': roomId, 'name': playerName});

    _state = _state.copyWith(
      currentRoomId: roomId,
      isHost: false,
      isQuizActive: true, // Set quiz as active when joining room
    );
    notifyListeners();
  }

  void sendManualQuestion(
    String question,
    List<String> options,
    int correctIndex,
  ) {
    if (_socket == null || !_state.isHost) return;

    _socket!.emit('sendManualQuestion', {
      'roomId': _state.currentRoomId,
      'question': question,
      'options': options,
      'correctIndex': correctIndex,
    });
  }

  void clearCurrentQuestion() {
    // For the new backend, we just clear the local state since there's no server event for this
    // The backend handles question flow differently
    _state = _state.copyWith(currentQuestion: null, isWaitingForAnswer: false);
    notifyListeners();
  }

  void endQuiz() {
    if (_socket == null || !_state.isHost) return;

    _socket!.emit('endQuiz', {'roomId': _state.currentRoomId});

    // Update local state
    _state = _state.copyWith(
      currentQuestion: null,
      isQuizActive: false,
      isWaitingForAnswer: false,
    );
    notifyListeners();
  }

  void submitAnswer(int selectedIndex) {
    if (_socket == null) return;

    _state = _state.copyWith(isWaitingForAnswer: true);
    notifyListeners();

    _socket!.emit('submitAnswer', {
      'roomId': _state.currentRoomId,
      'selectedIndex': selectedIndex,
    });
  }

  void leaveRoom() {
    _socket?.disconnect();
    _socket = null;
    _state = QuizState(); // This will reset isQuizActive to false
    notifyListeners();
  }

  @override
  void dispose() {
    _socket?.dispose();
    _messageController.close();
    super.dispose();
  }
}
