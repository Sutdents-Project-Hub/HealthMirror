import 'package:flutter/material.dart';

import '../main.dart';
import '../models/health_models.dart';
import '../widgets/section_header.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = HealthMirrorScope.of(context);
    final goals = controller.assessment.goals;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        const SectionHeader(
          title: '小目標與回饋',
          subtitle: '記錄提醒接受、目標完成與使用者回饋，作為後續模型修正依據。',
        ),
        const SizedBox(height: 12),
        ...goals.map(
          (goal) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _GoalCard(goal: goal),
          ),
        ),
      ],
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.goal});

  final HealthGoal goal;

  @override
  Widget build(BuildContext context) {
    final controller = HealthMirrorScope.of(context);
    final progress = controller.progressFor(goal.id);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.flag_outlined, color: scheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(goal.action),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              goal.reason,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Chip(
              avatar: const Icon(Icons.analytics_outlined, size: 18),
              label: Text(goal.metricLabel),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: .45),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '接受提醒',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Switch(
                        value: progress.accepted,
                        onChanged: (value) =>
                            controller.setGoalAccepted(goal.id, value),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Checkbox(
                        value: progress.completed,
                        onChanged: progress.accepted
                            ? (value) => controller.setGoalCompleted(
                                goal.id,
                                value ?? false,
                              )
                            : null,
                      ),
                      Expanded(
                        child: Text(
                          '今天已完成',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: progress.accepted
                                ? scheme.onSurface
                                : scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      IconButton.outlined(
                        tooltip: '記錄回饋',
                        onPressed: () => _openFeedbackDialog(context, progress),
                        icon: const Icon(Icons.rate_review_outlined),
                      ),
                    ],
                  ),
                  if (progress.feedback.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '回饋：${progress.feedback}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openFeedbackDialog(
    BuildContext context,
    GoalProgress progress,
  ) async {
    final controller = HealthMirrorScope.of(context);
    final textController = TextEditingController(text: progress.feedback);
    final feedback = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('目標回饋'),
        content: TextField(
          controller: textController,
          autofocus: true,
          minLines: 3,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: '今天執行感受',
            helperText: '例如：提醒太頻繁、目標可行、需要降低門檻',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, textController.text),
            child: const Text('儲存'),
          ),
        ],
      ),
    );
    textController.dispose();

    if (feedback != null) {
      await controller.saveGoalFeedback(goal.id, feedback);
    }
  }
}
