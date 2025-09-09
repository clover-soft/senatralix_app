import 'dart:convert';
import 'package:sentralix_app/features/assistant/models/assistant_tool.dart';

/// Состояние редактора Function Tool
class FunctionToolEditState {
  FunctionToolEditState({
    required this.name,
    required this.description,
    required this.parametersJson,
  });

  final String name;
  final String description;
  final String parametersJson; // JSON Schema (как текст)

  FunctionToolEditState copy({String? name, String? description, String? parametersJson}) =>
      FunctionToolEditState(
        name: name ?? this.name,
        description: description ?? this.description,
        parametersJson: parametersJson ?? this.parametersJson,
      );

  static FunctionToolEditState fromTool(AssistantFunctionTool tool) => FunctionToolEditState(
        name: tool.def.name,
        description: tool.def.description,
        parametersJson: const JsonEncoder.withIndent('  ').convert(
          tool.def.parameters?.toJson() ?? {'type': 'object', 'properties': {}, 'required': []},
        ),
      );
}
