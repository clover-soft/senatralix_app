// Модель ассистента
class Assistant {
  final String id;
  final String name;
  const Assistant({required this.id, required this.name});

  Assistant copyWith({String? id, String? name}) =>
      Assistant(id: id ?? this.id, name: name ?? this.name);
}
