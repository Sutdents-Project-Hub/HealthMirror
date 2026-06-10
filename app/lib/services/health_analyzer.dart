import '../models/health_models.dart';

class HealthAnalyzer {
  static HealthAssessment assess(List<HealthSample> samples) {
    final sorted = [...samples]..sort((a, b) => a.date.compareTo(b.date));
    final window = sorted.length > 7
        ? sorted.sublist(sorted.length - 7)
        : sorted;

    if (window.isEmpty) {
      return HealthAssessment(
        score: 0,
        findings: const [],
        goals: const [],
        weeklyStats: const WeeklyStats(
          averageSleepHours: 0,
          averageSteps: 0,
          averageActiveMinutes: 0,
          averageSedentaryHours: 0,
          sleepTargetDays: 0,
          stepTrendPercent: 0,
          sedentaryBreakTarget: 0,
        ),
        futureMessage: '尚未有資料，請先新增或模擬穿戴資料。',
        narrative: '目前沒有足夠資料產生週報。',
      );
    }

    final avgSleep = _average(window.map((sample) => sample.sleepHours));
    final avgSteps = _average(window.map((sample) => sample.steps.toDouble()));
    final avgActive = _average(
      window.map((sample) => sample.activeMinutes.toDouble()),
    );
    final avgSedentaryMinutes = _average(
      window.map((sample) => sample.sedentaryMinutes.toDouble()),
    );
    final avgHeart = _average(
      window.map((sample) => sample.restingHeartRate.toDouble()),
    );
    final avgHrv = _average(window.map((sample) => sample.hrv.toDouble()));
    final avgSleepQuality = _average(
      window.map((sample) => sample.sleepQuality.toDouble()),
    );
    final sleepTargetDays = window
        .where((sample) => sample.sleepHours >= 7)
        .length;
    final lateDays = window.where((sample) => sample.bedtimeHour >= 24).length;
    final sleepDebtStreak = _trailingCount(
      window,
      (sample) => sample.sleepHours < 6.5,
    );
    final stepTrend = _trendPercent(window.map((sample) => sample.steps));

    var score = 100;
    final findings = <RiskFinding>[];

    if (avgSleep < 6.2 || sleepDebtStreak >= 3) {
      score -= 22;
      findings.add(
        RiskFinding(
          id: 'sleep_debt',
          title: '連續睡眠不足',
          detail:
              '近 7 日平均睡眠 ${avgSleep.toStringAsFixed(1)} 小時，最近連續 $sleepDebtStreak 天低於 6.5 小時。',
          suggestion: '今晚先把就寢時間提前 30 分鐘，避免一次要求太大造成反彈。',
          level: RiskLevel.high,
        ),
      );
    } else if (avgSleep < 7) {
      score -= 10;
      findings.add(
        RiskFinding(
          id: 'sleep_warning',
          title: '睡眠接近不足',
          detail: '近 7 日平均睡眠 ${avgSleep.toStringAsFixed(1)} 小時，仍低於 7 小時目標。',
          suggestion: '設定固定睡前提醒，先讓每週睡眠達標天數增加 1 天。',
          level: RiskLevel.medium,
        ),
      );
    }

    if (avgSteps < 6000 || stepTrend < -12) {
      score -= avgSteps < 5000 ? 18 : 12;
      findings.add(
        RiskFinding(
          id: 'low_activity',
          title: '活動量下降',
          detail:
              '近 7 日平均 ${avgSteps.round()} 步，步數趨勢 ${stepTrend.toStringAsFixed(0)}%。',
          suggestion: '本週每日多走 1000 步，優先放在通勤或午餐後固定時段。',
          level: avgSteps < 5000 ? RiskLevel.high : RiskLevel.medium,
        ),
      );
    }

    final sedentaryHours = avgSedentaryMinutes / 60;
    if (sedentaryHours > 8.5) {
      score -= 16;
      findings.add(
        RiskFinding(
          id: 'sedentary',
          title: '久坐時間偏長',
          detail: '近 7 日平均久坐 ${sedentaryHours.toStringAsFixed(1)} 小時。',
          suggestion: '每 60 分鐘起身走 5 分鐘，先以一天完成 3 次為低門檻目標。',
          level: RiskLevel.high,
        ),
      );
    } else if (sedentaryHours > 7.2) {
      score -= 8;
      findings.add(
        RiskFinding(
          id: 'sedentary_warning',
          title: '久坐需要中斷',
          detail: '近 7 日平均久坐 ${sedentaryHours.toStringAsFixed(1)} 小時。',
          suggestion: '把久坐提醒設在工作或讀書時段，不需要增加額外運動時間。',
          level: RiskLevel.medium,
        ),
      );
    }

    if (lateDays >= 3) {
      score -= 9;
      findings.add(
        RiskFinding(
          id: 'late_schedule',
          title: '晚睡頻率增加',
          detail: '近 7 日有 $lateDays 天在午夜後就寢。',
          suggestion: '先固定起床時間，再把睡前螢幕使用時間往前收 20 分鐘。',
          level: RiskLevel.medium,
        ),
      );
    }

    if (avgHeart >= 76 || avgHrv < 38 || avgSleepQuality < 62) {
      score -= 7;
      findings.add(
        RiskFinding(
          id: 'recovery',
          title: '恢復狀態偏緊繃',
          detail:
              '平均靜息心率 ${avgHeart.round()} bpm、HRV ${avgHrv.round()} ms、睡眠品質 ${avgSleepQuality.round()} 分。',
          suggestion: '今天先降低高強度活動，保留 10 分鐘低刺激放鬆時間。',
          level: RiskLevel.medium,
        ),
      );
    }

    score = score.clamp(0, 100).round();
    final goals = _goalsFor(findings);
    final futureMessage = _futureMessage(score, findings);

    return HealthAssessment(
      score: score,
      findings: findings,
      goals: goals,
      weeklyStats: WeeklyStats(
        averageSleepHours: avgSleep,
        averageSteps: avgSteps.round(),
        averageActiveMinutes: avgActive.round(),
        averageSedentaryHours: sedentaryHours,
        sleepTargetDays: sleepTargetDays,
        stepTrendPercent: stepTrend,
        sedentaryBreakTarget: (avgSedentaryMinutes / 60).ceil(),
      ),
      futureMessage: futureMessage,
      narrative:
          '本週重點不是診斷疾病，而是把穿戴資料轉成可執行行動。系統已依睡眠、步數、活動分鐘、久坐、心率與 HRV 建立個人化趨勢判讀。',
    );
  }

