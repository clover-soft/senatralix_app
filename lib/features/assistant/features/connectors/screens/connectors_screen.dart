import 'package:flutter/material.dart';

class AssistantConnectorsScreen extends StatelessWidget {
  const AssistantConnectorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assistant • Connectors')),
      body: const Center(child: Text('Connectors (VOIP, Telegram, Avito, WhatsApp — future)')),
    );
  }
}
