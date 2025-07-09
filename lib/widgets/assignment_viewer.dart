import 'package:flutter/material.dart';
import 'package:myapp/class_essentials/assignment.dart';
import 'package:myapp/class_essentials/assignment_manager.dart';

class AssignmentViewer extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final crossAxisCount = isTablet ? 2 : 1;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    String noneText = "";
    List<Assignment> assignments;
    if(timeBased){
      switch(courseName){
        case 'Today':
          noneText = "You have no assignments due today!";
          assignments = am.getAssignmentsDueToday();
          break;
        case 'Tomorrow':
          noneText = "You have no assignments due tomorrow!";
          assignments = am.getAssignmentsDueTomorrow();
          break;
        case 'This Week':
          noneText = "You have no assignments due later this week!";
          assignments = am.getAssignmentsDueLaterThisWeek();
          break;
        case 'Overdue':
          noneText = "You have no overdue assignments!";
          assignments = am.getOverdueAssignments();
          break;
        case 'No Date/Other':
          noneText = "You have no assignments without a due date!";
          assignments = am.getOtherAssignments();
          break;
        default:
          assignments = [];
          print("Error: Unknown time-based folder $courseName");
      }
    } else{
      noneText = "You have no assignments for this course!";
      assignments = am.getAssignmentsForCourse(courseName);
    }
    print("Assignments for $courseName: ${assignments.length}");

    // Calculate app bar text color based on course color
    final appBarTextColor = _getTextColorForBackground(courseColor);

    return Scaffold(
      appBar: AppBar(
        title: Text(courseName),
        backgroundColor: courseColor,
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
              courseColor.withValues(alpha: isDarkMode ? 0.08 : 0.15),
              Theme.of(context).scaffoldBackgroundColor,
            ],
            stops: const [0.15, 0.85],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
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
                courseColor: courseColor,
              );
            },
          ),
        ),
      ),
    );
  }

  Color _getTextColorForBackground(Color background) {
    final brightness = (0.587 * background.r + 0.299 * background.g + 0.114 * background.b) / 255;
    return brightness > 0.5 ? Colors.black87 : Colors.white;
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