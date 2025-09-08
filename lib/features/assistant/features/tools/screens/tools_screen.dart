import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AssistantToolsScreen extends StatelessWidget {
  const AssistantToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final id = GoRouterState.of(context).pathParameters['assistantId'] ?? 'unknown';
    return Scaffold(
      appBar: AppBar(title: Text('Assistant • Tools ($id)')),
      body: Center(child: Text('Tools for assistantId=$id (user-defined assistant tools)')),
    );
  }
}
