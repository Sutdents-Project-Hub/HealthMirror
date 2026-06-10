import 'dart:convert';
import 'dart:math';

class HealthSample {
  const HealthSample({
    required this.date,
    required this.sleepHours,
    required this.sleepQuality,
    required this.steps,
    required this.activeMinutes,
    required this.restingHeartRate,
    required this.hrv,
    required this.sedentaryMinutes,
    required this.bedtimeHour,
  });

  final DateTime date;
  final double sleepHours;
  final int sleepQuality;
  final int steps;
  final int activeMinutes;
  final int restingHeartRate;
  final int hrv;
  final int sedentaryMinutes;
  final double bedtimeHour;

  String get dateKey {
    final local = DateTime(date.year, date.month, date.day);
    return local.toIso8601String().split('T').first;
  }

  HealthSample copyWith({
    DateTime? date,
    double? sleepHours,
    int? sleepQuality,
    int? steps,
    int? activeMinutes,
    int? restingHeartRate,
    int? hrv,
    int? sedentaryMinutes,
    double? bedtimeHour,
  }) {
    return HealthSample(
      date: date ?? this.date,
      sleepHours: sleepHours ?? this.sleepHours,
      sleepQuality: sleepQuality ?? this.sleepQuality,
      steps: steps ?? this.steps,
      activeMinutes: activeMinutes ?? this.activeMinutes,
      restingHeartRate: restingHeartRate ?? this.restingHeartRate,
      hrv: hrv ?? this.hrv,
      sedentaryMinutes: sedentaryMinutes ?? this.sedentaryMinutes,
      bedtimeHour: bedtimeHour ?? this.bedtimeHour,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': dateKey,
      'sleepHours': sleepHours,
      'sleepQuality': sleepQuality,
      'steps': steps,
      'activeMinutes': activeMinutes,
      'restingHeartRate': restingHeartRate,
      'hrv': hrv,
      'sedentaryMinutes': sedentaryMinutes,
      'bedtimeHour': bedtimeHour,
    };
  }

  factory HealthSample.fromJson(Map<String, dynamic> json) {
    return HealthSample(
      date: DateTime.parse(json['date'] as String),
      sleepHours: (json['sleepHours'] as num).toDouble(),
      sleepQuality: (json['sleepQuality'] as num).round(),
      steps: (json['steps'] as num).round(),
      activeMinutes: (json['activeMinutes'] as num).round(),
      restingHeartRate: (json['restingHeartRate'] as num).round(),
      hrv: (json['hrv'] as num).round(),
      sedentaryMinutes: (json['sedentaryMinutes'] as num).round(),
      bedtimeHour: (json['bedtimeHour'] as num).toDouble(),
    );
  }

  static List<HealthSample> seedData({DateTime? now}) {
    return _generateSimulation(now: now, random: Random(42));
  }

  static List<HealthSample> randomSimulation({DateTime? now}) {
    return _generateSimulation(now: now, random: Random());
  }

  static List<HealthSample> _generateSimulation({
    DateTime? now,
    required Random random,
  }) {
    final today = DateTime.now();
    final base = DateTime(
      now?.year ?? today.year,
      now?.month ?? today.month,
      now?.day ?? today.day,
    );
    final scenario = random.nextInt(4);
    final baselineSleep = 6.8 + random.nextDouble() * 1.2;
    final baselineSteps = 6200 + random.nextInt(3600);
    final fatigueStart = 6 + random.nextInt(5);

    return List.generate(14, (index) {
      final day = base.subtract(Duration(days: 13 - index));
      final weekend =
          day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;
      final fatigue = switch (scenario) {
        0 => index >= fatigueStart ? index - fatigueStart + 1 : 0,
        1 => 0,
        2 => index.isEven ? 2 : 0,
        _ => index >= 10 ? 2 : 1,
      };
      final recoveryBoost = scenario == 1 && index >= 8 ? index - 7 : 0;

      return HealthSample(
        date: day,
        sleepHours:
            (baselineSleep +
                    recoveryBoost * .10 -
                    fatigue * .24 +
                    (random.nextDouble() - .5) * .85)
                .clamp(5.2, 8.4)
                .toDouble(),
        sleepQuality:
            (74 + recoveryBoost * 2 - fatigue * 5 + random.nextInt(18))
                .clamp(48, 94)
                .round(),
        steps:
            (baselineSteps +
                    recoveryBoost * 260 -
                    fatigue * 460 +
                    random.nextInt(2200) -
                    900 +
                    (weekend ? 500 : 0))
                .clamp(3300, 12200)
                .round(),
        activeMinutes:
            (34 + recoveryBoost * 3 - fatigue * 3 + random.nextInt(24))
                .clamp(10, 78)
                .round(),
        restingHeartRate: (62 + fatigue * 2 - recoveryBoost + random.nextInt(9))
            .clamp(58, 84)
            .round(),
        hrv: (48 + recoveryBoost * 2 - fatigue * 3 + random.nextInt(16))
            .clamp(26, 72)
            .round(),
        sedentaryMinutes:
            (weekend
                    ? 360 + random.nextInt(150)
                    : 455 + fatigue * 34 - recoveryBoost * 16)
                .clamp(300, 690)
                .round(),
        bedtimeHour:
            (23.1 + fatigue * .20 - recoveryBoost * .08 + random.nextDouble())
                .clamp(22.5, 25.2)
                .toDouble(),
      );
    });
  }
}

