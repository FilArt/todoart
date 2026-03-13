import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/http_todo_repository.dart';
import 'package:app/main.dart';
import 'package:app/todo_item.dart';
import 'package:app/todo_repository.dart';

Future<void> _setSurfaceSize(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(800, 1200));
  addTearDown(() async {
    await tester.binding.setSurfaceSize(null);
  });
}

class FakeTodoRepository implements TodoRepository {
  FakeTodoRepository({List<TodoItem>? seedTodos, this.failOnList = false})
    : _todos = [...?seedTodos];

  final List<TodoItem> _todos;
  final bool failOnList;
  int _nextId = 100;

  @override
  Future<List<TodoItem>> listTodos() async {
    if (failOnList) {
      throw const TodoApiException('Backend is unavailable.');
    }

    return _copyTodos();
  }

  @override
  Future<TodoItem> createTodo(String title, {String description = ''}) async {
    final todo = TodoItem(
      id: _nextId++,
      title: title,
      description: description,
      done: false,
    );
    _todos.insert(0, todo);
    return todo;
  }

  @override
  Future<TodoItem> updateTodo(
    int id, {
    String? title,
    String? description,
    bool? done,
  }) async {
    final index = _todos.indexWhere((todo) => todo.id == id);
    final updated = _todos[index].copyWith(
      title: title,
      description: description,
      done: done,
    );
    _todos[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteTodo(int id) async {
    _todos.removeWhere((todo) => todo.id == id);
  }

  List<TodoItem> _copyTodos() {
    return _todos.map((todo) => todo.copyWith()).toList();
  }
}

void main() {
  testWidgets('loads todos from the repository and shows summary counts', (
    WidgetTester tester,
  ) async {
    await _setSurfaceSize(tester);

    final repository = FakeTodoRepository(
      seedTodos: const [
        TodoItem(
          id: 1,
          title: 'Sketch today\'s priorities',
          description: 'Pick the landing page layout before 10.',
          done: false,
        ),
        TodoItem(
          id: 2,
          title: 'Reply to Sam about the venue',
          description: 'Confirm the projector and the load-in window.',
          done: false,
        ),
        TodoItem(
          id: 3,
          title: 'Water the plants',
          description: 'Kitchen shelf and balcony pots.',
          done: true,
        ),
      ],
    );

    await tester.pumpWidget(MyApp(repository: repository));
    await tester.pumpAndSettle();

    expect(find.text('TodoArt'), findsOneWidget);
    expect(find.text('2 open'), findsOneWidget);
    expect(find.text('1 done'), findsOneWidget);
    expect(find.text('Sketch today\'s priorities'), findsOneWidget);
    expect(
      find.text('Pick the landing page layout before 10.'),
      findsOneWidget,
    );
    expect(find.text('Reply to Sam about the venue'), findsOneWidget);
    expect(
      find.text('Confirm the projector and the load-in window.'),
      findsOneWidget,
    );
    expect(find.text('Water the plants'), findsOneWidget);
  });

  testWidgets('can create and complete a todo through the repository flow', (
    WidgetTester tester,
  ) async {
    await _setSurfaceSize(tester);

    final repository = FakeTodoRepository(
      seedTodos: const [
        TodoItem(
          id: 1,
          title: 'Sketch today\'s priorities',
          description: 'Block the first hour for it.',
          done: false,
        ),
      ],
    );

    await tester.pumpWidget(MyApp(repository: repository));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('todo-input')), 'Buy oat milk');
    await tester.enterText(
      find.byKey(const Key('todo-description-input')),
      'Grab the barista blend.',
    );
    await tester.tap(find.byKey(const Key('add-todo-button')));
    await tester.pumpAndSettle();

    expect(find.text('Buy oat milk'), findsOneWidget);
    expect(find.text('Grab the barista blend.'), findsOneWidget);
    expect(find.text('2 open'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('todo-checkbox-100')));
    await tester.pump();

    expect(find.text('1 open'), findsOneWidget);
    expect(find.text('1 done'), findsOneWidget);
  });

  testWidgets('can edit a todo description through the repository flow', (
    WidgetTester tester,
  ) async {
    await _setSurfaceSize(tester);

    final repository = FakeTodoRepository(
      seedTodos: const [
        TodoItem(
          id: 1,
          title: 'Plan the workshop',
          description: 'Outline the first three exercises.',
          done: false,
        ),
      ],
    );

    await tester.pumpWidget(MyApp(repository: repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('todo-edit-1')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('todo-edit-description-input')),
      'Outline the first five exercises.',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Outline the first five exercises.'), findsOneWidget);
    expect(find.text('Outline the first three exercises.'), findsNothing);
  });

  testWidgets('shows a retry state when the initial load fails', (
    WidgetTester tester,
  ) async {
    await _setSurfaceSize(tester);

    await tester.pumpWidget(
      MyApp(repository: FakeTodoRepository(failOnList: true)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Could not load todos'), findsOneWidget);
    expect(find.byKey(const Key('retry-load-button')), findsOneWidget);
  });
}
