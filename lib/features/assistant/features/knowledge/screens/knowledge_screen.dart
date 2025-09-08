import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sentralix_app/features/assistant/widgets/assistant_app_bar.dart';

class AssistantKnowledgeScreen extends StatelessWidget {
  const AssistantKnowledgeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final id = GoRouterState.of(context).pathParameters['assistantId'] ?? 'unknown';
    return Scaffold(
      appBar: AssistantAppBar(assistantId: id, subfeatureTitle: 'Knowledge'),
      body: const Center(
        child: Text('Knowledge base (admin uploads)'),
      ),
    );
  }
}
