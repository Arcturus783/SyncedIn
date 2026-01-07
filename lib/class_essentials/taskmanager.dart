// lib/task_manager. dart
//
// TaskManager: Manages a user-ordered list of assignments (tasks) that the user
// wants to complete.  This list is independent of the main assignment data and
// maintains its own custom order.  Persists to Hive for data retention.

import 'package:myapp/class_essentials/assignment.dart';
import 'package:myapp/class_essentials/hive.dart';

class TaskManager {
  final HiveBoxManager _hiveManager;
  List<Assignment> _tasks = [];

  // Hive storage key for the task list
  static const String _storageKey = 'taskList';

  TaskManager(this._hiveManager) {
    _loadTasks();
  }

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  /// Returns an unmodifiable view of the task list (preserves user's custom order)
  List<Assignment> get tasks => List.unmodifiable(_tasks);

  /// Returns the number of tasks in the list
  int get length => _tasks.length;

  /// Returns true if the task list is empty
  bool get isEmpty => _tasks. isEmpty;

  // ---------------------------------------------------------------------------
  // Core Operations
  // ---------------------------------------------------------------------------

  /// Adds an assignment to the end of the task list.
  /// Returns true if added successfully, false if it's a duplicate.
  bool addTask(Assignment assignment) {
    if (contains(assignment)) {
      return false; // Duplicate - don't add
    }

    _tasks.add(assignment);
    _saveTasks();
    return true;
  }

  /// Removes the task at the specified index.
  /// Returns the removed assignment, or null if index is invalid.
  Assignment?  removeAt(int index) {
    if (index < 0 || index >= _tasks. length) {
      return null;
    }

    final removed = _tasks.removeAt(index);
    _saveTasks();
    return removed;
  }

  /// Removes a specific assignment from the task list.
  /// Returns true if the assignment was found and removed.
  bool removeTask(Assignment assignment) {
    final index = _indexOfTask(assignment);
    if (index == -1) {
      return false;
    }

    _tasks.removeAt(index);
    _saveTasks();
    return true;
  }

  /// Moves a task from oldIndex to newIndex.
  /// This is called by ReorderableListView's onReorder callback.
  ///
  /// Note: ReorderableListView provides newIndex as the position in the list
  /// BEFORE the item is removed.  We need to adjust for this behavior.
  void moveTask(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _tasks. length) return;
    if (newIndex < 0 || newIndex > _tasks.length) return;

    // ReorderableListView quirk: if moving down, newIndex is offset by 1
    // because it represents the index in the list including the item being moved
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    final task = _tasks.removeAt(oldIndex);
    _tasks. insert(newIndex, task);
    _saveTasks();
  }

  /// Clears all tasks from the list.
  void clearAll() {
    _tasks.clear();
    _saveTasks();
  }

  // ---------------------------------------------------------------------------
  // Query Operations
  // ---------------------------------------------------------------------------

  /// Checks if an assignment is already in the task list.
  /// Compares by title and dueDate since Assignment instances may differ.
  bool contains(Assignment assignment) {
    return _indexOfTask(assignment) != -1;
  }

  /// Gets the task at the specified index, or null if invalid.
  Assignment?  getTaskAt(int index) {
    if (index < 0 || index >= _tasks.length) {
      return null;
    }
    return _tasks[index];
  }

  // ---------------------------------------------------------------------------
  // Private Helpers
  // ---------------------------------------------------------------------------

  /// Finds the index of an assignment in the task list.
  /// Returns -1 if not found.
  int _indexOfTask(Assignment assignment) {
    for (int i = 0; i < _tasks.length; i++) {
      if (_isSameAssignment(_tasks[i], assignment)) {
        return i;
      }
    }
    return -1;
  }

  /// Compares two assignments to determine if they represent the same task.
  /// Uses title and dueDate as the unique identifier.
  bool _isSameAssignment(Assignment a, Assignment b) {
    // Compare titles
    if (a.title != b.title) return false;

    // Compare due dates (both null, or both equal)
    if (a.dueDate == null && b.dueDate == null) return true;
    if (a.dueDate == null || b.dueDate == null) return false;

    return a.dueDate! .isAtSameMomentAs(b. dueDate! );
  }

  // ---------------------------------------------------------------------------
  // Persistence (Hive)
  // ---------------------------------------------------------------------------

  /// Loads the task list from Hive storage.
  void _loadTasks() {
    try {
      final dynamic stored = _hiveManager.box. get(_storageKey);

      if (stored != null && stored is List) {
        _tasks = stored
            .whereType<Assignment>()
            .toList();
        print('TaskManager: Loaded ${_tasks.length} tasks from storage');
      } else {
        _tasks = [];
        print('TaskManager: No existing tasks found, starting fresh');
      }
    } catch (e) {
      print('TaskManager: Error loading tasks: $e');
      _tasks = [];
    }
  }

  /// Saves the current task list to Hive storage.
  void _saveTasks() {
    try {
      _hiveManager.box. put(_storageKey, _tasks);
      print('TaskManager: Saved ${_tasks.length} tasks to storage');
    } catch (e) {
      print('TaskManager: Error saving tasks: $e');
    }
  }

  /// Force reload tasks from storage (useful after external changes)
  void reload() {
    _loadTasks();
  }
}