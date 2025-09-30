import 'package:flutter/foundation.dart';

/// Модель слота диалога
@immutable
class DialogSlot {
  const DialogSlot({
    required this.id,
    required this.name,
    required this.label,
    required this.prompt,
    required this.options,
    required this.hints,
    required this.metadata,
    required this.slotType,
  });

  final int id;
  final String name;
  final String label;
  final String prompt;
  final List<String> options;
  final List<String> hints;
  final Map<String, dynamic> metadata;
  final String slotType;

  factory DialogSlot.fromJson(Map<String, dynamic> json) {
    return DialogSlot(
      id: (json['id'] as num).toInt(),
      name: (json['name'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      prompt: (json['prompt'] ?? '').toString(),
      options: (json['options'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      hints: (json['hints'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      metadata: Map<String, dynamic>.from(
        (json['metadata'] as Map?) ?? const <String, dynamic>{},
      ),
      slotType: (json['slot_type'] ?? '').toString(),
    );
  }
}
