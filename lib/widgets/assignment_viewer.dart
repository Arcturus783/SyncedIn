import 'package:flutter/material.dart';
import 'package:myapp/class_essentials/assignment.dart';
import 'package:myapp/class_essentials/assignment_manager.dart';
import 'package:myapp/class_essentials/taskmanager.dart';
import 'package:myapp/home.dart';

enum SortOption {
  dueDate('Due Date'),
  alphabetical('Alphabetical');

  const SortOption(this.label);
  final String label;
}

class AssignmentViewer extends StatefulWidget {
  final String courseName;
  final Color courseColor;
  final AssignmentManager am;
  final bool timeBased;
  final bool autoHide;
  final TaskManager?  taskManager; // NEW: Optional task manager for adding tasks

  const AssignmentViewer({
    super.key,
    required this.courseName,
    required this.courseColor,
    required this.am,
    required this.timeBased,
    required this. autoHide,
    this.taskManager,
  });

  @override
  State<AssignmentViewer> createState() => _AssignmentViewerState();
}

class _AssignmentViewerState extends State<AssignmentViewer> with TickerProviderStateMixin {
  SortOption _currentSortOption = SortOption.dueDate;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  List<Assignment> filteredAssignments = [];
  List<Assignment> disAssignments = [];
  bool displayVisible = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController. forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    String noneText = "";
    List<Assignment> assignments;

    if (widget. timeBased) {
      switch (widget.courseName) {
        case 'Today':
          noneText = "You have no assignments due today! ";
          assignments = widget.am.getAssignmentsDueToday();
          break;
        case 'Tomorrow':
          noneText = "You have no assignments due tomorrow!";
          assignments = widget.am. getAssignmentsDueTomorrow();
          break;
        case 'This Week':
          noneText = "You have no assignments due later this week!";
          assignments = widget. am.getAssignmentsDueLaterThisWeek();
          break;
        case 'Overdue':
          noneText = "You have no overdue assignments!";
          assignments = widget. am.getOverdueAssignments();
          break;
        case 'No Date/Other':
          noneText = "You have no assignments without a due date!";
          assignments = widget.am.getOtherAssignments();
          break;
        default:
          assignments = [];
          print("Error: Unknown time-based folder ${widget.courseName}");
      }
    } else {
      noneText = "You have no assignments for this course!";
      assignments = widget.am.getAssignmentsForCourse(widget.courseName);
    }

    print("Assignments for ${widget.courseName}: ${assignments.length}");

    if (widget.autoHide) {
      for (Assignment assignment in assignments) {
        if (assignment.completed) {
          assignment.visible = false;
        }
      }
    }

    filteredAssignments = assignments. where((item) => item.visible).toList();
    disAssignments = assignments.where((item) => !item.visible).toList();

    if (_currentSortOption == SortOption. dueDate) {
      sortByDueDate(filteredAssignments);
    } else {
      sortByName(filteredAssignments);
    }

