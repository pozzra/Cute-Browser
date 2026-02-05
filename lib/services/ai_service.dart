import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/foundation.dart';

class AiService {
  static GenerativeModel? _model;
  static const String _apiKey = "AIzaSyB7Gw8ojQFWTamLB65KprJ3hLWti9P3m0c";

  static const String _systemInstruction = """
You are "Cute Assistant", a friendly, helpful, and very cute AI companion built into the Cute Browser.
Your tone should be warm, cheerful, and encouraging. Use emojis occasionally (like ✨, 💖, 🎀, 🍭) to stay "cute".
Your goal is to help the user with questions and summarize web pages they are viewing.
Keep your answers concise and easy to read. If you don't know something, be honest but stay cute!
""";

  static Future<void> init() async {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
      systemInstruction: Content.system(_systemInstruction),
    );
  }

  // No longer needed as key is hardcoded
  static Future<void> setApiKey(String key) async {}

  static bool get isConfigured => _model != null;

  static Future<String> sendMessage(
    String message, {
    String? pageContext,
  }) async {
    if (_model == null) await init();

    try {
      final promptParts = [
        if (pageContext != null)
          TextPart("I am currently looking at this website:\n$pageContext\n\n"),
        TextPart(message),
      ];

      final response = await _model!.generateContent([
        Content.multi(promptParts),
      ]);
      return response.text ?? "Oops! I draw a blank. Try again? 🍭";
    } catch (e) {
      debugPrint("AiService Error: $e");
      return "Something went wrong while I was thinking... 🎀 Maybe check your API key or connection?";
    }
  }
}
