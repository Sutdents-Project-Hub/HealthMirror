import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../main.dart';
import '../models/health_models.dart';
import '../widgets/mini_trend_chart.dart';
import '../widgets/section_header.dart';

class DataScreen extends StatelessWidget {
  const DataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = HealthMirrorScope.of(context);
    final samples = controller.samples.reversed.toList();
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        SectionHeader(
          title: '穿戴資料輸入',
          subtitle: '可用模擬資料展示流程，也可手動填入今日狀態。',
          trailing: FilledButton.icon(
            onPressed: () => _openEditor(context),
            icon: const Icon(Icons.add),
            label: const Text('填寫今日'),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.tonalIcon(
                  onPressed: controller.generateRandomSimulation,
                  icon: const Icon(Icons.auto_graph_outlined),
                  label: const Text('Random 生成 14 日資料'),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => _openEditor(
                    context,
                    initial: controller.samples.isEmpty
                        ? null
                        : controller.samples.last,
                  ),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('編輯最新資料'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        MiniTrendChart(
          label: '睡眠品質趨勢',
          values: controller.samples
              .map((sample) => sample.sleepQuality.toDouble())
              .toList(),
          color: scheme.secondary,
        ),
        const SizedBox(height: 16),
        const SectionHeader(
          title: '資料紀錄',
          subtitle: '原型先以本機資料模擬 Apple Health、Google Fit 或手環匯入流程。',
        ),
        const SizedBox(height: 12),
        ...samples.map(
          (sample) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _SampleTile(sample: sample),
          ),
        ),
      ],
    );
  }

  Future<void> _openEditor(
    BuildContext context, {
    HealthSample? initial,
  }) async {
    final controller = HealthMirrorScope.of(context);
    final today = DateTime.now();
    final fallback = HealthSample(
      date: DateTime(today.year, today.month, today.day),
      sleepHours: 7,
      sleepQuality: 78,
      steps: 7200,
      activeMinutes: 38,
      restingHeartRate: 66,
      hrv: 48,
      sedentaryMinutes: 500,
      bedtimeHour: 23.5,
    );

    final sample = await showModalBottomSheet<HealthSample>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _SampleEditorSheet(initial: initial ?? fallback),
    );

    if (sample != null && context.mounted) {
      await controller.upsertSample(sample);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('健康資料已儲存在本機。')));
      }
    }
  }
}

class _SampleTile extends StatelessWidget {
  const _SampleTile({required this.sample});

  final HealthSample sample;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        minVerticalPadding: 14,
        leading: const Icon(Icons.watch_outlined),
        title: Text(sample.dateKey),
        subtitle: Text(
          '睡眠 ${sample.sleepHours.toStringAsFixed(1)}h · ${sample.steps} 步 · 活動 ${sample.activeMinutes}m · 久坐 ${(sample.sedentaryMinutes / 60).toStringAsFixed(1)}h',
        ),
        trailing: Text(
          '${sample.sleepQuality}',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _SampleEditorSheet extends StatefulWidget {
  const _SampleEditorSheet({required this.initial});

  final HealthSample initial;

  @override
  State<_SampleEditorSheet> createState() => _SampleEditorSheetState();
}

class _SampleEditorSheetState extends State<_SampleEditorSheet> {
  late double _sleepHours;
  late double _sleepQuality;
  late double _activeMinutes;
  late double _sedentaryHours;
  late final TextEditingController _stepsController;
  late final TextEditingController _heartController;
  late final TextEditingController _hrvController;
  late final TextEditingController _bedtimeController;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _sleepHours = initial.sleepHours;
    _sleepQuality = initial.sleepQuality.toDouble();
    _activeMinutes = initial.activeMinutes.toDouble();
    _sedentaryHours = initial.sedentaryMinutes / 60;
    _stepsController = TextEditingController(text: '${initial.steps}');
    _heartController = TextEditingController(
      text: '${initial.restingHeartRate}',
    );
    _hrvController = TextEditingController(text: '${initial.hrv}');
    _bedtimeController = TextEditingController(
      text: initial.bedtimeHour.toStringAsFixed(1),
    );
  }

  @override
  void dispose() {
    _stepsController.dispose();
    _heartController.dispose();
    _hrvController.dispose();
    _bedtimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 0, 16, bottom + 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '今日健康資料',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            _MetricSlider(
              label: '睡眠時數',
              value: _sleepHours,
              min: 3,
              max: 10,
              divisions: 14,
              suffix: '小時',
              onChanged: (value) => setState(() => _sleepHours = value),
            ),
            _MetricSlider(
              label: '睡眠品質',
              value: _sleepQuality,
              min: 0,
              max: 100,
              divisions: 20,
              suffix: '分',
              onChanged: (value) => setState(() => _sleepQuality = value),
            ),
            _MetricSlider(
              label: '活動分鐘',
              value: _activeMinutes,
              min: 0,
              max: 120,
              divisions: 24,
              suffix: '分鐘',
              onChanged: (value) => setState(() => _activeMinutes = value),
            ),
            _MetricSlider(
              label: '久坐時間',
              value: _sedentaryHours,
              min: 2,
              max: 12,
              divisions: 20,
              suffix: '小時',
              onChanged: (value) => setState(() => _sedentaryHours = value),
            ),
            const SizedBox(height: 8),
            _NumberField(
              controller: _stepsController,
              label: '步數',
              helper: '例如 8000',
            ),
            const SizedBox(height: 12),
            _NumberField(
              controller: _heartController,
              label: '靜息心率',
              helper: '單位 bpm',
            ),
            const SizedBox(height: 12),
            _NumberField(
              controller: _hrvController,
              label: 'HRV',
              helper: '單位 ms',
            ),
            const SizedBox(height: 12),
            _NumberField(
              controller: _bedtimeController,
              label: '就寢時間',
              helper: '23.5 代表 23:30；24.5 代表 00:30',
              allowDecimal: true,
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _save,
                    child: const Text('儲存'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    final now = DateTime.now();
    final sample = HealthSample(
      date: DateTime(now.year, now.month, now.day),
      sleepHours: _sleepHours,
      sleepQuality: _sleepQuality.round(),
      steps: int.tryParse(_stepsController.text) ?? widget.initial.steps,
      activeMinutes: _activeMinutes.round(),
      restingHeartRate:
          int.tryParse(_heartController.text) ??
          widget.initial.restingHeartRate,
      hrv: int.tryParse(_hrvController.text) ?? widget.initial.hrv,
      sedentaryMinutes: (_sedentaryHours * 60).round(),
      bedtimeHour:
          double.tryParse(_bedtimeController.text) ??
          widget.initial.bedtimeHour,
    );
    Navigator.pop(context, sample);
  }
}

class _MetricSlider extends StatelessWidget {
  const _MetricSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.suffix,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String suffix;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label)),
            Text('${value.toStringAsFixed(1)} $suffix'),
          ],
        ),
        Slider(
          value: value.clamp(min, max).toDouble(),
          min: min,
          max: max,
          divisions: divisions,
          label: value.toStringAsFixed(1),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    required this.helper,
    this.allowDecimal = false,
  });

  final TextEditingController controller;
  final String label;
  final String helper;
  final bool allowDecimal;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: 1,
      keyboardType: TextInputType.numberWithOptions(decimal: allowDecimal),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          allowDecimal ? RegExp(r'[0-9.]') : RegExp(r'[0-9]'),
        ),
      ],
      decoration: InputDecoration(labelText: label, helperText: helper),
    );
  }
}
