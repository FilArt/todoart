import 'package:flutter/material.dart';

import 'api_config.dart';
import 'http_todo_repository.dart';
import 'todo_item.dart';
import 'todo_repository.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key, TodoRepository? repository})
    : repository =
          repository ?? HttpTodoRepository(baseUrl: resolveTodoApiBaseUrl());

  final TodoRepository repository;

  @override
  Widget build(BuildContext context) {
    const canvas = Color(0xFFF6F1E8);
    const panel = Color(0xFFFFFCF7);
    const accent = Color(0xFF0F766E);

    return MaterialApp(
      title: 'TodoArt',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: accent,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: canvas,
        textTheme: Typography.blackMountainView,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: panel,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: TodoHomePage(repository: repository),
    );
  }
}

class TodoHomePage extends StatefulWidget {
  const TodoHomePage({super.key, required this.repository});

  final TodoRepository repository;

  @override
  State<TodoHomePage> createState() => _TodoHomePageState();
}

class _TodoHomePageState extends State<TodoHomePage> {
  final TextEditingController _controller = TextEditingController();

  List<TodoItem> _todos = const [];
  bool _isLoading = true;
  bool _isCreating = false;
  String? _loadError;
  final Set<int> _busyIds = <int>{};

  int get _openCount => _todos.where((todo) => !todo.done).length;
  int get _doneCount => _todos.where((todo) => todo.done).length;

