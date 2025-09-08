import 'package:flutter/material.dart';

class AssistantKnowledgeScreen extends StatelessWidget {
  const AssistantKnowledgeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assistant • Knowledge Base')),
      body: const Center(child: Text('Knowledge base management (admin uploads)')),
    );
  }
}
