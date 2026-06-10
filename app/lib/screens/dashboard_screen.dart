import 'package:flutter/material.dart';

import '../main.dart';
import '../widgets/metric_card.dart';
import '../widgets/mini_trend_chart.dart';
import '../widgets/mirror_panel.dart';
import '../widgets/risk_card.dart';
import '../widgets/section_header.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = HealthMirrorScope.of(context);
    final samples = controller.samples;
    final assessment = controller.assessment;
    final latest = samples.isEmpty ? null : samples.last;
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        MirrorPanel(assessment: assessment, latest: latest),
        const SizedBox(height: 24),
        const SectionHeader(title: '今日狀態', subtitle: '把穿戴資料轉成可掃描的行為訊號。'),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 760 ? 4 : 2;
            return GridView.count(
              crossAxisCount: columns,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: columns == 4 ? 1.05 : 1.0,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                MetricCard(
                  title: '睡眠',
                  value: latest == null
                      ? '--'
                      : latest.sleepHours.toStringAsFixed(1),
                  unit: '小時',
                  helper: '${assessment.weeklyStats.sleepTargetDays}/7 天達標',
                  icon: Icons.bedtime_outlined,
                  color: scheme.tertiary,
                ),
                MetricCard(
                  title: '步數',
                  value: latest == null ? '--' : '${latest.steps}',
                  unit: '步',
                  helper:
                      '週趨勢 ${assessment.weeklyStats.stepTrendPercent.toStringAsFixed(0)}%',
                  icon: Icons.directions_walk_outlined,
                  color: scheme.primary,
                ),
                MetricCard(
                  title: '活動',
                  value: latest == null ? '--' : '${latest.activeMinutes}',
                  unit: '分鐘',
                  helper:
                      '週平均 ${assessment.weeklyStats.averageActiveMinutes} 分',
                  icon: Icons.timer_outlined,
                  color: scheme.secondary,
                ),
                MetricCard(
                  title: '久坐',
                  value: latest == null
                      ? '--'
                      : (latest.sedentaryMinutes / 60).toStringAsFixed(1),
                  unit: '小時',
                  helper: '建議每 60 分鐘中斷',
                  icon: Icons.event_seat_outlined,
                  color: scheme.error,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        SectionHeader(
          title: '健康趨勢',
          subtitle: assessment.findings.isEmpty
              ? '目前沒有明顯生活型風險。'
              : '偵測到 ${assessment.findings.length} 個需要介入的趨勢。',
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 760;
            final charts = [
              MiniTrendChart(
                label: '近 14 日睡眠時數',
                values: samples.map((sample) => sample.sleepHours).toList(),
                color: scheme.tertiary,
              ),
              MiniTrendChart(
                label: '近 14 日步數',
                values: samples
                    .map((sample) => sample.steps.toDouble())
                    .toList(),
                color: scheme.primary,
              ),
            ];
            if (!wide) {
              return Column(
                children: [
                  charts.first,
                  const SizedBox(height: 12),
                  charts.last,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: charts.first),
                const SizedBox(width: 12),
                Expanded(child: charts.last),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        const SectionHeader(title: '風險與介入', subtitle: '規則式判讀只做健康促進，不做疾病診斷。'),
        const SizedBox(height: 12),
        if (assessment.findings.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline, color: scheme.primary),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('本週作息與活動趨勢穩定，建議維持目前節奏並保留輕量目標。')),
                ],
              ),
            ),
          )
        else
          ...assessment.findings.map(
            (finding) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: RiskCard(finding: finding),
            ),
          ),
      ],
    );
  }
}
