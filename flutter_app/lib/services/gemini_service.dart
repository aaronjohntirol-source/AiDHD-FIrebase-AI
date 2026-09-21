import 'dart:convert';

import 'package:http/http.dart' as http;
import 'ai_provider_service.dart';

class GeminiException implements Exception {
  final String message;
  final bool keyProblem;

  const GeminiException(this.message, {this.keyProblem = false});

  @override
  String toString() => message;
}

class GeminiService {
  Future<String> sendMessage({
    required AiProviderConfig config,
    required String systemPrompt,
    required List<Map<String, String>> history,
    required String message,
  }) async {
    if (config.provider == AiProvider.gemini) {
      return _sendGemini(config, systemPrompt, history, message);
    }
    return _sendOpenAiCompatible(config, systemPrompt, history, message);
  }

  Future<String> _sendGemini(
    AiProviderConfig config,
    String systemPrompt,
    List<Map<String, String>> history,
    String message,
  ) async {
    final endpoint = '${config.endpoint}/${config.model}:generateContent';
    final contents = [
      ...history.map((item) => {
            'role': item['role']!,
            'parts': jsonEncode([
              {'text': item['text']!}
            ]),
          }),
      {
        'role': 'user',
        'parts': jsonEncode([
          {'text': message}
        ]),
      },
    ];

    final response = await http.post(
      Uri.parse('$endpoint?key=${Uri.encodeQueryComponent(config.apiKey)}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'systemInstruction': {
          'parts': [
            {'text': systemPrompt}
          ]
        },
        'contents': contents
            .map((item) => {
                  'role': item['role'],
                  'parts': jsonDecode(item['parts']!),
                })
            .toList(),
        'generationConfig': {
          'temperature': 0.6,
          'maxOutputTokens': 450,
        },
      }),
    );

    final data = _decode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw GeminiException(
        _errorMessage(response.statusCode, data),
        keyProblem: response.statusCode == 400 ||
            response.statusCode == 401 ||
            response.statusCode == 403 ||
            response.statusCode == 429,
      );
    }

    final candidates = data['candidates'];
    if (candidates is! List || candidates.isEmpty) {
      throw const GeminiException('Gemini did not return a response.');
    }
    final parts = candidates.first['content']?['parts'];
    if (parts is! List || parts.isEmpty || parts.first['text'] is! String) {
      throw const GeminiException('Gemini returned an empty response.');
    }
    return (parts.first['text'] as String).trim();
  }

  Future<String> _sendOpenAiCompatible(
    AiProviderConfig config,
    String systemPrompt,
    List<Map<String, String>> history,
    String message,
  ) async {
    final messages = [
      {'role': 'system', 'content': systemPrompt},
      ...history.map((item) => {
            'role': item['role'] == 'model' ? 'assistant' : 'user',
            'content': item['text']!,
          }),
      {'role': 'user', 'content': message},
    ];
    final response = await http.post(
      Uri.parse(config.endpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${config.apiKey}',
      },
      body: jsonEncode({
        'model': config.model,
        'messages': messages,
        'temperature': 0.6,
        'max_tokens': 450,
      }),
    );
    final data = _decode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw GeminiException(
        _errorMessage(response.statusCode, data),
        keyProblem: response.statusCode == 400 ||
            response.statusCode == 401 ||
            response.statusCode == 403 ||
            response.statusCode == 429,
      );
    }
    final content = data['choices']?[0]?['message']?['content'];
    if (content is! String || content.trim().isEmpty) {
      throw const GeminiException(
          'The selected AI returned an empty response.');
    }
    return content.trim();
  }

  Map<String, dynamic> _decode(String body) {
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  String _errorMessage(int statusCode, Map<String, dynamic> data) {
    final message = data['error']?['message'];
    if (message is String && message.isNotEmpty) return message;
    switch (statusCode) {
      case 429:
        return 'This Gemini API key has reached its usage limit.';
      case 400:
      case 401:
      case 403:
        return 'This Gemini API key was rejected. Check the key and try again.';
      default:
        return 'Gemini is temporarily unavailable. Please try again.';
    }
  }
}
