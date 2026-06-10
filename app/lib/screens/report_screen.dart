import 'package:flutter/material.dart';

import '../main.dart';
import '../widgets/metric_card.dart';
import '../widgets/risk_card.dart';
import '../widgets/section_header.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = HealthMirrorScope.of(context);
    final assessment = controller.assessment;
    final stats = assessment.weeklyStats;
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        SectionHeader(
          title: '每週健康報告',
          subtitle: '30 秒內產出可解釋週報，支援規則式與可選 AI 建議。',
          trailing: FilledButton.icon(
            onPressed: controller.isRequestingAi
                ? null
                : controller.requestAiInsight,
            icon: controller.isRequestingAi
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome_outlined),
            label: const Text('產生 AI 建議'),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '本週摘要',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                Text(
                  assessment.narrative,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(height: 1.55),
                ),
                const SizedBox(height: 12),
                Text(
                  '未來自我提示：${assessment.futureMessage}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 760 ? 4 : 2;
            return GridView.count(
              crossAxisCount: columns,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: columns == 4 ? 1.08 : 1.0,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                MetricCard(
                  title: '睡眠達標',
                  value: '${stats.sleepTargetDays}/7',
                  unit: '天',
                  helper: '目標增加 1 天',
                  icon: Icons.hotel_outlined,
                  color: scheme.tertiary,
                ),
                MetricCard(
                  title: '平均步數',
                  value: '${stats.averageSteps}',
                  unit: '步',
                  helper: '場域目標 +10%',
                  icon: Icons.directions_walk_outlined,
                  color: scheme.primary,
                ),
                MetricCard(
                  title: '久坐中斷',
                  value: '${stats.sedentaryBreakTarget}',
                  unit: '次/日',
                  helper: '場域目標 +20%',
                  icon: Icons.accessibility_new_outlined,
                  color: scheme.secondary,
                ),
                MetricCard(
                  title: '規則一致率',
                  value: '85',
                  unit: '%',
                  helper: '原型驗證目標',
                  icon: Icons.rule_outlined,
                  color: scheme.error,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        const SectionHeader(
          title: '風險判讀依據',
          subtitle: '以可解釋規則先驗證流程，後續可替換為機器學習模型。',
        ),
        const SizedBox(height: 12),
        if (assessment.findings.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('本週未偵測到主要生活型風險。'),
            ),
          )
        else
          ...assessment.findings.map(
            (finding) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: RiskCard(finding: finding),
            ),
          ),
        const SizedBox(height: 12),
        _AiInsightCard(
          insight: controller.aiInsight,
          error: controller.aiError,
          settingsReady: controller.settings.canRequest,
        ),
      ],
    );
  }
}

class _AiInsightCard extends StatelessWidget {
  const _AiInsightCard({
    required this.insight,
    required this.error,
    required this.settingsReady,
  });

  final String? insight;
  final String? error;
  final bool settingsReady;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.psychology_alt_outlined, color: scheme.primary),
                const SizedBox(width: 8),
                Text(
                  'AI 教練建議',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (insight != null)
              Text(insight!, style: theme.textTheme.bodyLarge)
            else if (error != null)
              Text(
                error!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.error,
                ),
              )
            else
              Text(
                settingsReady
                    ? '按下「產生 AI 建議」後，App 會直接從本機呼叫你設定的 API URL。'
                    : '尚未設定 API URL。可先使用規則式週報，到設定頁啟用 AI 後再產生建議。',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
