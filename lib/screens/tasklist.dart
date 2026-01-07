// lib/screens/tasklist. dart
//
// TaskListScreen: Displays the user's prioritized task list as draggable cards.
// Users can reorder tasks by long-pressing and dragging, and remove tasks
// with a button on each card.  Uses ReorderableListView for smooth drag handling.

import 'package:flutter/material.dart';
import 'package:myapp/class_essentials/assignment.dart';
import 'package:myapp/class_essentials/taskmanager.dart';

class TaskListScreen extends StatefulWidget {
  final TaskManager taskManager;
  final Color accentColor;

  const TaskListScreen({
    super.key,
    required this.taskManager,
    this.accentColor = Colors.blue,
  });

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController. forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  /// Called when the user finishes dragging a task to a new position
  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      widget.taskManager.moveTask(oldIndex, newIndex);
    });
  }

  /// Removes a task from the list and shows a confirmation snackbar
  void _removeTask(int index) {
    final task = widget.taskManager.getTaskAt(index);
    if (task == null) return;

    setState(() {
      widget.taskManager.removeAt(index);
    });

    ScaffoldMessenger. of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Removed "${task.title}" from task list',
                style: const TextStyle(fontWeight: FontWeight. w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius. circular(12)),
        backgroundColor: Colors.grey. shade800,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme. of(context).brightness == Brightness.dark;
    final tasks = widget.taskManager.tasks;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              widget.accentColor. withValues(alpha: isDarkMode ? 0.08 : 0.05),
              Theme.of(context). scaffoldBackgroundColor,
            ],
            stops: const [0.0, 0.3],
          ),
        ),
        child: tasks.isEmpty
            ?  _buildEmptyState(isDarkMode)
            : _buildTaskList(tasks, isDarkMode),
      ),
    );
  }

  /// Builds the empty state when no tasks are in the list
  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: widget.accentColor. withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.playlist_add_rounded,
                size: 64,
                color: widget.accentColor. withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Tasks Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Theme.of(context). colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Add assignments from your courses to create\nyour prioritized task list',
              textAlign: TextAlign. center,
              style: TextStyle(
                fontSize: 15,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets. symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: widget. accentColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.accentColor. withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize. min,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 18,
                    color: widget.accentColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Tip: Long-press and drag to reorder',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight. w500,
                      color: widget.accentColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the reorderable task list
  Widget _buildTaskList(List<Assignment> tasks, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with task count
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets. all(10),
                decoration: BoxDecoration(
                  color: widget.accentColor. withValues(alpha: 0.15),
                  borderRadius: BorderRadius. circular(12),
                ),
                child: Icon(
                  Icons.format_list_numbered_rounded,
                  color: widget.accentColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${tasks.length} Task${tasks.length != 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight. w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    'Drag to reorder priorities',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Reorderable list of task cards
        Expanded(
          child: ReorderableListView. builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: tasks.length,
            onReorder: _onReorder,
            proxyDecorator: (child, index, animation) {
              // Adds elevation effect when dragging
              return AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  final elevation = Tween<double>(begin: 0, end: 8)
                      .animate(animation)
                      .value;
                  return Material(
                    elevation: elevation,
                    borderRadius: BorderRadius. circular(16),
                    color: Colors.transparent,
                    shadowColor: widget.accentColor. withValues(alpha: 0.3),
                    child: child,
                  );
                },
                child: child,
              );
            },
            itemBuilder: (context, index) {
              final task = tasks[index];
              return _TaskCard(
                key: ValueKey('${task.title}_${task. dueDate}_$index'),
                task: task,
                index: index,
                accentColor: widget. accentColor,
                isDarkMode: isDarkMode,
                onRemove: () => _removeTask(index),
              );
            },
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Task Card Widget - Compact card for the task list
// -----------------------------------------------------------------------------

class _TaskCard extends StatelessWidget {
  final Assignment task;
  final int index;
  final Color accentColor;
  final bool isDarkMode;
  final VoidCallback onRemove;

  const _TaskCard({
    super.key,
    required this. task,
    required this.index,
    required this.accentColor,
    required this.isDarkMode,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = isDarkMode
        ?  Color.alphaBlend(
      accentColor.withValues(alpha: 0.08),
      theme. colorScheme.surface,
    )
        : Color.alphaBlend(
      accentColor.withValues(alpha: 0.04),
      theme. colorScheme.surface,
    );

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Priority number badge
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accentColor.withValues(alpha: 0.8),
                      accentColor,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment. bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight. w800,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Task info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight. w600,
                        color: theme.colorScheme.onSurface,
                        decoration: task.completed
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow. ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // Type badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius. circular(4),
                          ),
                          child: Text(
                            task. type. toUpperCase(),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight. w700,
                              color: accentColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Due date
                        Icon(
                          Icons.schedule_rounded,
                          size: 12,
                          color: theme.colorScheme. onSurface
                              .withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          task.dueDate != null
                              ?  _formatDueDate(task. dueDate!)
                              : 'No due date',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Drag handle
              Container(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.drag_handle_rounded,
                  color: theme.colorScheme. onSurface. withValues(alpha: 0.3),
                  size: 22,
                ),
              ),

              // Remove button
              GestureDetector(
                onTap: onRemove,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red. withValues(alpha: 0.1),
                    borderRadius: BorderRadius. circular(8),
                  ),
                  child: Icon(
                    Icons.remove_circle_outline_rounded,
                    color: Colors.red.shade400,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Formats the due date for compact display
  String _formatDueDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(date.year, date.month, date.day);
    final difference = dueDay.difference(today). inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else if (difference == -1) {
      return 'Yesterday';
    } else if (difference < -1) {
      return '${-difference} days ago';
    } else if (difference < 7) {
      return 'In $difference days';
    } else {
      // Format as MM/DD
      return '${date.month}/${date.day}';
    }
  }
}