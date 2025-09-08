import 'package:flutter/material.dart';

class AssistantSessionsScreen extends StatelessWidget {
  const AssistantSessionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assistant • Sessions')),
      body: const Center(child: Text('Sessions (threads, stub)')),
    );
  }
}
