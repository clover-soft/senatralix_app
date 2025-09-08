import 'package:flutter/material.dart';

class AssistantScriptsScreen extends StatelessWidget {
  const AssistantScriptsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assistant • Scripts')),
      body: const Center(child: Text('Scripts (on events: enter/leave dialog, triggers, etc.)')),
    );
  }
}
