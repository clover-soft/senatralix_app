import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AssistantKnowledgeScreen extends StatelessWidget {
  const AssistantKnowledgeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final id = GoRouterState.of(context).pathParameters['assistantId'] ?? 'unknown';
    return Scaffold(
      appBar: AppBar(title: Text('Assistant • Knowledge Base ($id)')),
      body: Center(child: Text('Knowledge base for assistantId=$id (admin uploads)')),
    );
  }
}