class AiSettings {
  const AiSettings({
    this.enabled = false,
    this.endpoint = '',
    this.apiKey = '',
    this.model = 'gpt-4.1-mini',
  });

  final bool enabled;
  final String endpoint;
  final String apiKey;
  final String model;

  bool get canRequest => enabled && endpoint.trim().isNotEmpty;

  AiSettings copyWith({
    bool? enabled,
    String? endpoint,
    String? apiKey,
    String? model,
  }) {
    return AiSettings(
      enabled: enabled ?? this.enabled,
      endpoint: endpoint ?? this.endpoint,
      apiKey: apiKey ?? this.apiKey,
      model: model ?? this.model,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'endpoint': endpoint,
      'apiKey': apiKey,
      'model': model,
    };
  }

  factory AiSettings.fromJson(Map<String, dynamic> json) {
    return AiSettings(
      enabled: json['enabled'] as bool? ?? false,
      endpoint: json['endpoint'] as String? ?? '',
      apiKey: json['apiKey'] as String? ?? '',
      model: json['model'] as String? ?? 'gpt-4.1-mini',
    );
  }
}

class GoalProgress {
  const GoalProgress({
    this.accepted = false,
    this.completed = false,
    this.feedback = '',
  });

  final bool accepted;
  final bool completed;
  final String feedback;

  GoalProgress copyWith({bool? accepted, bool? completed, String? feedback}) {
    return GoalProgress(
      accepted: accepted ?? this.accepted,
      completed: completed ?? this.completed,
      feedback: feedback ?? this.feedback,
    );
  }

  Map<String, dynamic> toJson() {
    return {'accepted': accepted, 'completed': completed, 'feedback': feedback};
  }

  factory GoalProgress.fromJson(Map<String, dynamic> json) {
    return GoalProgress(
      accepted: json['accepted'] as bool? ?? false,
      completed: json['completed'] as bool? ?? false,
      feedback: json['feedback'] as String? ?? '',
    );
  }
}

enum RiskLevel { low, medium, high }

class RiskFinding {
  const RiskFinding({
    required this.id,
    required this.title,
    required this.detail,
    required this.suggestion,
    required this.level,
  });

  final String id;
  final String title;
  final String detail;
  final String suggestion;
  final RiskLevel level;
}

class HealthGoal {
  const HealthGoal({
    required this.id,
    required this.title,
    required this.action,
    required this.reason,
    required this.metricLabel,
  });

  final String id;
  final String title;
  final String action;
  final String reason;
  final String metricLabel;
}

class WeeklyStats {
  const WeeklyStats({
    required this.averageSleepHours,
    required this.averageSteps,
    required this.averageActiveMinutes,
    required this.averageSedentaryHours,
    required this.sleepTargetDays,
    required this.stepTrendPercent,
    required this.sedentaryBreakTarget,
  });

  final double averageSleepHours;
  final int averageSteps;
  final int averageActiveMinutes;
  final double averageSedentaryHours;
  final int sleepTargetDays;
  final double stepTrendPercent;
  final int sedentaryBreakTarget;
}

class HealthAssessment {
  const HealthAssessment({
    required this.score,
    required this.findings,
    required this.goals,
    required this.weeklyStats,
    required this.futureMessage,
    required this.narrative,
  });

  final int score;
  final List<RiskFinding> findings;
  final List<HealthGoal> goals;
  final WeeklyStats weeklyStats;
  final String futureMessage;
  final String narrative;

  String toPromptSummary(List<HealthSample> samples) {
    final latest = samples.isEmpty ? null : samples.last;
    final sampleJson = jsonEncode(
      samples.map((sample) => sample.toJson()).toList(),
    );
    return '''
目前健康分數：$score/100
未來自我提示：$futureMessage
週平均睡眠：${weeklyStats.averageSleepHours.toStringAsFixed(1)} 小時
週平均步數：${weeklyStats.averageSteps} 步
週平均活動：${weeklyStats.averageActiveMinutes} 分鐘
週平均久坐：${weeklyStats.averageSedentaryHours.toStringAsFixed(1)} 小時
睡眠達標天數：${weeklyStats.sleepTargetDays} 天
最新資料日期：${latest?.dateKey ?? '無'}
風險：${findings.map((finding) => '${finding.title}：${finding.detail}').join('；')}
建議目標：${goals.map((goal) => '${goal.title}：${goal.action}').join('；')}
原始資料 JSON：$sampleJson
''';
  }
}
