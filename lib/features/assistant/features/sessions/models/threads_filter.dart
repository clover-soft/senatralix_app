// Модель состояния фильтра для списка тредов

class ThreadsFilter {
  final DateTime? createdFrom;
  final DateTime? createdTo;
  final int limit;

  const ThreadsFilter({
    this.createdFrom,
    this.createdTo,
    this.limit = 10,
  });

  ThreadsFilter copyWith({
    DateTime? createdFrom,
    DateTime? createdTo,
    int? limit,
  }) {
    return ThreadsFilter(
      createdFrom: createdFrom ?? this.createdFrom,
      createdTo: createdTo ?? this.createdTo,
      limit: limit ?? this.limit,
    );
  }

  /// Человекочитаемая строка диапазона дат
  String get dateRangeLabel {
    if (createdFrom == null && createdTo == null) return 'Все даты';
    final from = createdFrom != null
        ? _fmt(createdFrom!)
        : '…';
    final to = createdTo != null ? _fmt(createdTo!) : '…';
    return '$from — $to';
  }

  String _fmt(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}.$mm.$dd';
  }
}
