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

  Future<void> _createTodo({_TodoDraft? initialDraft}) async {
    if (_isCreating) {
      return;
    }

    final draft = await _showTodoDraftDialog(
      dialogTitle: 'Add task',
      submitLabel: 'Add',
      submitKey: const Key('todo-create-submit-button'),
      titleFieldKey: const Key('todo-create-title-input'),
      descriptionFieldKey: const Key('todo-create-description-input'),
      initialDraft: initialDraft,
    );
    final title = draft?.title.trim();
    final description = draft?.description.trim() ?? '';
    if (title == null || title.isEmpty) {
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      final todo = await widget.repository.createTodo(
        title,
        description: description,
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _todos = [todo, ..._todos];
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

  Future<void> _editTodo(TodoItem todo) async {
    final updatedDraft = await _showTodoDraftDialog(
      dialogTitle: 'Edit task',
      submitLabel: 'Save',
      submitKey: const Key('todo-edit-submit-button'),
      titleFieldKey: const Key('todo-edit-title-input'),
      descriptionFieldKey: const Key('todo-edit-description-input'),
      initialDraft: _TodoDraft(
        title: todo.title,
        description: todo.description,
      ),
    );

    final trimmedTitle = updatedDraft?.title.trim();
    final trimmedDescription = updatedDraft?.description.trim() ?? '';
    if (trimmedTitle == null || trimmedTitle.isEmpty) {
      return;
    }

    if (trimmedTitle == todo.title && trimmedDescription == todo.description) {
      return;
    }

    await _runForTodo(todo.id, () async {
      final updated = await widget.repository.updateTodo(
        todo.id,
        title: trimmedTitle,
        description: trimmedDescription,
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _todos = _replaceTodo(updated);
      });
    });
  }

  Future<_TodoDraft?> _showTodoDraftDialog({
    required String dialogTitle,
    required String submitLabel,
    required Key submitKey,
    required Key titleFieldKey,
    required Key descriptionFieldKey,
    _TodoDraft? initialDraft,
  }) {
    return showDialog<_TodoDraft>(
      context: context,
      builder: (context) {
        return _TodoDraftDialog(
          dialogTitle: dialogTitle,
          submitLabel: submitLabel,
          submitKey: submitKey,
          titleFieldKey: titleFieldKey,
          descriptionFieldKey: descriptionFieldKey,
          initialDraft: initialDraft,
        );
      },
    );
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
                          FilledButton.icon(
                            key: const Key('open-create-todo-button'),
                            onPressed: _isCreating ? null : _createTodo,
                            icon: _isCreating
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.add_task_rounded),
                            label: const Text('New task'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
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
        busy: _isCreating,
        onAddDemoTask: () => _createTodo(
          initialDraft: const _TodoDraft(
            title: 'Pick up a sketchbook',
            description: 'Take ten minutes after lunch.',
          ),
        ),
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
                onEdit: () => _editTodo(todo),
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
    final descriptionStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: scheme.onSurfaceVariant,
      height: 1.35,
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
                  if (todo.description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      todo.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: descriptionStyle,
                    ),
                  ],
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
  const _EmptyState({required this.onAddDemoTask, required this.busy});

  final Future<void> Function() onAddDemoTask;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bottomInset = MediaQuery.paddingOf(context).bottom;

        return SingleChildScrollView(
          padding: EdgeInsets.only(bottom: bottomInset + 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
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
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
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
                        onPressed: busy ? null : onAddDemoTask,
                        icon: const Icon(Icons.auto_fix_high_rounded),
                        label: const Text('Add a starter task'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
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

class _TodoDraftDialog extends StatefulWidget {
  const _TodoDraftDialog({
    required this.dialogTitle,
    required this.submitLabel,
    required this.submitKey,
    required this.titleFieldKey,
    required this.descriptionFieldKey,
    this.initialDraft,
  });

  final String dialogTitle;
  final String submitLabel;
  final Key submitKey;
  final Key titleFieldKey;
  final Key descriptionFieldKey;
  final _TodoDraft? initialDraft;

  @override
  State<_TodoDraftDialog> createState() => _TodoDraftDialogState();
}

class _TodoDraftDialogState extends State<_TodoDraftDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.initialDraft?.title ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.initialDraft?.description ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.dialogTitle),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: widget.titleFieldKey,
            controller: _titleController,
            autofocus: true,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(hintText: 'Todo title'),
          ),
          const SizedBox(height: 12),
          TextField(
            key: widget.descriptionFieldKey,
            controller: _descriptionController,
            minLines: 3,
            maxLines: 5,
            textInputAction: TextInputAction.newline,
            decoration: const InputDecoration(hintText: 'Description'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: widget.submitKey,
          onPressed: () {
            Navigator.of(context).pop(
              _TodoDraft(
                title: _titleController.text,
                description: _descriptionController.text,
              ),
            );
          },
          child: Text(widget.submitLabel),
        ),
      ],
    );
  }
}

class _TodoDraft {
  const _TodoDraft({required this.title, required this.description});

  final String title;
  final String description;
}
