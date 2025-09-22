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
    _syncControllers(settings);

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
                  _buildProviderField(context, settings),
                  SizedBox(height: 16.h),
                  _buildApiKeyField(context),
                  SizedBox(height: 16.h),
                  _buildBaseUrlField(context, settings),
                  SizedBox(height: 16.h),
                  _buildEndpointField(context, settings),
                  SizedBox(height: 16.h),
                  _buildModelField(context, settings),
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
      '各自で取得したAPIキーとエンドポイントを設定すると、保存したURLをAIで要約できます。OpenAI互換のAPIまたはGemini APIを利用できます。',
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }

  Widget _buildProviderField(BuildContext context, AiSettings settings) {
    return DropdownButtonFormField<AiProvider>(
      value: settings.provider,
      decoration: const InputDecoration(
        labelText: 'AIプロバイダー',
      ),
      onChanged: (value) {
        if (value != null) {
          ref.read(aiSettingsProvider.notifier).updateProvider(value);
        }
      },
      items: AiProvider.values
          .map(
            (provider) => DropdownMenuItem<AiProvider>(
              value: provider,
              child: Text(_providerLabel(provider)),
            ),
          )
          .toList(),
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

  Widget _buildBaseUrlField(BuildContext context, AiSettings settings) {
    return TextField(
      controller: _baseUrlController,
      decoration: InputDecoration(
        labelText: 'ベースURL',
        hintText: _baseUrlHint(settings.provider),
      ),
      keyboardType: TextInputType.url,
      onChanged: (value) {
        ref.read(aiSettingsProvider.notifier).updateBaseUrl(value);
      },
    );
  }

  Widget _buildEndpointField(BuildContext context, AiSettings settings) {
    return TextField(
      controller: _endpointController,
      decoration: InputDecoration(
        labelText: 'エンドポイントパス',
        hintText: _endpointHint(settings.provider),
      ),
      onChanged: (value) {
        ref.read(aiSettingsProvider.notifier).updateEndpointPath(value);
      },
    );
  }

  Widget _buildModelField(BuildContext context, AiSettings settings) {
    return TextField(
      controller: _modelController,
      decoration: InputDecoration(
        labelText: 'モデル名',
        hintText: _modelHint(settings.provider),
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

  void _syncControllers(AiSettings settings) {
    _updateControllerIfNeeded(_apiKeyController, settings.apiKey);
    _updateControllerIfNeeded(_baseUrlController, settings.baseUrl);
    _updateControllerIfNeeded(_endpointController, settings.endpointPath);
    _updateControllerIfNeeded(_modelController, settings.model);
  }

  void _updateControllerIfNeeded(
    TextEditingController controller,
    String newValue,
  ) {
    if (controller.text == newValue) {
      return;
    }
    controller
      ..text = newValue
      ..selection = TextSelection.collapsed(offset: newValue.length);
  }

  String _providerLabel(AiProvider provider) {
    switch (provider) {
      case AiProvider.openAi:
        return 'OpenAI互換';
      case AiProvider.gemini:
        return 'Gemini';
    }
  }

  String _baseUrlHint(AiProvider provider) {
    switch (provider) {
      case AiProvider.openAi:
        return 'https://api.openai.com/v1';
      case AiProvider.gemini:
        return 'https://generativelanguage.googleapis.com';
    }
  }

  String _endpointHint(AiProvider provider) {
    switch (provider) {
      case AiProvider.openAi:
        return '/chat/completions';
      case AiProvider.gemini:
        return '/v1beta/models/gemini-1.5-flash:generateContent';
    }
  }

  String _modelHint(AiProvider provider) {
    switch (provider) {
      case AiProvider.openAi:
        return 'gpt-4o-mini など';
      case AiProvider.gemini:
        return 'gemini-1.5-flash など';
    }
  }
}
