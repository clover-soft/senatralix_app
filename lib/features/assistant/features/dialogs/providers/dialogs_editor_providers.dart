import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphview/GraphView.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/controllers/dialogs_editor_controller.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/graph/dialogs_graph_builder.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/graph/graph_style.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/utils/dialogs_layout_utils.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/providers/dialogs_config_controller.dart';

/// Контроллер редактора
final dialogsEditorControllerProvider =
    StateNotifierProvider<DialogsEditorController, DialogsEditorState>((ref) {
      return DialogsEditorController(ref);
    });

/// Построенный граф на основе steps и style
final graphProvider = Provider<Graph>((ref) {
  final cfg = ref.watch(dialogsConfigControllerProvider);
  // Жёстко фиксируем Sugiyama сверху-вниз
  final style = GraphStyle.sugiyamaTopBottom(nodeSeparation: 20, levelSeparation: 80);
  final builder = DialogsGraphBuilder(style: style);
  return builder.build(cfg.steps);
});
