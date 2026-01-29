import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class AiService {
  static GenerativeModel? _model;
  static String? _apiKey;

  static const String _systemInstruction = """
You are "Cute Assistant", a friendly, helpful, and very cute AI companion built into the Cute Browser.
Your tone should be warm, cheerful, and encouraging. Use emojis occasionally (like ✨, 💖, 🎀, 🍭) to stay "cute".
Your goal is to help the user with questions and summarize web pages they are viewing.
Keep your answers concise and easy to read. If you don't know something, be honest but stay cute!
""";

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _apiKey = prefs.getString('gemini_api_key');
    if (_apiKey != null && _apiKey!.isNotEmpty) {
      _model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _apiKey!,
        systemInstruction: Content.system(_systemInstruction),
      );
    }
  }

  static Future<void> setApiKey(String key) async {
    _apiKey = key;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gemini_api_key', key);
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey!,
      systemInstruction: Content.system(_systemInstruction),
    );
  }

  static bool get isConfigured => _model != null;

  static Future<String> sendMessage(String message, {String? pageContext}) async {
    if (_model == null) {
      return "Hello! I'm your Cute AI Assistant. To start chatting, please go to Settings and add your Gemini API Key! ✨💖";
    }

    try {
      final promptParts = [
        if (pageContext != null) TextPart("I am currently looking at this website:\n$pageContext\n\n"),
        TextPart(message),
      ];

      final response = await _model!.generateContent([Content.multi(promptParts)]);
      return response.text ?? "Oops! I draw a blank. Try again? 🍭";
    } catch (e) {
      debugPrint("AiService Error: $e");
      return "Something went wrong while I was thinking... 🎀 Maybe check your API key or connection?";
    }
  }
}
