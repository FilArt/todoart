class TodoItem {
  const TodoItem({
    required this.id,
    required this.title,
    required this.description,
    required this.done,
  });

  final int id;
  final String title;
  final String description;
  final bool done;

  TodoItem copyWith({int? id, String? title, String? description, bool? done}) {
    return TodoItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      done: done ?? this.done,
    );
  }

  factory TodoItem.fromJson(Map<String, dynamic> json) {
    return TodoItem(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      done: json['done'] as bool,
    );
  }
}
