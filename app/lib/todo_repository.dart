import 'todo_item.dart';

abstract class TodoRepository {
  Future<List<TodoItem>> listTodos();

  Future<TodoItem> createTodo(String title, {String description = ''});

  Future<TodoItem> updateTodo(
    int id, {
    String? title,
    String? description,
    bool? done,
  });

  Future<void> deleteTodo(int id);
}
