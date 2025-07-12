import 'package:flutter/material.dart';
import 'package:myapp/class_essentials/assignment.dart';
import 'package:myapp/class_essentials/assignment_manager.dart';

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

  const AssignmentViewer({
    super.key,
    required this.courseName,
    required this.courseColor,
    required this.am,
    required this.timeBased,
  });

  @override
  State<AssignmentViewer> createState() => _AssignmentViewerState();
}

class _AssignmentViewerState extends State<AssignmentViewer> {
  SortOption _currentSortOption = SortOption.dueDate; // Default to due date

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final crossAxisCount = isTablet ? 2 : 1;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    String noneText = "";
    List<Assignment> assignments;
    if(widget.timeBased){
      switch(widget.courseName){
        case 'Today':
          noneText = "You have no assignments due today!";
          assignments = widget.am.getAssignmentsDueToday();
          break;
        case 'Tomorrow':
          noneText = "You have no assignments due tomorrow!";
          assignments = widget.am.getAssignmentsDueTomorrow();
          break;
        case 'This Week':
          noneText = "You have no assignments due later this week!";
          assignments = widget.am.getAssignmentsDueLaterThisWeek();
          break;
        case 'Overdue':
          noneText = "You have no overdue assignments!";
          assignments = widget.am.getOverdueAssignments();
          break;
        case 'No Date/Other':
          noneText = "You have no assignments without a due date!";
          assignments = widget.am.getOtherAssignments();
          break;
        default:
          assignments = [];
          print("Error: Unknown time-based folder ${widget.courseName}");
      }
    } else{
      noneText = "You have no assignments for this course!";
      assignments = widget.am.getAssignmentsForCourse(widget.courseName);
    }
    print("Assignments for ${widget.courseName}: ${assignments.length}");

    // Apply sorting based on current selection
    if (_currentSortOption == SortOption.dueDate) {
      sortByDueDate(assignments);
    } else {
      sortByName(assignments);
    }

    // Calculate app bar text color based on course color
    final appBarTextColor = _getTextColorForBackground(widget.courseColor);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.courseName),
        backgroundColor: widget.courseColor,
        foregroundColor: appBarTextColor,
        elevation: 0,
        iconTheme: IconThemeData(color: appBarTextColor),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              widget.courseColor.withValues(alpha: isDarkMode ? 0.08 : 0.15),
              Theme.of(context).scaffoldBackgroundColor,
            ],
            stops: const [0.15, 0.85],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Sort dropdown
              if (assignments.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 16.0),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? widget.courseColor.withValues(alpha: 0.1)
                        : widget.courseColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(
                      color: widget.courseColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.sort_rounded,
                        size: 20,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Sort by:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(width: 12),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<SortOption>(
                          value: _currentSortOption,
                          onChanged: (SortOption? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _currentSortOption = newValue;
                              });
                            }
                          },
                          items: SortOption.values.map<DropdownMenuItem<SortOption>>((SortOption value) {
                            return DropdownMenuItem<SortOption>(
                              value: value,
                              child: Text(
                                value.label,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            );
                          }).toList(),
                          icon: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 20,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          dropdownColor: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ],
                  ),
                ),
              // Assignment grid or empty state
              Expanded(
                child: assignments.isEmpty
                    ? Center(
                  child: Text(
                    noneText,
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
                    : GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: isTablet ? 2.5 : 3.0,
                    crossAxisSpacing: 16.0,
                    mainAxisSpacing: 16.0,
                  ),
                  itemCount: assignments.length,
                  itemBuilder: (context, index) {
                    return AssignmentCard(
                      assignment: assignments[index],
                      courseColor: widget.courseColor,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getTextColorForBackground(Color background) {
    final brightness = (0.587 * background.r + 0.299 * background.g + 0.114 * background.b) / 255;
    return brightness > 0.5 ? Colors.black87 : Colors.white;
  }

  void sortByName(List<Assignment> as){
    as.sort((a,b) => a.title.compareTo(b.title));
  }

  void sortByDueDate(List<Assignment> as) {
    as.sort((a, b) {
      if (a.dueDate == null && b.dueDate == null) return 0;
      if (a.dueDate == null) return 1;
      if (b.dueDate == null) return -1;

      int dateComparison = a.dueDate!.compareTo(b.dueDate!);

      if (dateComparison == 0) {
        return a.title.compareTo(b.title);
      }
      return dateComparison;
    });
  }
}

class AssignmentCard extends StatelessWidget {
  final Assignment assignment;
  final Color courseColor;

  const AssignmentCard({
    super.key,
    required this.assignment,
    required this.courseColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    // Create a more reliable card background that works in both light and dark modes
    final cardColor = isDarkMode
        ? Color.alphaBlend(
      courseColor.withValues(alpha: 0.15),
      theme.colorScheme.surface,
    )
        : Color.alphaBlend(
      courseColor.withValues(alpha: 0.08),
      theme.colorScheme.surface,
    );

    // Use theme-aware text colors with sufficient contrast
    final primaryTextColor = theme.colorScheme.onSurface;
    final secondaryTextColor = theme.colorScheme.onSurface.withValues(alpha: 0.7);

    // Icon container background that adapts to theme
    final iconContainerColor = isDarkMode
        ? courseColor.withValues(alpha: 0.2)
        : courseColor.withValues(alpha: 0.15);

    // Icon color that ensures visibility
    final iconColor = isDarkMode
        ? courseColor.withValues(alpha: 0.9)
        : courseColor;

    return Card(
      elevation: isDarkMode ? 2 : 4,
      shadowColor: courseColor.withValues(alpha: isDarkMode ? 0.15 : 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      color: cardColor,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: courseColor.withValues(alpha: isDarkMode ? 0.2 : 0.3),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: iconContainerColor,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Icon(
                      _getIconForType(assignment.type),
                      size: 20,
                      color: iconColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      assignment.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: primaryTextColor,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 16,
                    color: secondaryTextColor,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      assignment.dueDate != null
                          ? "Due: ${assignment.dueDate!.toLocal().toString().split(' ')[0]} at ${assignment.dueDate!.toLocal().toString().split(' ')[1].split('.')[0]}"
                          : "No Due Date",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: secondaryTextColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'assignment':
        return Icons.assignment_rounded;
      case 'discussion':
        return Icons.forum_rounded;
      case 'assessment':
        return Icons.quiz_rounded;
      default:
        return Icons.task_rounded;
    }
  }
}