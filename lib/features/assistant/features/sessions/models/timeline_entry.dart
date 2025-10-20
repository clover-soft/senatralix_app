enum TimelineEntryType { assistantMessage, toolCallLog, assistantRun, threadSlots }

enum MessageRole { assistant, user, system }

class AssistantMessageEntry {
  final int id;
  final int threadId;
  final MessageRole role;
  final String content;
  final Map<String, dynamic>? payload;
  final int? tokens;
  final String status;
  final DateTime createdAt;
  AssistantMessageEntry({
    required this.id,
    required this.threadId,
    required this.role,
    required this.content,
    required this.payload,
    required this.tokens,
    required this.status,
    required this.createdAt,
  });
  factory AssistantMessageEntry.fromJson(Map<String, dynamic> json) {
    final rawRole = (json['role']?.toString() ?? '').toLowerCase();
    final role = rawRole.contains('assistant')
        ? MessageRole.assistant
        : rawRole.contains('system')
            ? MessageRole.system
            : MessageRole.user;
    return AssistantMessageEntry(
      id: json['id'] as int,
      threadId: json['thread_id'] as int,
      role: role,
      content: (json['content'] ?? '').toString(),
      payload: json['payload'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['payload'] as Map)
          : null,
      tokens: json['tokens'] is int ? json['tokens'] as int : null,
      status: (json['status'] ?? '').toString(),
      createdAt: DateTime.parse(json['created_at'].toString()),
    );
  }
}

class ToolCallLogEntry {
  final int id;
  final String toolName;
  final int assistantId;
  final int threadId;
  final String? domainId;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final int? durationMs;
  final String status;
  final dynamic input;
  final dynamic output;
  final dynamic error;
  ToolCallLogEntry({
    required this.id,
    required this.toolName,
    required this.assistantId,
    required this.threadId,
    required this.domainId,
    required this.startedAt,
    required this.finishedAt,
    required this.durationMs,
    required this.status,
    required this.input,
    required this.output,
    required this.error,
  });
  factory ToolCallLogEntry.fromJson(Map<String, dynamic> json) {
    return ToolCallLogEntry(
      id: json['id'] as int,
      toolName: (json['tool_name'] ?? '').toString(),
      assistantId: json['assistant_id'] as int,
      threadId: json['thread_id'] as int,
      domainId: json['domain_id']?.toString(),
      startedAt: DateTime.parse(json['started_at'].toString()),
      finishedAt:
          json['finished_at'] != null ? DateTime.parse(json['finished_at']) : null,
      durationMs: json['duration_ms'] is int ? json['duration_ms'] as int : null,
      status: (json['status'] ?? '').toString(),
      input: json['input'],
      output: json['output'],
      error: json['error'],
    );
  }
}

class AssistantRunEntry {
  final int id;
  final int threadId;
  final int assistantId;
  final String? externalId;
  final String status;
  final int? inputTokens;
  final int? outputTokens;
  final num? cost;
  final DateTime createdAt;
  final DateTime? completedAt;
  AssistantRunEntry({
    required this.id,
    required this.threadId,
    required this.assistantId,
    required this.externalId,
    required this.status,
    required this.inputTokens,
    required this.outputTokens,
    required this.cost,
    required this.createdAt,
    required this.completedAt,
  });
  factory AssistantRunEntry.fromJson(Map<String, dynamic> json) {
    return AssistantRunEntry(
      id: json['id'] as int,
      threadId: json['thread_id'] as int,
      assistantId: json['assistant_id'] as int,
      externalId: json['external_id']?.toString(),
      status: (json['status'] ?? '').toString(),
      inputTokens: json['input_tokens'] is int ? json['input_tokens'] as int : null,
      outputTokens:
          json['output_tokens'] is int ? json['output_tokens'] as int : null,
      cost: json['cost'] as num?,
      createdAt: DateTime.parse(json['created_at'].toString()),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'].toString())
          : null,
    );
  }
}

class ThreadSlotValue {
  final int id;
  final int threadId;
  final int slotId;
  final dynamic value;
  final bool isFilled;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic> metadata;
  final String contextName;
  ThreadSlotValue({
    required this.id,
    required this.threadId,
    required this.slotId,
    required this.value,
    required this.isFilled,
    required this.createdAt,
    required this.updatedAt,
    required this.metadata,
    required this.contextName,
  });
  factory ThreadSlotValue.fromJson(Map<String, dynamic> json) {
    return ThreadSlotValue(
      id: json['id'] as int,
      threadId: json['thread_id'] as int,
      slotId: json['slot_id'] is int ? json['slot_id'] as int : 0,
      value: json['value'],
      isFilled: json['is_filled'] == true,
      createdAt: DateTime.parse(json['created_at'].toString()),
      updatedAt:
          json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      metadata: json['metadata'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : <String, dynamic>{},
      contextName: (json['context_name'] ?? '').toString(),
    );
  }
}

class ThreadSlotsEntry {
  final List<ThreadSlotValue> values;
  final Map<String, dynamic> context;
  ThreadSlotsEntry({required this.values, required this.context});
  factory ThreadSlotsEntry.fromJson(Map<String, dynamic> json) {
    final values = (json['values'] as List<dynamic>? ?? const [])
        .map((e) => ThreadSlotValue.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    final ctx = json['context'] is Map
        ? Map<String, dynamic>.from(json['context'] as Map)
        : <String, dynamic>{};
    return ThreadSlotsEntry(values: values, context: ctx);
  }
}

class TimelineEntry {
  final TimelineEntryType type;
  final Object data;
  final DateTime sortTime;
  TimelineEntry({required this.type, required this.data, required this.sortTime});

  static List<TimelineEntry> fromTimelineJson(List<Map<String, dynamic>> raw) {
    final List<TimelineEntry> out = [];
    for (final item in raw) {
      if (item['AssistantMessage'] is Map) {
        final e = AssistantMessageEntry.fromJson(
            Map<String, dynamic>.from(item['AssistantMessage'] as Map));
        out.add(TimelineEntry(type: TimelineEntryType.assistantMessage, data: e, sortTime: e.createdAt));
      } else if (item['ToolCallLog'] is Map) {
        final e = ToolCallLogEntry.fromJson(
            Map<String, dynamic>.from(item['ToolCallLog'] as Map));
        out.add(TimelineEntry(type: TimelineEntryType.toolCallLog, data: e, sortTime: e.startedAt));
      } else if (item['AssistantRun'] is Map) {
        final e = AssistantRunEntry.fromJson(
            Map<String, dynamic>.from(item['AssistantRun'] as Map));
        out.add(TimelineEntry(type: TimelineEntryType.assistantRun, data: e, sortTime: e.createdAt));
      } else if (item['ThreadSlots'] is Map) {
        final e = ThreadSlotsEntry.fromJson(
            Map<String, dynamic>.from(item['ThreadSlots'] as Map));
        // Для сортировки возьмём максимально позднюю дату из values
        DateTime t = DateTime.fromMillisecondsSinceEpoch(0);
        for (final v in e.values) {
          if (v.createdAt.isAfter(t)) t = v.createdAt;
          if (v.updatedAt != null && v.updatedAt!.isAfter(t)) t = v.updatedAt!;
        }
        out.add(TimelineEntry(type: TimelineEntryType.threadSlots, data: e, sortTime: t));
      }
    }
    out.sort((a, b) => a.sortTime.compareTo(b.sortTime));
    return out;
  }
}
