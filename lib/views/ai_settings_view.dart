import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_manager/view_models/ai_settings_view_model.dart';

class AiSettingsView extends ConsumerStatefulWidget {
  const AiSettingsView({super.key});

  @override
  ConsumerState<AiSettingsView> createState() => _AiSettingsViewState();
}

class _AiSettingsViewState extends ConsumerState<AiSettingsView> {
  late final TextEditingController _apiKeyController;
  late final TextEditingController _baseUrlController;
  late final TextEditingController _endpointController;
  late final TextEditingController _modelController;
  bool _obscureApiKey = true;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(aiSettingsProvider);
    _apiKeyController = TextEditingController(text: settings.apiKey);
    _baseUrlController = TextEditingController(text: settings.baseUrl);
    _endpointController = TextEditingController(text: settings.endpointPath);
    _modelController = TextEditingController(text: settings.model);
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    _endpointController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(aiSettingsProvider);

    return ScreenUtilInit(
      designSize: const Size(926, 428),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('AI要約設定'),
            actions: [
              TextButton(
                onPressed: () async {
                  await _saveSettings();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('設定を保存しました')), 
                  );
                },
                child: const Text('保存'),
              ),
            ],
          ),
          body: Scrollbar(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDescription(context),
                  SizedBox(height: 24.h),
                  _buildApiKeyField(context),
                  SizedBox(height: 16.h),
                  _buildBaseUrlField(context),
                  SizedBox(height: 16.h),
                  _buildEndpointField(context),
                  SizedBox(height: 16.h),
                  _buildModelField(context),
                  SizedBox(height: 24.h),
                  _buildStatusIndicator(settings),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDescription(BuildContext context) {
    return Text(
      '各自で取得したAPIキーとエンドポイントを設定すると、保存したURLをAIで要約できます。OpenAI互換のAPIであればそのまま利用できます。',
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }

  Widget _buildApiKeyField(BuildContext context) {
    return TextField(
      controller: _apiKeyController,
      obscureText: _obscureApiKey,
      decoration: InputDecoration(
        labelText: 'APIキー',
        suffixIcon: IconButton(
          icon: Icon(_obscureApiKey ? Icons.visibility : Icons.visibility_off),
          onPressed: () {
            setState(() {
              _obscureApiKey = !_obscureApiKey;
            });
          },
        ),
      ),
      onChanged: (value) {
        ref.read(aiSettingsProvider.notifier).updateApiKey(value);
      },
    );
  }

  Widget _buildBaseUrlField(BuildContext context) {
    return TextField(
      controller: _baseUrlController,
      decoration: const InputDecoration(
        labelText: 'ベースURL',
        hintText: 'https://api.openai.com/v1',
      ),
      keyboardType: TextInputType.url,
      onChanged: (value) {
        ref.read(aiSettingsProvider.notifier).updateBaseUrl(value);
      },
    );
  }

  Widget _buildEndpointField(BuildContext context) {
    return TextField(
      controller: _endpointController,
      decoration: const InputDecoration(
        labelText: 'エンドポイントパス',
        hintText: '/chat/completions',
      ),
      onChanged: (value) {
        ref.read(aiSettingsProvider.notifier).updateEndpointPath(value);
      },
    );
  }

  Widget _buildModelField(BuildContext context) {
    return TextField(
      controller: _modelController,
      decoration: const InputDecoration(
        labelText: 'モデル名',
        hintText: 'gpt-4o-mini など',
      ),
      onChanged: (value) {
        ref.read(aiSettingsProvider.notifier).updateModel(value);
      },
    );
  }

  Widget _buildStatusIndicator(AiSettings settings) {
    final isReady = settings.isConfigured;
    return Row(
      children: [
        Icon(
          isReady ? Icons.check_circle : Icons.error_outline,
          color: isReady ? Colors.green : Colors.orange,
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            isReady
                ? '設定済み: 要約画面からAI要約を実行できます。'
                : '未設定: APIキーやエンドポイントを入力してください。',
          ),
        ),
      ],
    );
  }

  Future<void> _saveSettings() async {
    await ref
        .read(aiSettingsProvider.notifier)
        .updateApiKey(_apiKeyController.text);
    await ref
        .read(aiSettingsProvider.notifier)
        .updateBaseUrl(_baseUrlController.text);
    await ref
        .read(aiSettingsProvider.notifier)
        .updateEndpointPath(_endpointController.text);
    await ref
        .read(aiSettingsProvider.notifier)
        .updateModel(_modelController.text);
  }
}