    final appBarTextColor = _getTextColorForBackground(widget.courseColor);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120.0,
            floating: false,
            pinned: true,
            backgroundColor: widget.courseColor,
            foregroundColor: appBarTextColor,
            elevation: 0,
            iconTheme: IconThemeData(color: appBarTextColor),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.courseName,
                textAlign: TextAlign. center,
                style: TextStyle(
                  color: appBarTextColor,
                  fontWeight: FontWeight. w700,
                  fontSize: 20,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment. bottomRight,
                    colors: [
                      widget.courseColor,
                      widget.courseColor.withValues(alpha: 0.8),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -30,
                      top: -30,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: appBarTextColor.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                    Positioned(
                      left: -50,
                      bottom: -50,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: appBarTextColor.withValues(alpha: 0.05),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    widget.courseColor. withValues(alpha: isDarkMode ? 0.05 : 0.08),
                    Theme.of(context). scaffoldBackgroundColor,
                  ],
                  stops: const [0.0, 0.3],
                ),
              ),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      // Assignment count header
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              widget.courseColor. withValues(alpha: isDarkMode ? 0.15 : 0.1),
                              widget.courseColor.withValues(alpha: isDarkMode ? 0.08 : 0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20.0),
                          border: Border.all(
                            color: widget.courseColor.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10.0),
                              decoration: BoxDecoration(
                                color: widget.courseColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius. circular(12.0),
                              ),
                              child: Icon(
                                filteredAssignments. isEmpty ?  Icons.check_circle_outline : Icons.assignment_outlined,
                                color: widget. courseColor,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    filteredAssignments. isEmpty ? 'All Clear!' : '${filteredAssignments.length} Assignment${filteredAssignments.length != 1 ? 's' : ''}',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Theme.of(context). colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  displayVisible = ! displayVisible;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(10.0),
                                child: Icon(
                                  displayVisible ?  Icons.visibility : Icons.visibility_off,
                                  color: widget.courseColor,
                                  size: 24,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Sort dropdown
                      if (filteredAssignments. isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(bottom: 24.0),
                          padding: const EdgeInsets.all(4.0),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                widget.courseColor. withValues(alpha: isDarkMode ? 0.12 : 0.08),
                                widget.courseColor. withValues(alpha: isDarkMode ? 0.06 : 0.04),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16.0),
                            border: Border. all(
                              color: widget.courseColor.withValues(alpha: 0.25),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: widget. courseColor.withValues(alpha: 0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                            decoration: BoxDecoration(
                              color: Theme.of(context). colorScheme.surface. withValues(alpha: 0.8),
                              borderRadius: BorderRadius. circular(12.0),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize. min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8.0),
                                  decoration: BoxDecoration(
                                    color: widget.courseColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  child: Icon(
                                    Icons.tune_rounded,
                                    size: 20,
                                    color: widget.courseColor,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Sort by:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme. onSurface,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<SortOption>(
                                      value: _currentSortOption,
                                      onChanged: (SortOption? newValue) {
                                        if (newValue != null) {
                                          setState(() {
                                            _currentSortOption = newValue;
                                          });
                                        }
                                      },
                                      items: SortOption. values.map<DropdownMenuItem<SortOption>>((SortOption value) {
                                        return DropdownMenuItem<SortOption>(
                                          value: value,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                                            child: Text(
                                              value.label,
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: Theme.of(context).colorScheme.onSurface,
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                      icon: Container(
                                        padding: const EdgeInsets.all(4.0),
                                        decoration: BoxDecoration(
                                          color: widget.courseColor.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(6.0),
                                        ),
                                        child: Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          size: 20,
                                          color: widget.courseColor,
                                        ),
                                      ),
                                      dropdownColor: Theme.of(context). colorScheme.surface,
                                      borderRadius: BorderRadius. circular(12.0),
                                      elevation: 8,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Assignment grid
                      AssignmentGrid(
                        assignments: displayVisible ? disAssignments : filteredAssignments,
                        courseColor: widget.courseColor,
                        autoHide: widget. autoHide,
                        isTablet: isTablet,
                        noneText: displayVisible ? "No hidden assignments!" : noneText,
                        onAssignmentChanged: () {
                          setState(() {
                            List<Assignment> refreshedAssignments;
                            if (widget.timeBased) {
                              switch (widget.courseName) {
                                case 'Today':
                                  refreshedAssignments = widget.am.getAssignmentsDueToday();
                                  break;
                                case 'Tomorrow':
                                  refreshedAssignments = widget.am.getAssignmentsDueTomorrow();
                                  break;
                                case 'This Week':
                                  refreshedAssignments = widget.am.getAssignmentsDueLaterThisWeek();
                                  break;
                                case 'Overdue':
                                  refreshedAssignments = widget. am.getOverdueAssignments();
                                  break;
                                case 'No Date/Other':
                                  refreshedAssignments = widget.am.getOtherAssignments();
                                  break;
                                default:
                                  refreshedAssignments = [];
                              }
                            } else {
                              refreshedAssignments = widget.am. getAssignmentsForCourse(widget.courseName);
                            }
                            filteredAssignments = refreshedAssignments.where((item) => item.visible). toList();
                            disAssignments = refreshedAssignments.where((item) => !item.visible).toList();

                            if (_currentSortOption == SortOption.dueDate) {
                              sortByDueDate(filteredAssignments);
                              sortByDueDate(disAssignments);
                            } else {
                              sortByName(filteredAssignments);
                              sortByName(disAssignments);
                            }
                          });
                        },
                        allowDismiss: ! displayVisible,
                        dismissActionText: displayVisible ? 'Show Assignment' : 'Hide Assignment',
                        dismissIcon: displayVisible ? Icons.visibility : Icons. visibility_off_rounded,
                        currentSortOption: _currentSortOption,
                        taskManager: widget.taskManager, // NEW: Pass task manager to grid
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void saveAssignments() {
    Map<dynamic, dynamic> rawAssignments = hiveManager.box. get("assignments") ??  {};
    Map<String, List<Assignment>> assignments = {};
    rawAssignments.forEach((key, value) {
      if (key is String && value is List) {
        assignments[key] = value.cast<Assignment>();
      }
    });
    hiveManager.box. put("assignments", assignments);
  }

  Color _getTextColorForBackground(Color background) {
    final brightness = (0.587 * background.r + 0.299 * background.g + 0.114 * background.b) / 255;
    return brightness > 0.5 ? Colors.black87 : Colors.white;
  }

  void sortByName(List<Assignment> as) {
    as.sort((a, b) {
      if (a.completed && !b.completed) return 1;
      if (!a.completed && b.completed) return -1;
      return a.title.compareTo(b.title);
    });
  }

  void sortByDueDate(List<Assignment> as) {
    as.sort((a, b) {
      if (a. completed && !b.completed) return 1;
      if (!a.completed && b. completed) return -1;
      if (a. dueDate == null && b. dueDate == null) return 0;
      if (a. dueDate == null) return 1;
      if (b.dueDate == null) return -1;
      int dateComparison = a.dueDate! .compareTo(b.dueDate! );
      if (dateComparison == 0) {
        return a.title.compareTo(b.title);
      }
      return dateComparison;
    });
  }
}

// =============================================================================
// AssignmentCard - Individual assignment card with "Add to Task List" button
// =============================================================================

class AssignmentCard extends StatefulWidget {
  final Assignment assignment;
  final Color courseColor;
  final int index;
  final bool autoHide;
  final VoidCallback? onAssignmentChanged;
  final TaskManager? taskManager; // NEW: Task manager for adding to task list

  const AssignmentCard({
    super.key,
    required this.assignment,
    required this.courseColor,
    required this.index,
    required this.autoHide,
    this.onAssignmentChanged,
    this.taskManager,
  });

  @override
  State<AssignmentCard> createState() => _AssignmentCardState();
}

class _AssignmentCardState extends State<AssignmentCard> with TickerProviderStateMixin {
  late AnimationController _hoverController;
  AnimationController? _checkboxController;
  late Animation<double> _scaleAnimation;
  Animation<double>? _checkboxAnimation;
  bool _isHovered = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super. initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _checkboxController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut),
    );
    _checkboxAnimation = Tween<double>(begin: 0.0, end: 1.0). animate(
      CurvedAnimation(parent: _checkboxController!, curve: Curves. elasticOut),
    );

    if (widget.assignment.completed) {
      _checkboxController! .value = 1.0;
    }
    _isInitialized = true;
  }

  @override
  void dispose() {
    _hoverController.dispose();
    _checkboxController?.dispose();
    super.dispose();
  }

  void _handleCheckboxTap() {
    if (! _isInitialized || _checkboxController == null) return;

    setState(() {
      widget.assignment.completed = !widget.assignment. completed;

      if (widget. assignment.completed) {
        _checkboxController!. forward();
        if (widget.autoHide) {
          widget.assignment.visible = false;
        }
      } else {
        _checkboxController! .reverse();
        widget.assignment.visible = true;
      }

      saveAssignments();
    });

    widget.onAssignmentChanged?.call();
  }

  /// NEW: Handle adding assignment to task list
  void _handleAddToTaskList() {
    if (widget. taskManager == null) return;

    final added = widget.taskManager!.addTask(widget.assignment);

    // Show appropriate snackbar
    ScaffoldMessenger. of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              added ? Icons.playlist_add_check : Icons.info_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                added
                    ? 'Added "${widget.assignment.title}" to task list'
                    : 'Already in task list',
                style: const TextStyle(fontWeight: FontWeight. w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius. circular(12)),
        backgroundColor: added ? Colors.green. shade700 : Colors.orange.shade700,
        duration: const Duration(seconds: 2),
      ),
    );

    // Refresh UI to update button state
    setState(() {});
  }

  void saveAssignments() {
    Map<dynamic, dynamic> rawAssignments = hiveManager.box.get("assignments") ?? {};
    Map<String, List<Assignment>> assignments = {};
    rawAssignments. forEach((key, value) {
      if (key is String && value is List) {
        assignments[key] = value.cast<Assignment>();
      }
    });
    hiveManager. box.put("assignments", assignments);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme. of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    final cardColor = isDarkMode
        ? Color. alphaBlend(
      widget.courseColor.withValues(alpha: 0.12),
      theme. colorScheme.surface,
    )
        : Color.alphaBlend(
      widget. courseColor.withValues(alpha: 0.06),
      theme. colorScheme.surface,
    );

    final primaryTextColor = theme.colorScheme. onSurface;
    final secondaryTextColor = theme. colorScheme.onSurface.withValues(alpha: 0.7);
    final iconContainerColor = isDarkMode
        ? widget.courseColor.withValues(alpha: 0.25)
        : widget.courseColor.withValues(alpha: 0.15);
    final iconColor = isDarkMode
        ? widget.courseColor.withValues(alpha: 0.9)
        : widget.courseColor;

    // NEW: Check if assignment is already in task list
    final isInTaskList = widget.taskManager?. contains(widget.assignment) ?? false;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius. circular(20.0),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cardColor,
              cardColor. withValues(alpha: 0.8),
            ],
          ),
          border: Border.all(
            color: widget.courseColor.withValues(alpha: _isHovered ? 0.4 : 0.2),
            width: _isHovered ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.courseColor.withValues(alpha: _isHovered ? 0.2 : 0.08),
              blurRadius: _isHovered ? 20 : 12,
              offset: Offset(0, _isHovered ? 8 : 4),
              spreadRadius: _isHovered ? 2 : 0,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Card content
            Positioned. fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius. circular(20.0),
                  onTapDown: (_) {
                    _hoverController.forward();
                    setState(() {
                      _isHovered = true;
                    });
                  },
                  onTapUp: (_) {
                    _hoverController.reverse();
                    setState(() {
                      _isHovered = false;
                    });
                  },
                  onTapCancel: () {
                    _hoverController.reverse();
                    setState(() {
                      _isHovered = false;
                    });
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20.0),
                    child: Stack(
                      children: [
                        // Background decorations
                        Positioned(
                          right: -20,
                          top: -20,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: widget.courseColor.withValues(alpha: 0.05),
                            ),
                          ),
                        ),
                        Positioned(
                          left: -30,
                          bottom: -30,
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: widget. courseColor.withValues(alpha: 0.03),
                            ),
                          ),
                        ),
                        // Main content
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment. start,
                            children: [
                              // Header row (space for checkbox + add button)
                              Padding(
                                padding: const EdgeInsets.only(right: 80.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Hero(
                                      tag: 'assignment_icon_${widget.assignment. title}_${widget.index}',
                                      child: Container(
                                        padding: const EdgeInsets. all(10.0),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              iconContainerColor,
                                              iconContainerColor.withValues(alpha: 0.8),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(14.0),
                                          boxShadow: [
                                            BoxShadow(
                                              color: widget.courseColor.withValues(alpha: 0.1),
                                              blurRadius: 6,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          _getIconForType(widget.assignment. type),
                                          size: 22,
                                          color: iconColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          AnimatedDefaultTextStyle(
                                            duration: const Duration(milliseconds: 300),
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: widget.assignment.completed
                                                  ? primaryTextColor. withValues(alpha: 0.6)
                                                  : primaryTextColor,
                                              height: 1.2,
                                              decoration: widget.assignment.completed
                                                  ?  TextDecoration.lineThrough
                                                  : TextDecoration.none,
                                              decorationColor: primaryTextColor. withValues(alpha: 0.5),
                                              decorationThickness: 2,
                                            ),
                                            child: Text(
                                              widget. assignment.title,
                                              maxLines: 2,
                                              overflow: TextOverflow. ellipsis,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                                            decoration: BoxDecoration(
                                              color: widget.courseColor.withValues(
                                                alpha: widget.assignment.completed ?  0.06 : 0.12,
                                              ),
                                              borderRadius: BorderRadius.circular(6.0),
                                            ),
                                            child: Text(
                                              widget.assignment.type. toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: widget.assignment.completed
                                                    ? widget.courseColor.withValues(alpha: 0.6)
                                                    : widget.courseColor,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              // Due date row
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6.0),
                                    decoration: BoxDecoration(
                                      color: widget.courseColor.withValues(
                                        alpha: widget.assignment.completed ? 0.05 : 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    child: Icon(
                                      Icons.schedule_rounded,
                                      size: 14,
                                      color: widget.assignment.completed
                                          ? widget.courseColor.withValues(alpha: 0.6)
                                          : widget.courseColor,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: widget.assignment.dueDate != null
                                        ? Column(
                                      crossAxisAlignment: CrossAxisAlignment. start,
                                      children: [
                                        Text(
                                          widget.assignment. dueDate!.toLocal().toString().split(' ')[0],
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: widget. assignment.completed
                                                ? primaryTextColor.withValues(alpha: 0.5)
                                                : primaryTextColor,
                                          ),
                                        ),
                                        Text(
                                          widget.assignment. dueDate!.toLocal().toString().split(' ')[1]. split('. ')[0],
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight. w500,
                                            color: widget. assignment.completed
                                                ? secondaryTextColor.withValues(alpha: 0.5)
                                                : secondaryTextColor,
                                          ),
                                        ),
                                      ],
                                    )
                                        : Text(
                                      "No Due Date",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: widget.assignment.completed
                                            ? secondaryTextColor.withValues(alpha: 0.5)
                                            : secondaryTextColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // NEW: Add to Task List button (positioned top right, before checkbox)
            if (widget.taskManager != null)
              Positioned(
                top: 12,
                right: 48, // Position before the checkbox
                child: GestureDetector(
                  onTap: isInTaskList ? null : _handleAddToTaskList,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.all(4.0),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius. circular(8.0),
                        color: isInTaskList
                            ? Colors.green.withValues(alpha: 0.15)
                            : widget.courseColor. withValues(alpha: 0.12),
                        border: Border.all(
                          color: isInTaskList
                              ? Colors.green.withValues(alpha: 0.4)
                              : widget.courseColor. withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          isInTaskList
                              ? Icons.playlist_add_check_rounded
                              : Icons.playlist_add_rounded,
                          size: 16,
                          color: isInTaskList
                              ? Colors.green
                              : widget. courseColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // Checkbox
            Positioned(
              top: 12,
              right: 12,
              child: GestureDetector(
                onTap: _handleCheckboxTap,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.all(4.0),
                  child: _isInitialized && _checkboxAnimation != null
                      ?  AnimatedBuilder(
                    animation: _checkboxAnimation!,
                    builder: (context, child) {
                      return _buildCheckboxContainer();
                    },
                  )
                      : _buildCheckboxContainer(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckboxContainer() {
    final theme = Theme.of(context);
    final isCompleted = widget. assignment.completed;
    final completionProgress = _isInitialized && _checkboxAnimation != null
        ? _checkboxAnimation!. value
        : (isCompleted ? 1.0 : 0.0);

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        borderRadius: BorderRadius. circular(8.0),
        gradient: isCompleted
            ?  LinearGradient(
          colors: [
            Colors.green.shade400,
            Colors.green.shade600,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
            : LinearGradient(
          colors: [
            theme.colorScheme. surface,
            theme.colorScheme.surface.withValues(alpha: 0.8),
          ],
        ),
        border: Border.all(
          color: isCompleted
              ? Colors.green.shade600
              : theme.colorScheme. outline. withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          if (isCompleted)
            BoxShadow(
              color: Colors.green. withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Center(
        child: AnimatedScale(
          scale: completionProgress,
          duration: const Duration(milliseconds: 200),
          child: Icon(
            Icons.check_rounded,
            size: 16,
            color: isCompleted ? Colors.white : Colors.transparent,
            weight: 800,
          ),
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type. toLowerCase()) {
      case 'assignment':
        return Icons. assignment_rounded;
      case 'discussion':
        return Icons.forum_rounded;
      case 'assessment':
        return Icons.quiz_rounded;
      default:
        return Icons.task_rounded;
    }
  }
}

// =============================================================================
// AssignmentGrid - Grid of assignment cards
// =============================================================================

class AssignmentGrid extends StatefulWidget {
  final List<Assignment> assignments;
  final Color courseColor;
  final bool isTablet;
  final String noneText;
  final VoidCallback onAssignmentChanged;
  final bool allowDismiss;
  final String dismissActionText;
  final IconData dismissIcon;
  final bool autoHide;
  final SortOption currentSortOption;
  final TaskManager?  taskManager; // NEW: Task manager for cards

  const AssignmentGrid({
    super.key,
    required this.assignments,
    required this.courseColor,
    required this.isTablet,
    required this.noneText,
    required this.onAssignmentChanged,
    required this.autoHide,
    required this.currentSortOption,
    this.allowDismiss = true,
    this.dismissActionText = 'Hide Assignment',
    this. dismissIcon = Icons. visibility_off_rounded,
    this.taskManager,
  });

  @override
  State<AssignmentGrid> createState() => _AssignmentGridState();
}

class _AssignmentGridState extends State<AssignmentGrid> {
  late List<Assignment> _assignments;

  @override
  void initState() {
    super.initState();
    _assignments = List.from(widget.assignments);
  }

  @override
  void didUpdateWidget(AssignmentGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.assignments != oldWidget.assignments) {
      setState(() {
        _assignments = List.from(widget.assignments);
      });
    }
  }

  void _saveAssignments() {
    Map<dynamic, dynamic> rawAssignments = hiveManager.box.get("assignments") ?? {};
    Map<String, List<Assignment>> assignments = {};
    rawAssignments. forEach((key, value) {
      if (key is String && value is List) {
        assignments[key] = value.cast<Assignment>();
      }
    });
    hiveManager. box.put("assignments", assignments);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (_assignments.isEmpty) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              widget.courseColor.withValues(alpha: isDarkMode ? 0.08 : 0.05),
              widget. courseColor.withValues(alpha: isDarkMode ? 0.04 : 0.02),
            ],
          ),
          borderRadius: BorderRadius.circular(24.0),
          border: Border.all(
            color: widget.courseColor. withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets. all(20.0),
                decoration: BoxDecoration(
                  color: widget.courseColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.celebration_outlined,
                  size: 48,
                  color: widget.courseColor,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                widget.noneText,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context). colorScheme.onSurface. withValues(alpha: 0.8),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Take a well-deserved break!  🎉',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign. center,
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.isTablet ? 2 : 1,
        childAspectRatio: widget.isTablet ?  2.0 : 2.5,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
      ),
      itemCount: _assignments. length,
      itemBuilder: (context, index) {
        return AnimatedContainer(
          duration: Duration(milliseconds: 300 + (index * 100)),
          curve: Curves.easeOutBack,
          child: Dismissible(
            key: Key(_assignments[index].title),
            direction: DismissDirection.horizontal,
            background: _buildDismissBackground(),
            secondaryBackground: _buildDismissBackground(),
            onDismissed: (direction) {
              setState(() {
                _assignments[index].visible = ! _assignments[index]. visible;
                _assignments. removeAt(index);
              });
              _saveAssignments();
              widget.onAssignmentChanged();
            },
            child: AssignmentCard(
              assignment: _assignments[index],
              courseColor: widget. courseColor,
              index: index,
              autoHide: widget. autoHide,
              onAssignmentChanged: widget.onAssignmentChanged,
              taskManager: widget.taskManager, // NEW: Pass task manager to card
            ),
          ),
        );
      },
    );
  }

  Widget _buildDismissBackground() {
    final isShowingHidden = _assignments.isNotEmpty && ! _assignments. first.visible;
    final backgroundColor = isShowingHidden ?  Colors.grey : Colors.red;
    final actionText = isShowingHidden ? 'Show Assignment' : widget.dismissActionText;
    final subText = isShowingHidden ? 'Swipe to make visible' : 'Swipe to remove from view';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            backgroundColor.withValues(alpha: 0.8),
            backgroundColor. withValues(alpha: 0.6),
            backgroundColor.withValues(alpha: 0.4),
          ],
          stops: const [0.0, 0.7, 1.0],
        ),
        borderRadius: BorderRadius. circular(20.0),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 24),
          Container(
            padding: const EdgeInsets. all(12.0),
            decoration: BoxDecoration(
              color: Colors.white. withValues(alpha: 0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              isShowingHidden ?  Icons.visibility : widget.dismissIcon,
              color: backgroundColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  actionText,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black. withValues(alpha: 0.3),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.9),
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 1,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
        ],
      ),
    );
  }
}