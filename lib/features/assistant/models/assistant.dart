// Модель ассистента
class Assistant {
  final String id;
  final String name;
  final String? description;
  const Assistant({required this.id, required this.name, this.description});

  Assistant copyWith({String? id, String? name, String? description}) =>
      Assistant(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
      );
}
