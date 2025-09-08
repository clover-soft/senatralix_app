import 'package:flutter/material.dart';

class AssistantSettingsScreen extends StatelessWidget {
  const AssistantSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assistant • Settings')),
      body: const Center(child: Text('Settings (prompt, temperature, model, tokens limit)')),
    );
  }
}
