import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:code_text_field/code_text_field.dart';
import 'package:highlight/languages/json.dart' as hl_json;
import 'package:sentralix_app/features/assistant/features/scripts/data/script_filter_presets.dart';
import 'package:sentralix_app/features/assistant/features/scripts/models/message_filter_form_state.dart';
import 'package:sentralix_app/features/assistant/features/scripts/models/script_command_edit_state.dart';

/// Контроллер формы редактирования команды
class ScriptCommandEditController extends StateNotifier<ScriptCommandEditState> {
  bool _inited = false;
  ScriptCommandEditController() : super(ScriptCommandEditState.initial());

  void initIfNeeded(ScriptCommandEditState initial) {
    if (_inited) return;
    state = initial;
    _inited = true;
  }

  void setOrder(int v) => state = state.copy(order: v);
  void setName(String v) => state = state.copy(name: v);
  void setDescription(String v) => state = state.copy(description: v);
  void setFilter(String v) => state = state.copy(filterExpression: v);
  void setActive(bool v) => state = state.copy(isActive: v);
}

/// Провайдер состояния формы (autoDispose, чтобы не висел в памяти)
/// Ключ family: assistantId:scriptId | assistantId:new
final scriptCommandEditProvider = StateNotifierProvider.autoDispose
    .family<ScriptCommandEditController, ScriptCommandEditState, String>(
  (ref, key) => ScriptCommandEditController(),
);

/// Выбранный пресет фильтра (для текущего экземпляра редактора)
/// Ключ: assistantId:scriptId | assistantId:new
final scriptPresetProvider = StateProvider.autoDispose
    .family<ScriptFilterPreset, String>((ref, key) {
  // По умолчанию — custom, пока не распознали
  return ScriptFilterPreset.custom;
});

/// Подформа фильтра сообщений (значения по умолчанию)
class MessageFilterFormController
    extends StateNotifier<MessageFilterFormState> {
  MessageFilterFormController(super.state);
  void loadFromParsed(MessageFilterFormState s) {
    state = s;
  }
  void toggleRole(MessageRole role, bool value) {
    final s = state;
    final roles = Set<MessageRole>.from(s.roles);
    if (value) {
      roles.add(role);
    } else {
      roles.remove(role);
      if (roles.isEmpty) roles.add(MessageRole.user); // минимум 1 роль
    }
    state = s.copyWith(roles: roles);
  }

  void setType(MessageFilterType t) => state = state.copyWith(type: t);
  void setText(String v) => state = state.copyWith(textOrPattern: v);
  void setFlags(List<String> flags) => state = state.copyWith(flags: flags);
}

final messageFilterFormProvider = StateNotifierProvider.autoDispose
    .family<MessageFilterFormController, MessageFilterFormState, String>(
  (ref, key) => MessageFilterFormController(MessageFilterFormState.initial()),
);

/// Флаг одноразовой инициализации экрана редактора, чтобы не вызывать init в каждом билдё
final scriptEditorInitProvider = StateProvider.autoDispose
    .family<bool, String>((ref, key) => false);

/// Контроллер текстового поля filter_expression, привязанный к экземпляру редактора
final filterControllerProvider = Provider
    .family<TextEditingController, String>((ref, key) {
  final c = TextEditingController();
  ref.onDispose(() => c.dispose());
  return c;
});

/// Контроллер поля Название, привязанный к экземпляру редактора
final nameControllerProvider = Provider
    .family<TextEditingController, String>((ref, key) {
  final c = TextEditingController();
  ref.onDispose(() => c.dispose());
  return c;
});

/// Контроллер поля Описание, привязанный к экземпляру редактора
final descriptionControllerProvider = Provider
    .family<TextEditingController, String>((ref, key) {
  final c = TextEditingController();
  ref.onDispose(() => c.dispose());
  return c;
});

/// Контроллер CodeEditor для поля JSON с подсветкой, привязанный к экземпляру редактора
final codeControllerProvider = Provider
    .family<CodeController, String>((ref, key) {
  final c = CodeController(
    language: hl_json.json,
    text: '',
  );
  ref.onDispose(() => c.dispose());
  return c;
});

/// FocusNode для редактора JSON, чтобы понимать, редактирует ли сейчас пользователь
final codeFocusNodeProvider = Provider
    .family<FocusNode, String>((ref, key) {
  final node = FocusNode();
  ref.onDispose(() => node.dispose());
  return node;
});

/// Показать/скрыть поле raw JSON filter_expression на экране редактора
final showRawJsonProvider = StateProvider.autoDispose
    .family<bool, String>((ref, key) => false);

/// Сообщение об ошибке в поле raw JSON (null, если валидно)
final rawJsonErrorProvider = StateProvider.autoDispose
    .family<String?, String>((ref, key) => null);
