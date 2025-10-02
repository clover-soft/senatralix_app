import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphview/GraphView.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/controllers/dialogs_editor_controller.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/graph/dialogs_graph_builder.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/graph/graph_style.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/utils/dialogs_layout_utils.dart';
import 'package:sentralix_app/core/logger.dart';

/// Контроллер редактора
final dialogsEditorControllerProvider =
    StateNotifierProvider<DialogsEditorController, DialogsEditorState>((ref) {
      return DialogsEditorController();
    });

/// Построенный граф на основе steps и style
final graphProvider = Provider<Graph>((ref) {
  final editor = ref.watch(dialogsEditorControllerProvider);
  // Жёстко фиксируем Sugiyama сверху-вниз
  final style = GraphStyle.sugiyamaTopBottom(nodeSeparation: 20, levelSeparation: 80);
  final builder = DialogsGraphBuilder(style: style);
  // Лог размера графа (ряды/колонки) по текущей конфигурации
  final stats = computeDialogGridStats(editor.steps);
  AppLogger.d('[Dialogs Graph] rows=${stats.rows}, cols=${stats.cols}', tag: 'DialogsGraph');
  return builder.build(editor.steps);
});
