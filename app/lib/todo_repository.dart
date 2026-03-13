import 'todo_item.dart';

abstract class TodoRepository {
  Future<List<TodoItem>> listTodos();

  Future<TodoItem> createTodo(String title);

  Future<TodoItem> updateTodo(int id, {String? title, bool? done});

  Future<void> deleteTodo(int id);
}
