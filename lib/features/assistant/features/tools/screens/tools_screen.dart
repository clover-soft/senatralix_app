import 'package:flutter/material.dart';

class AssistantToolsScreen extends StatelessWidget {
  const AssistantToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assistant • Tools')),
      body: const Center(child: Text('Tools (user-defined assistant tools)')),
    );
  }
}
