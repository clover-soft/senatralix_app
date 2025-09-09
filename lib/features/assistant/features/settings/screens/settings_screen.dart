import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sentralix_app/features/assistant/features/settings/widgets/assistant_settings_form.dart';
import 'package:sentralix_app/features/assistant/widgets/assistant_app_bar.dart';

class AssistantSettingsScreen extends StatelessWidget {
  const AssistantSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final id =
        GoRouterState.of(context).pathParameters['assistantId'] ?? 'unknown';
    return Scaffold(
      appBar: AssistantAppBar(assistantId: id, subfeatureTitle: 'Настройки'),
      body: AssistantSettingsForm(assistantId: id),
    );
  }
}
