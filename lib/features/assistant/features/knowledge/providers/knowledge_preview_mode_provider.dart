import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Хранит состояние переключателя предпросмотра Markdown
final knowledgePreviewModeProvider = StateProvider.autoDispose
    .family<bool, int?>((ref, knowledgeId) => true);
