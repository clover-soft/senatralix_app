import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AssistantSettingsScreen extends StatelessWidget {
  const AssistantSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final id = GoRouterState.of(context).pathParameters['assistantId'] ?? 'unknown';
    return Scaffold(
      appBar: AppBar(title: Text('Assistant • Settings ($id)')),
      body: Center(
        child: Text('Settings for assistantId=$id (prompt, temperature, model, tokens limit)'),
      ),
    );
  }
}
