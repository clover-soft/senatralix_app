import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AssistantSessionsScreen extends StatelessWidget {
  const AssistantSessionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final id = GoRouterState.of(context).pathParameters['assistantId'] ?? 'unknown';
    return Scaffold(
      appBar: AppBar(title: Text('Assistant • Sessions ($id)')),
      body: Center(child: Text('Sessions for assistantId=$id (threads, stub)')),
    );
  }
}
