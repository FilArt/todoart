import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/app_release.dart';
import 'package:app/app_update_controller.dart';
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

class FakeAppUpdateController implements AppUpdateController {
  FakeAppUpdateController({
    List<UpdateCheckResult>? queuedResults,
    this.supportsSelfUpdate = true,
  }) : _queuedResults = [...?queuedResults];

  final List<UpdateCheckResult> _queuedResults;
  @override
  final bool supportsSelfUpdate;

  int checkCalls = 0;
  AppRelease? installedRelease;

  @override
  Future<UpdateCheckResult> checkForUpdates() async {
    checkCalls += 1;

    if (_queuedResults.isEmpty) {
      return const UpdateCheckResult(
        currentVersion: AppVersionInfo(version: '1.0.0', buildNumber: 1),
        latestRelease: null,
      );
    }

    if (_queuedResults.length == 1) {
      return _queuedResults.first;
    }

    return _queuedResults.removeAt(0);
  }

  @override
  Future<void> installUpdate(AppRelease release) async {
    installedRelease = release;
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
    final updateController = FakeAppUpdateController();

    await tester.pumpWidget(
      MyApp(repository: repository, updateController: updateController),
    );
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
    final updateController = FakeAppUpdateController();

    await tester.pumpWidget(
      MyApp(repository: repository, updateController: updateController),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('open-create-todo-button')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('todo-create-title-input')),
      'Buy oat milk',
    );
    await tester.enterText(
      find.byKey(const Key('todo-create-description-input')),
      'Grab the barista blend.',
    );
    await tester.tap(find.byKey(const Key('todo-create-submit-button')));
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
    final updateController = FakeAppUpdateController();

    await tester.pumpWidget(
      MyApp(repository: repository, updateController: updateController),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('todo-edit-1')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('todo-edit-description-input')),
      'Outline the first five exercises.',
    );
    await tester.tap(find.byKey(const Key('todo-edit-submit-button')));
    await tester.pumpAndSettle();

    expect(find.text('Outline the first five exercises.'), findsOneWidget);
    expect(find.text('Outline the first three exercises.'), findsNothing);
  });

  testWidgets('shows a retry state when the initial load fails', (
    WidgetTester tester,
  ) async {
    await _setSurfaceSize(tester);

    await tester.pumpWidget(
      MyApp(
        repository: FakeTodoRepository(failOnList: true),
        updateController: FakeAppUpdateController(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Could not load todos'), findsOneWidget);
    expect(find.byKey(const Key('retry-load-button')), findsOneWidget);
  });

  testWidgets(
    'keeps the empty-state starter action reachable on short screens',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

      await tester.pumpWidget(
        MyApp(
          repository: FakeTodoRepository(),
          updateController: FakeAppUpdateController(),
        ),
      );
      await tester.pumpAndSettle();

      final starterTaskButton = find.widgetWithText(
        OutlinedButton,
        'Add a starter task',
      );

      await tester.ensureVisible(starterTaskButton);

      expect(starterTaskButton, findsOneWidget);
      expect(tester.getRect(starterTaskButton).bottom, lessThanOrEqualTo(640));
    },
  );

  testWidgets('prompts for an update on startup and can start installation', (
    WidgetTester tester,
  ) async {
    await _setSurfaceSize(tester);

    final release = AppRelease(
      version: '1.1.0',
      buildNumber: 2,
      notes: 'Faster release downloads.',
      downloadUrl: Uri.parse('https://example.com/todoart-android-1.1.0-2.apk'),
      publishedAt: DateTime.utc(2026, 3, 14, 12),
    );
    final updateController = FakeAppUpdateController(
      queuedResults: [
        UpdateCheckResult(
          currentVersion: const AppVersionInfo(
            version: '1.0.0',
            buildNumber: 1,
          ),
          latestRelease: release,
        ),
      ],
    );

    await tester.pumpWidget(
      MyApp(
        repository: FakeTodoRepository(),
        updateController: updateController,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Update available'), findsOneWidget);
    expect(find.text('Latest version 1.1.0+2'), findsOneWidget);
    expect(find.text('Faster release downloads.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('install-update-button')));
    await tester.pumpAndSettle();

    expect(updateController.installedRelease?.version, '1.1.0');
  });

  testWidgets('check updates button can fetch and show a new release', (
    WidgetTester tester,
  ) async {
    await _setSurfaceSize(tester);

    final release = AppRelease(
      version: '1.2.0',
      buildNumber: 3,
      notes: 'Adds Android self-update support.',
      downloadUrl: Uri.parse('https://example.com/todoart-android-1.2.0-3.apk'),
      publishedAt: DateTime.utc(2026, 3, 14, 12),
    );
    final updateController = FakeAppUpdateController(
      queuedResults: [
        const UpdateCheckResult(
          currentVersion: AppVersionInfo(version: '1.0.0', buildNumber: 1),
          latestRelease: null,
        ),
        UpdateCheckResult(
          currentVersion: const AppVersionInfo(
            version: '1.0.0',
            buildNumber: 1,
          ),
          latestRelease: release,
        ),
      ],
    );

    await tester.pumpWidget(
      MyApp(
        repository: FakeTodoRepository(),
        updateController: updateController,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('check-updates-button')));
    await tester.pumpAndSettle();

    expect(updateController.checkCalls, 2);
    expect(find.text('Update available'), findsOneWidget);
    expect(find.text('Latest version 1.2.0+3'), findsOneWidget);
  });
}
