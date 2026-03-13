import 'dart:convert';

import 'package:http/http.dart' as http;

import 'todo_item.dart';
import 'todo_repository.dart';

class TodoApiException implements Exception {
  const TodoApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class HttpTodoRepository implements TodoRepository {
  HttpTodoRepository({required String baseUrl, http.Client? client})
    : _baseUri = Uri.parse(baseUrl),
      _client = client ?? http.Client();

  final Uri _baseUri;
  final http.Client _client;

  Uri _uri(String path) => _baseUri.resolve(path);

  @override
  Future<List<TodoItem>> listTodos() async {
    final response = await _client.get(_uri('/todos'));
    final payload = _decode(response);

    if (response.statusCode != 200) {
      throw TodoApiException('Failed to load todos.');
    }

    return (payload as List<dynamic>)
        .map((item) => TodoItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<TodoItem> createTodo(String title, {String description = ''}) async {
    final response = await _client.post(
      _uri('/todos'),
      headers: {'content-type': 'application/json'},
      body: jsonEncode({'title': title, 'description': description}),
    );
    final payload = _decode(response);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw TodoApiException('Failed to create the todo.');
    }

    return TodoItem.fromJson(payload as Map<String, dynamic>);
  }

  @override
  Future<TodoItem> updateTodo(
    int id, {
    String? title,
    String? description,
    bool? done,
  }) async {
    final body = <String, dynamic>{};
    if (title != null) {
      body['title'] = title;
    }
    if (description != null) {
      body['description'] = description;
    }
    if (done != null) {
      body['done'] = done;
    }

    final response = await _client.patch(
      _uri('/todos/$id'),
      headers: {'content-type': 'application/json'},
      body: jsonEncode(body),
    );
    final payload = _decode(response);

    if (response.statusCode != 200) {
      throw TodoApiException('Failed to update the todo.');
    }

    return TodoItem.fromJson(payload as Map<String, dynamic>);
  }

  @override
  Future<void> deleteTodo(int id) async {
    final response = await _client.delete(_uri('/todos/$id'));
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw TodoApiException('Failed to delete the todo.');
    }
  }

  dynamic _decode(http.Response response) {
    if (response.body.isEmpty) {
      return null;
    }

    return jsonDecode(response.body);
  }
}
