import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class GroqService {
  static const String _apiKey =
      "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";
  static const String _baseUrl =
      "https://api.groq.com/openai/v1/chat/completions";

  /// Send a chat message to Groq API and get response
  Future<String> sendMessage(String message, {bool isEnglish = true}) async {
    try {
      final systemMessage = isEnglish
          ? "You are an educational guidance counselor for Tamil Nadu students. Help them with college admissions, course selection, and career planning. Provide accurate information about TNEA counseling, engineering colleges, and entrance exams."
          : "நீங்கள் தமிழ்நாடு மாணவர்களுக்கான கல்வி வழிகாட்டுதல் ஆலோசகர். கல்லூரி சேர்க்கை, பாடநெறி தேர்வு மற்றும் தொழில் திட்டமிடல் ஆகியவற்றில் அவர்களுக்கு உதவுங்கள். TNEA ஆலோசனை, பொறியியல் கல்லூரிகள் மற்றும் நுழைவுத் தேர்வுகள் பற்றிய துல்லியமான தகவல்களை வழங்குங்கள்.";

      final requestBody = {
        "messages": [
          {"role": "system", "content": systemMessage},
          {"role": "user", "content": message},
        ],
        "model": "llama-3.3-70b-versatile",
        "temperature": 0.7,
        "max_tokens": 1024,
        "stream": false,
      };

      debugPrint('Sending request to Groq API...');

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: json.encode(requestBody),
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['choices'] != null &&
            responseData['choices'].isNotEmpty) {
          final content = responseData['choices'][0]['message']['content'];
          return content ?? 'No response received';
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        debugPrint('Error response: ${response.body}');
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Error in GroqService: $e');

      // Return fallback responses
      if (isEnglish) {
        return "I'm sorry, I'm having trouble connecting right now. Please try again later. In the meantime, you can browse our question banks or use the predict feature for college recommendations.";
      } else {
        return "மன்னிக்கவும், இப்போது இணைப்பில் சிக்கல் உள்ளது. தயவுசெய்து பின்னர் மீண்டும் முயற்சிக்கவும். இதற்கிடையில், நீங்கள் எங்கள் கேள்வி வங்கிகளைப் பார்க்கலாம் அல்லது கல்லூரி பரிந்துரைகளுக்கு முன்னறிவிப்பு அம்சத்தைப் பயன்படுத்தலாம்.";
      }
    }
  }

  /// Get educational guidance response based on predefined scenarios
  String _getFallbackResponse(String message, bool isEnglish) {
    final lowerMessage = message.toLowerCase();

    if (lowerMessage.contains('college') ||
        lowerMessage.contains('admission')) {
      return isEnglish
          ? "For college admissions in Tamil Nadu, the main process is through TNEA counseling. You'll need your +2 marks and entrance exam scores. Would you like specific information about any particular college or course?"
          : "தமிழ்நாட்டில் கல்லூரி சேர்க்கைக்கு முக்கிய செயல்முறை TNEA ஆலோசனை மூலம் நடக்கும். உங்களுக்கு +2 மதிப்பெண்கள் மற்றும் நுழைவுத் தேர்வு மதிப்பெண்கள் தேவை. ஏதேனும் குறிப்பிட்ட கல்லூரி அல்லது பாடநெறி பற்றிய தகவல் வேண்டுமா?";
    } else if (lowerMessage.contains('engineering') ||
        lowerMessage.contains('btech')) {
      return isEnglish
          ? "For engineering admissions, you need to appear for JEE Main or state-level entrance exams. Anna University conducts TNEA for state quota seats. The cutoff depends on your category and college preference."
          : "பொறியியல் சேர்க்கைக்கு, நீங்கள் JEE Main அல்லது மாநில அளவிலான நுழைவுத் தேர்வுகளில் தோன்ற வேண்டும். அண்ணா பல்கலைக்கழகம் மாநில ஒதுக்கீட்டு இடங்களுக்காக TNEA நடத்துகிறது.";
    } else {
      return isEnglish
          ? "I'm here to help with your educational queries. You can ask me about college admissions, course selection, entrance exams, or career guidance. What would you like to know?"
          : "உங்கள் கல்வி சார்ந்த கேள்விகளுக்கு நான் இங்கே உதவ இருக்கிறேன். கல்லூரி சேர்க்கை, பாடநெறி தேர்வு, நுழைவுத் தேர்வுகள் அல்லது தொழில் வழிகாட்டுதல் பற்றி என்னிடம் கேட்கலாம். நீங்கள் என்ன அறிய விரும்புகிறீர்கள்?";
    }
  }
}