  static List<HealthGoal> _goalsFor(List<RiskFinding> findings) {
    final goals = <HealthGoal>[];
    final ids = findings.map((finding) => finding.id).toSet();

    if (ids.contains('sleep_debt') ||
        ids.contains('sleep_warning') ||
        ids.contains('late_schedule')) {
      goals.add(
        const HealthGoal(
          id: 'sleep_30',
          title: '今晚提早 30 分鐘睡',
          action: '睡前 30 分鐘關閉高刺激螢幕，保留固定洗漱流程。',
          reason: '先提高睡眠達標天數，比追求一次睡滿更容易持續。',
          metricLabel: '睡眠達標天數 +1',
        ),
      );
    }

    if (ids.contains('sedentary') || ids.contains('sedentary_warning')) {
      goals.add(
        const HealthGoal(
          id: 'stand_60',
          title: '每 60 分鐘起身 5 分鐘',
          action: '在讀書或工作時段設定整點提醒，一天先完成 3 次。',
          reason: '降低久坐連續性，比單純增加運動量更適合辦公與宿舍場域。',
          metricLabel: '久坐中斷次數 +20%',
        ),
      );
    }

    if (ids.contains('low_activity')) {
      goals.add(
        const HealthGoal(
          id: 'walk_1000',
          title: '本週每日多走 1000 步',
          action: '把多走 1000 步拆成午餐後 500 步、晚餐後 500 步。',
          reason: '小幅增加活動量能降低提醒排斥感，也方便用穿戴資料驗證。',
          metricLabel: '每日步數 +10%',
        ),
      );
    }

    if (goals.isEmpty) {
      goals.addAll(const [
        HealthGoal(
          id: 'maintain_sleep',
          title: '維持 7 小時睡眠',
          action: '保留目前作息，連續 4 天維持 7 小時以上睡眠。',
          reason: '穩定作息是後續活動量與恢復狀態判讀的基準。',
          metricLabel: '睡眠穩定',
        ),
        HealthGoal(
          id: 'light_walk',
          title: '晚餐後散步 10 分鐘',
          action: '選擇固定路線，不以速度或距離作為壓力。',
          reason: '在健康分數穩定時，輕量活動能維持使用者參與。',
          metricLabel: '活動分鐘維持',
        ),
      ]);
    }

    return goals.take(3).toList();
  }

  static String _futureMessage(int score, List<RiskFinding> findings) {
    if (score >= 82) {
      return '一週後的你會看起來更穩定：作息與活動量已形成可維持節奏。';
    }
    if (findings.any((finding) => finding.id.contains('sleep'))) {
      return '如果晚睡持續，三天後的你可能更難集中；先把今晚睡眠提前 30 分鐘。';
    }
    if (findings.any((finding) => finding.id.contains('sedentary'))) {
      return '如果久坐不中斷，未來自我會更容易疲累；今天先完成 3 次起身。';
    }
    return '目前趨勢需要一個小改變：選一個最容易執行的目標，讓資料開始轉向。';
  }

  static int _trailingCount(
    List<HealthSample> samples,
    bool Function(HealthSample sample) test,
  ) {
    var count = 0;
    for (final sample in samples.reversed) {
      if (!test(sample)) {
        break;
      }
      count += 1;
    }
    return count;
  }

  static double _average(Iterable<double> values) {
    final list = values.toList();
    if (list.isEmpty) {
      return 0;
    }
    return list.reduce((a, b) => a + b) / list.length;
  }

  static double _trendPercent(Iterable<int> values) {
    final list = values.toList();
    if (list.length < 4) {
      return 0;
    }
    final pivot = list.length ~/ 2;
    final first = _average(list.take(pivot).map((value) => value.toDouble()));
    final second = _average(list.skip(pivot).map((value) => value.toDouble()));
    if (first == 0) {
      return 0;
    }
    return ((second - first) / first) * 100;
  }
}
