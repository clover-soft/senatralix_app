import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AssistantScriptsScreen extends StatelessWidget {
  const AssistantScriptsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final id = GoRouterState.of(context).pathParameters['assistantId'] ?? 'unknown';
    return Scaffold(
      appBar: AppBar(title: Text('Assistant • Scripts ($id)')),
      body: Center(child: Text('Scripts for assistantId=$id (on events: enter/leave dialog, triggers, etc.)')),
    );
  }
}
