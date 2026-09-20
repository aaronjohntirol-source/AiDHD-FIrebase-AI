import 'dart:convert';

import 'package:http/http.dart' as http;

class GeminiException implements Exception {
  final String message;
  final bool keyProblem;

  const GeminiException(this.message, {this.keyProblem = false});

  @override
  String toString() => message;
}

class GeminiService {
  static const _model = 'gemini-2.0-flash';
  static const _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';

  Future<String> sendMessage({
    required String apiKey,
    required String systemPrompt,
    required List<Map<String, String>> history,
    required String message,
  }) async {
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
      Uri.parse('$_endpoint?key=${Uri.encodeQueryComponent(apiKey)}'),
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
          'temperature': 0.7,
          'maxOutputTokens': 700,
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
