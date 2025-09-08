import 'package:flutter/material.dart';

class AssistantChatScreen extends StatelessWidget {
  const AssistantChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assistant • Chat')),
      body: const Center(child: Text('Chat with assistant (stub)')),
    );
  }
}
