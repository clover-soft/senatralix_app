import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Набор раскрытых шагов по scriptId (для инлайн-редактирования)
final expandedStepsProvider = StateNotifierProvider.autoDispose
    .family<ExpandedStepsController, Set<String>, String>((ref, scriptId) {
      return ExpandedStepsController();
    });

class ExpandedStepsController extends StateNotifier<Set<String>> {
  ExpandedStepsController() : super(<String>{});

  void toggle(String stepId) {
    final s = {...state};
    if (s.contains(stepId)) {
      s.remove(stepId);
    } else {
      s.add(stepId);
    }
    state = s;
  }

  bool isOpen(String stepId) => state.contains(stepId);
}
