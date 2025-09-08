import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AssistantConnectorsScreen extends StatelessWidget {
  const AssistantConnectorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final id = GoRouterState.of(context).pathParameters['assistantId'] ?? 'unknown';
    return Scaffold(
      appBar: AppBar(title: Text('Assistant • Connectors ($id)')),
      body: Center(child: Text('Connectors for assistantId=$id (VOIP, Telegram, Avito, WhatsApp — future)')),
    );
  }
}
