import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/health_models.dart';

class AiClient {
  Future<String> generateInsight({
    required AiSettings settings,
    required List<HealthSample> samples,
    required HealthAssessment assessment,
  }) async {
    if (!settings.canRequest) {
      throw const AiClientException('尚未啟用 AI 或未填寫 API URL。');
    }

    final uri = Uri.parse(settings.endpoint.trim());
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (settings.apiKey.trim().isNotEmpty)
        'Authorization': 'Bearer ${settings.apiKey.trim()}',
    };
    final body = jsonEncode({
      'model': settings.model.trim().isEmpty
          ? 'gpt-4.1-mini'
          : settings.model.trim(),
      'temperature': 0.4,
      'max_tokens': 450,
      'messages': [
        {
          'role': 'system',
          'content': '你是健康促進與生活型態管理教練。請使用繁體中文，不能做疾病診斷，不能取代醫師，建議必須可執行且低壓力。',
        },
        {
          'role': 'user',
          'content':
              '請根據以下穿戴資料趨勢，輸出一段 120 字內的未來自我提示，接著列出 3 個小目標與原因：\n${assessment.toPromptSummary(samples)}',
        },
      ],
    });

    final response = await http
        .post(uri, headers: headers, body: body)
        .timeout(const Duration(seconds: 20));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AiClientException(
        'AI API 回應失敗：HTTP ${response.statusCode}，${_errorMessage(response.body)}',
      );
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    final content = _extractText(decoded);
    if (content == null || content.trim().isEmpty) {
      throw const AiClientException('AI API 回應格式無法解析。');
    }
    return content.trim();
  }

  String? _extractText(dynamic decoded) {
    if (decoded is Map<String, dynamic>) {
      final choices = decoded['choices'];
      if (choices is List && choices.isNotEmpty) {
        final first = choices.first;
        if (first is Map<String, dynamic>) {
          final message = first['message'];
          if (message is Map<String, dynamic> && message['content'] is String) {
            return message['content'] as String;
          }
          if (first['text'] is String) {
            return first['text'] as String;
          }
        }
      }
      if (decoded['output_text'] is String) {
        return decoded['output_text'] as String;
      }
      if (decoded['content'] is String) {
        return decoded['content'] as String;
      }
    }
    return null;
  }

  String _errorMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final error = decoded['error'];
        if (error is Map<String, dynamic> && error['message'] is String) {
          return error['message'] as String;
        }
        if (error is String) {
          return error;
        }
        if (decoded['message'] is String) {
          return decoded['message'] as String;
        }
      }
    } on FormatException {
      // Fall through to the raw body summary below.
    }
    final compact = body.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compact.isEmpty) {
      return '沒有錯誤本文。';
    }
    return compact.length > 160 ? '${compact.substring(0, 160)}...' : compact;
  }
}

class AiClientException implements Exception {
  const AiClientException(this.message);

  final String message;

  @override
  String toString() => message;
}
