import 'package:flutter/foundation.dart';

import '../models/health_models.dart';
import 'ai_client.dart';
import 'health_analyzer.dart';
import 'local_store.dart';

class HealthMirrorController extends ChangeNotifier {
  HealthMirrorController({LocalStore? store, AiClient? aiClient})
    : _store = store ?? LocalStore(),
      _aiClient = aiClient ?? AiClient();

  final LocalStore _store;
  final AiClient _aiClient;

  List<HealthSample> _samples = const [];
  AiSettings _settings = const AiSettings();
  Map<String, GoalProgress> _goalProgress = const {};
  bool _isLoading = true;
  bool _isRequestingAi = false;
  String? _aiInsight;
  String? _aiError;

  List<HealthSample> get samples => _samples;
  AiSettings get settings => _settings;
  Map<String, GoalProgress> get goalProgress => _goalProgress;
  bool get isLoading => _isLoading;
  bool get isRequestingAi => _isRequestingAi;
  String? get aiInsight => _aiInsight;
  String? get aiError => _aiError;
  HealthAssessment get assessment => HealthAnalyzer.assess(_samples);

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();

    final loadedSamples = await _store.loadSamples();
    _samples = loadedSamples.isEmpty ? HealthSample.seedData() : loadedSamples;
    _sortSamples();
    _settings = await _store.loadSettings();
    _goalProgress = await _store.loadGoalProgress();
    await _store.saveSamples(_samples);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> upsertSample(HealthSample sample) async {
    final next = [
      ..._samples.where((item) => item.dateKey != sample.dateKey),
      sample,
    ];
    _samples = next;
    _sortSamples();
    _aiInsight = null;
    _aiError = null;
    notifyListeners();
    await _store.saveSamples(_samples);
  }

  Future<void> generateRandomSimulation() async {
    _samples = HealthSample.randomSimulation();
    _goalProgress = const {};
    _aiInsight = null;
    _aiError = null;
    _sortSamples();
    notifyListeners();
    await _store.saveSamples(_samples);
    await _store.saveGoalProgress(_goalProgress);
  }

  Future<void> generateBalancedSimulation() => generateRandomSimulation();

  Future<void> updateSettings(AiSettings settings) async {
    _settings = settings;
    _aiError = null;
    notifyListeners();
    await _store.saveSettings(settings);
  }

  GoalProgress progressFor(String goalId) {
    return _goalProgress[goalId] ?? const GoalProgress();
  }

  Future<void> setGoalAccepted(String goalId, bool value) async {
    final progress = progressFor(goalId).copyWith(accepted: value);
    _goalProgress = {..._goalProgress, goalId: progress};
    notifyListeners();
    await _store.saveGoalProgress(_goalProgress);
  }

  Future<void> setGoalCompleted(String goalId, bool value) async {
    final progress = progressFor(goalId).copyWith(completed: value);
    _goalProgress = {..._goalProgress, goalId: progress};
    notifyListeners();
    await _store.saveGoalProgress(_goalProgress);
  }

  Future<void> saveGoalFeedback(String goalId, String feedback) async {
    final progress = progressFor(goalId).copyWith(feedback: feedback.trim());
    _goalProgress = {..._goalProgress, goalId: progress};
    notifyListeners();
    await _store.saveGoalProgress(_goalProgress);
  }

  Future<void> requestAiInsight() async {
    _isRequestingAi = true;
    _aiError = null;
    notifyListeners();

    try {
      _aiInsight = await _aiClient.generateInsight(
        settings: _settings,
        samples: _samples,
        assessment: assessment,
      );
    } on Object catch (error) {
      _aiError = error.toString();
    } finally {
      _isRequestingAi = false;
      notifyListeners();
    }
  }

  void _sortSamples() {
    _samples = [..._samples]..sort((a, b) => a.date.compareTo(b.date));
  }
}
