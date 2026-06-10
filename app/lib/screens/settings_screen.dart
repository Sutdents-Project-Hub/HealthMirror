import 'package:flutter/material.dart';

import '../main.dart';
import '../models/health_models.dart';
import '../services/health_mirror_controller.dart';
import '../widgets/section_header.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _endpointController;
  late TextEditingController _apiKeyController;
  late TextEditingController _modelController;
  bool _enabled = false;
  bool _obscureKey = true;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    final settings = HealthMirrorScope.of(context).settings;
    _endpointController = TextEditingController(text: settings.endpoint);
    _apiKeyController = TextEditingController(text: settings.apiKey);
    _modelController = TextEditingController(text: settings.model);
    _enabled = settings.enabled;
    _initialized = true;
  }

  @override
  void dispose() {
    _endpointController.dispose();
    _apiKeyController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = HealthMirrorScope.of(context);
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        const SectionHeader(
          title: '設定',
          subtitle: '資料與 AI 呼叫都由 App 本機處理，不需要後端。',
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.shuffle_outlined, color: scheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      '模擬資料',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  '競賽展示時可直接 random 生成 14 日穿戴資料，包含睡眠、步數、活動分鐘、心率、HRV、久坐與就寢時間。',
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _generateRandomData(controller),
                    icon: const Icon(Icons.shuffle_outlined),
                    label: const Text('一鍵 Random 生成資料'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Form(
          key: _formKey,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _enabled,
                    onChanged: (value) => setState(() => _enabled = value),
                    title: const Text('啟用 AI 建議'),
                    subtitle: const Text('關閉時仍可使用規則式趨勢判讀與週報。'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _endpointController,
                    keyboardType: TextInputType.url,
                    textCapitalization: TextCapitalization.none,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: const InputDecoration(
                      labelText: 'API URL',
                      helperText:
                          'OpenAI-compatible chat completions endpoint，例如 https://api.example.com/v1/chat/completions',
                      helperMaxLines: 2,
                    ),
                    validator: (value) {
                      if (!_enabled) {
                        return null;
                      }
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) {
                        return '啟用 AI 時必須填寫 API URL';
                      }
                      return Uri.tryParse(text)?.hasAbsolutePath == true
                          ? null
                          : '請填寫有效 URL';
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _apiKeyController,
                    obscureText: _obscureKey,
                    keyboardType: TextInputType.visiblePassword,
                    textCapitalization: TextCapitalization.none,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: InputDecoration(
                      labelText: 'API Key',
                      helperText: '只儲存在本機 SharedPreferences，不會送到後端。',
                      helperMaxLines: 2,
                      suffixIcon: IconButton(
                        tooltip: _obscureKey ? '顯示 API Key' : '隱藏 API Key',
                        onPressed: () {
                          setState(() => _obscureKey = !_obscureKey);
                        },
                        icon: Icon(
                          _obscureKey
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _modelController,
                    keyboardType: TextInputType.visiblePassword,
                    textCapitalization: TextCapitalization.none,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: const InputDecoration(
                      labelText: '模型名稱',
                      helperText: '依你的 API 供應商填寫；空白時使用 App 預設值。',
                      helperMaxLines: 2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: () => _save(controller),
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('儲存設定'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.privacy_tip_outlined, color: scheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      '隱私與安全定位',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  '原型採同意制資料輸入，資料預設只存在 App 本機。若啟用 AI，App 會把摘要後的健康資料直接送到你設定的 API URL；正式產品應改用安全儲存、匿名化與更完整的同意流程。',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '原型驗證目標',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                const Text('資料同步成功率 80% 以上。'),
                const Text('規則式風險偵測與人工標註一致率 85% 以上。'),
                const Text('每週報告產生時間小於 30 秒。'),
                const Text('理解度與實用性問卷平均 4/5 分以上。'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _generateRandomData(HealthMirrorController controller) async {
    await controller.generateRandomSimulation();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('已 random 生成 14 日模擬健康資料。')));
    }
  }

  Future<void> _save(HealthMirrorController controller) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    await controller.updateSettings(
      AiSettings(
        enabled: _enabled,
        endpoint: _endpointController.text.trim(),
        apiKey: _apiKeyController.text.trim(),
        model: _normalizeModelName(_modelController.text),
      ),
    );
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('設定已儲存在本機。')));
    }
  }

  String _normalizeModelName(String value) {
    final model = value.trim();
    if (model.isEmpty) {
      return 'gpt-4.1-mini';
    }
    if (model.toLowerCase().startsWith('gemini-')) {
      return model.toLowerCase();
    }
    return model;
  }
}
