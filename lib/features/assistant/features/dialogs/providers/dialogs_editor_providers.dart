import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/controllers/dialogs_editor_controller.dart';

/// Контроллер редактора
final dialogsEditorControllerProvider =
    StateNotifierProvider<DialogsEditorController, DialogsEditorState>((ref) {
      return DialogsEditorController(ref);
    });
