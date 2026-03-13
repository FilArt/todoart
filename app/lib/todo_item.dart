class TodoItem {
  const TodoItem({required this.id, required this.title, required this.done});

  final int id;
  final String title;
  final bool done;

  TodoItem copyWith({int? id, String? title, bool? done}) {
    return TodoItem(
      id: id ?? this.id,
      title: title ?? this.title,
      done: done ?? this.done,
    );
  }

  factory TodoItem.fromJson(Map<String, dynamic> json) {
    return TodoItem(
      id: json['id'] as int,
      title: json['title'] as String,
      done: json['done'] as bool,
    );
  }
}