  @override
  void initState() {
    super.initState();
    _loadTodos();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadTodos() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final todos = await widget.repository.listTodos();
      if (!mounted) {
        return;
      }

      setState(() {
        _todos = todos;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _loadError = _friendlyError(error);
      });
    }
  }

  Future<void> _addTodo() async {
    final title = _controller.text.trim();
    if (title.isEmpty || _isCreating) {
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      final todo = await widget.repository.createTodo(title);
      if (!mounted) {
        return;
      }

      setState(() {
        _todos = [todo, ..._todos];
        _controller.clear();
        _isCreating = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isCreating = false;
      });
      _showError(_friendlyError(error));
    }
  }

  Future<void> _toggleTodo(TodoItem todo, bool? value) async {
    await _runForTodo(todo.id, () async {
      final updated = await widget.repository.updateTodo(
        todo.id,
        done: value ?? false,
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _todos = _replaceTodo(updated);
      });
    });
  }

  Future<void> _renameTodo(TodoItem todo) async {
    final controller = TextEditingController(text: todo.title);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit task'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (value) => Navigator.of(context).pop(value),
            decoration: const InputDecoration(hintText: 'Todo title'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    controller.dispose();

    final trimmedTitle = newTitle?.trim();
    if (trimmedTitle == null ||
        trimmedTitle.isEmpty ||
        trimmedTitle == todo.title) {
      return;
    }

    await _runForTodo(todo.id, () async {
      final updated = await widget.repository.updateTodo(
        todo.id,
        title: trimmedTitle,
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _todos = _replaceTodo(updated);
      });
    });
  }

  Future<void> _removeTodo(TodoItem todo) async {
    await _runForTodo(todo.id, () async {
      await widget.repository.deleteTodo(todo.id);
      if (!mounted) {
        return;
      }

      setState(() {
        _todos = _todos.where((item) => item.id != todo.id).toList();
      });
    });
  }

  Future<void> _clearCompleted() async {
    final completedTodos = _todos.where((todo) => todo.done).toList();
    if (completedTodos.isEmpty) {
      return;
    }

    for (final todo in completedTodos) {
      try {
        await widget.repository.deleteTodo(todo.id);
      } catch (error) {
        if (!mounted) {
          return;
        }

        _showError(_friendlyError(error));
        return;
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _todos = _todos.where((todo) => !todo.done).toList();
    });
  }

  Future<void> _runForTodo(int todoId, Future<void> Function() action) async {
    setState(() {
      _busyIds.add(todoId);
    });

    try {
      await action();
    } catch (error) {
      if (mounted) {
        _showError(_friendlyError(error));
      }
    } finally {
      if (!mounted) {
        return;
      }

      setState(() {
        _busyIds.remove(todoId);
      });
    }
  }

  List<TodoItem> _replaceTodo(TodoItem updatedTodo) {
    return _todos
        .map((todo) => todo.id == updatedTodo.id ? updatedTodo : todo)
        .toList();
  }

  String _friendlyError(Object error) {
    if (error is TodoApiException) {
      return error.message;
    }
    return 'Something went wrong while talking to the API.';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    const panel = Color(0xFFFFFCF7);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: panel,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'TodoArt',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: scheme.onSurface,
                              ),
                            ),
                          ),
                          IconButton(
                            key: const Key('refresh-todos-button'),
                            onPressed: _isLoading ? null : _loadTodos,
                            tooltip: 'Refresh tasks',
                            icon: const Icon(Icons.sync_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Live list from FastAPI. Add, edit, complete, and delete tasks from one place.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _StatChip(
                            label: '$_openCount open',
                            backgroundColor: scheme.primaryContainer,
                            foregroundColor: scheme.onPrimaryContainer,
                          ),
                          _StatChip(
                            label: '$_doneCount done',
                            backgroundColor: scheme.secondaryContainer,
                            foregroundColor: scheme.onSecondaryContainer,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('todo-input'),
                      controller: _controller,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _addTodo(),
                      enabled: !_isCreating,
                      decoration: const InputDecoration(
                        hintText: 'Add a task',
                        prefixIcon: Icon(Icons.edit_note_rounded),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    key: const Key('add-todo-button'),
                    onPressed: _isCreating ? null : _addTodo,
                    icon: _isCreating
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add_task_rounded),
                    label: const Text('Add'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 18,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Expanded(child: _buildBody(theme)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading && _todos.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(key: Key('initial-loading')),
      );
    }

    if (_loadError != null && _todos.isEmpty) {
      return _ErrorState(message: _loadError!, onRetry: _loadTodos);
    }

    if (_todos.isEmpty) {
      return _EmptyState(
        onAddDemoTask: () async {
          _controller.text = 'Pick up a sketchbook';
          await _addTodo();
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'Today\'s list',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            if (_doneCount > 0)
              TextButton(
                onPressed: _busyIds.isNotEmpty ? null : _clearCompleted,
                child: const Text('Clear completed'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.separated(
            itemCount: _todos.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final todo = _todos[index];
              return _TodoCard(
                todo: todo,
                busy: _busyIds.contains(todo.id),
                onChanged: (value) => _toggleTodo(todo, value),
                onEdit: () => _renameTodo(todo),
                onDelete: () => _removeTodo(todo),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: foregroundColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _TodoCard extends StatelessWidget {
  const _TodoCard({
    required this.todo,
    required this.busy,
    required this.onChanged,
    required this.onEdit,
    required this.onDelete,
  });

  final TodoItem todo;
  final bool busy;
  final ValueChanged<bool?> onChanged;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
      decoration: todo.done ? TextDecoration.lineThrough : null,
      color: todo.done ? scheme.onSurfaceVariant : scheme.onSurface,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: todo.done ? scheme.secondaryContainer : Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Checkbox(
              key: ValueKey('todo-checkbox-${todo.id}'),
              value: todo.done,
              onChanged: busy ? null : onChanged,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(todo.title, style: titleStyle),
                  const SizedBox(height: 4),
                  Text(
                    todo.done ? 'Done' : 'Up next',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              key: ValueKey('todo-edit-${todo.id}'),
              onPressed: busy ? null : onEdit,
              tooltip: 'Edit task',
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              key: ValueKey('todo-delete-${todo.id}'),
              onPressed: busy ? null : onDelete,
              tooltip: 'Delete task',
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAddDemoTask});

  final Future<void> Function() onAddDemoTask;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                size: 48,
                color: scheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Nothing left on the page.',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Add one small task and it will be created in the backend.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: onAddDemoTask,
                icon: const Icon(Icons.auto_fix_high_rounded),
                label: const Text('Add a starter task'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_rounded, size: 48, color: scheme.error),
              const SizedBox(height: 16),
              Text(
                'Could not load todos',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton(
                key: const Key('retry-load-button'),
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
