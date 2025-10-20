import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentralix_app/features/assistant/features/sessions/models/threads_filter.dart';

/// Провайдер состояния фильтра (диапазон дат + лимит)
final sessionsFilterProvider = NotifierProvider<SessionsFilterNotifier, ThreadsFilter>(
  SessionsFilterNotifier.new,
);

class SessionsFilterNotifier extends Notifier<ThreadsFilter> {
  @override
  ThreadsFilter build() {
    // Значения по умолчанию: без дат, лимит 10
    return const ThreadsFilter(limit: 10);
  }

  void setLimit(int limit) {
    state = state.copyWith(limit: limit);
  }

  void setDateRange({DateTime? from, DateTime? to}) {
    state = state.copyWith(createdFrom: from, createdTo: to);
  }

  void reset() {
    state = const ThreadsFilter(limit: 10);
  }
}
