import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class GroqService {
  static const String _apiKey = String.fromEnvironment('GROQ_API_KEY');
  static const String _baseUrl =
      'https://api.groq.com/openai/v1/chat/completions';

  Future<String> sendMessage(String message, {bool isEnglish = true}) async {
    if (_apiKey.isEmpty) {
      throw StateError(
        'GROQ_API_KEY is not configured. Pass it with --dart-define.',
      );
    }

    final systemMessage = isEnglish
        ? 'You are an educational guidance counselor for Tamil Nadu students. Help with college admissions, course selection, and career planning, including TNEA counseling, engineering colleges, and entrance exams. Always respond only in English, even if the user writes in Tamil or another language. Do not include Tamil text.'
        : 'நீங்கள் தமிழ்நாட்டு மாணவர்களுக்கான கல்வி வழிகாட்டுதல் ஆலோசகர். கல்லூரி சேர்க்கை, பாடநெறி தேர்வு, தொழில் திட்டமிடல், TNEA கலந்தாய்வு, பொறியியல் கல்லூரிகள் மற்றும் நுழைவுத் தேர்வுகள் குறித்து உதவுங்கள். பயனர் ஆங்கிலம் அல்லது வேறு மொழியில் எழுதினாலும், எப்போதும் தமிழில் மட்டுமே பதிலளிக்கவும். ஆங்கில உரையைச் சேர்க்க வேண்டாம்.';

    final response = await http
        .post(
          Uri.parse(_baseUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_apiKey',
          },
          body: json.encode({
            'messages': [
              {'role': 'system', 'content': systemMessage},
              {'role': 'user', 'content': message},
            ],
            'model': 'openai/gpt-oss-20b',
            'max_completion_tokens': 1024,
            'stream': false,
          }),
        )
        .timeout(const Duration(seconds: 30));

    debugPrint('Groq response status: ${response.statusCode}');
    if (response.statusCode != 200) {
      throw Exception(
        'Groq API error ${response.statusCode}: '
        '${_getApiErrorMessage(response.body)}',
      );
    }

    final responseData = json.decode(response.body) as Map<String, dynamic>;
    final choices = responseData['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      throw const FormatException('Groq returned no chat choices.');
    }

    final choice = choices.first as Map<String, dynamic>;
    final messageData = choice['message'] as Map<String, dynamic>?;
    final content = messageData?['content'] as String?;
    if (content == null || content.isEmpty) {
      throw const FormatException('Groq returned an empty chat response.');
    }
    return content;
  }

  String _getApiErrorMessage(String responseBody) {
    try {
      final data = json.decode(responseBody) as Map<String, dynamic>;
      final error = data['error'];
      if (error is Map<String, dynamic> && error['message'] is String) {
        return error['message'] as String;
      }
    } on FormatException {
      // Use a bounded response excerpt if the API did not return JSON.
    } on TypeError {
      // Use a bounded response excerpt if the API returned an unexpected shape.
    }
    return responseBody.length > 300
        ? '${responseBody.substring(0, 300)}...'
        : responseBody;
  }
}
