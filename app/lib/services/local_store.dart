import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/health_models.dart';

class LocalStore {
  static const _samplesKey = 'health_samples_v1';
  static const _settingsKey = 'ai_settings_v1';
  static const _goalProgressKey = 'goal_progress_v1';

  Future<List<HealthSample>> loadSamples() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_samplesKey);
    if (raw == null || raw.isEmpty) {
      return const [];
    }
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => HealthSample.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveSamples(List<HealthSample> samples) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(samples.map((sample) => sample.toJson()).toList());
    await prefs.setString(_samplesKey, raw);
  }

  Future<AiSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_settingsKey);
    if (raw == null || raw.isEmpty) {
      return const AiSettings();
    }
    return AiSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveSettings(AiSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
  }

  Future<Map<String, GoalProgress>> loadGoalProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_goalProgressKey);
    if (raw == null || raw.isEmpty) {
      return const {};
    }
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map(
      (key, value) =>
          MapEntry(key, GoalProgress.fromJson(value as Map<String, dynamic>)),
    );
  }

  Future<void> saveGoalProgress(Map<String, GoalProgress> progress) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(
      progress.map((key, value) => MapEntry(key, value.toJson())),
    );
    await prefs.setString(_goalProgressKey, raw);
  }
}
