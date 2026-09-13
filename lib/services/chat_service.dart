import 'dart:convert';

import 'package:http/http.dart' as http;

class ChatServiceException implements Exception {
  final String message;
  ChatServiceException(this.message);

  @override
  String toString() => message;
}

class ChatTurn {
  final String role; // 'user' or 'assistant'
  final String content;

  const ChatTurn({required this.role, required this.content});

  Map<String, String> toJson() => {'role': role, 'content': content};
}

/// Calls the solar-system-chat Cloudflare Worker, which holds the LLM API
/// key server-side. Never call an LLM API directly from the client — the
/// key would be extractable from the shipped app.
class ChatService {
  static const _endpoint = 'https://solar-system-chat.belalsaqer.workers.dev';

  static Future<String> sendMessage({
    required String message,
    required List<ChatTurn> history,
    String? selectedPlanet,
  }) async {
    final http.Response response;
    try {
      response = await http
          .post(
            Uri.parse(_endpoint),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'message': message,
              'history': history.map((t) => t.toJson()).toList(),
              'selectedPlanet': ?selectedPlanet,
            }),
          )
          .timeout(const Duration(seconds: 30));
    } catch (_) {
      throw ChatServiceException('Could not reach the assistant. Check your connection and try again.');
    }

    Map<String, dynamic> data;
    try {
      data = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      data = const {};
    }

    if (response.statusCode != 200) {
      throw ChatServiceException(
        data['error'] as String? ?? 'Something went wrong (HTTP ${response.statusCode}).',
      );
    }

    final reply = data['reply'] as String?;
    if (reply == null || reply.trim().isEmpty) {
      throw ChatServiceException("The assistant didn't send back a reply. Please try again.");
    }
    return reply;
  }
}
