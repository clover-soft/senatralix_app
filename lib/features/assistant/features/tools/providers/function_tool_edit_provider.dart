import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentralix_app/features/assistant/features/tools/models/function_tool_edit_state.dart';
import 'package:sentralix_app/features/assistant/models/assistant_tool.dart';

class FunctionToolEditController extends StateNotifier<FunctionToolEditState> {
  FunctionToolEditController(AssistantFunctionTool initial)
    : super(FunctionToolEditState.fromTool(initial));

  void setName(String v) => state = state.copy(name: v);
  void setDescription(String v) => state = state.copy(description: v);
  void setParametersJson(String v) => state = state.copy(parametersJson: v);

  AssistantFunctionTool buildResult(AssistantFunctionTool initial) {
    // Попытаться распарсить JSON Schema
    final raw = json.decode(state.parametersJson);
    if (raw is! Map<String, dynamic>) {
      throw const FormatException('JSON должен быть объектом');
    }
    final schema = JsonSchemaObject.fromJson(raw);
    return initial.copyWith(
      def: initial.def.copyWith(
        name: state.name.trim(),
        description: state.description.trim(),
        parameters: schema,
      ),
    );
  }
}

final functionToolEditProvider = StateNotifierProvider.autoDispose
    .family<
      FunctionToolEditController,
      FunctionToolEditState,
      AssistantFunctionTool
    >((ref, initial) {
      return FunctionToolEditController(initial);
    });
