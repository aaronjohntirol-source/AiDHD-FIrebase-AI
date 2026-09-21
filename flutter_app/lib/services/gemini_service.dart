import 'package:cloud_functions/cloud_functions.dart';

class GeminiException implements Exception {
  final String message;
  final bool keyProblem;

  const GeminiException(this.message, {this.keyProblem = false});

  @override
  String toString() => message;
}

class GeminiService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  Future<String> sendMessage({
    required Map<String, dynamic> userContext,
    required List<Map<String, String>> history,
    required String message,
  }) async {
    try {
      final callable = _functions.httpsCallable('chatWithGemini');
      final result = await callable.call({
        'userContext': userContext,
        'history': history,
        'message': message,
      });
      final data = result.data;
      final text = data is Map ? data['text'] : null;
      if (text is! String || text.trim().isEmpty) {
        throw const GeminiException('Gemini returned an empty response.');
      }
      return text.trim();
    } on FirebaseFunctionsException catch (error) {
      throw GeminiException(
          error.message ?? 'The assistant is temporarily unavailable.');
    }
  }
}
