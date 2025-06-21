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

  // Sample assignments data
  /*
  List<Assignment> get _assignments => [
    Assignment(
      title: "Midterm Exam",
      dueDate: "June 15, 2025",
      type: "assessment",
    ),
    Assignment(
      title: "Weekly Discussion: Chapter 5",
      dueDate: "June 12, 2025",
      type: "discussion",
    ),
    Assignment(
      title: "Research Paper Draft",
      dueDate: "June 18, 2025",
      type: "assignment",
    ),
    Assignment(
      title: "Lab Report #3",
      dueDate: "June 20, 2025",
      type: "assignment",
    ),
    Assignment(
      title: "Final Project Presentation",
      dueDate: "June 25, 2025",
      type: "assessment",
    ),
    Assignment(
      title: "Group Discussion Forum",
      dueDate: "June 14, 2025",
      type: "discussion",
    ),
    Assignment(
      title: "Problem Set 4",
      dueDate: "June 22, 2025",
      type: "assignment",
    ),
    Assignment(
      title: "Peer Review Activity",
      dueDate: "June 16, 2025",
      type: "other",
    ),
  ];
  */
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final crossAxisCount = isTablet ? 2 : 1;
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

    return Scaffold(
      appBar: AppBar(
        title: Text(courseName),
        backgroundColor: courseColor,
        foregroundColor: _getTextColorForBackground(courseColor),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              courseColor.withValues(alpha: 0.15),
              Theme.of(context).scaffoldBackgroundColor,
            ],
            stops: const [0.15, 0.85],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: assignments.isEmpty ? Center(child: Text(noneText)) : GridView.builder(
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
    final cardColor = Color.fromARGB(
      courseColor.a.round(),
      (courseColor.r + (255 - courseColor.r) * 0.5).round(),
      (courseColor.g + (255 - courseColor.g) * 0.5).round(),
      (courseColor.b + (255 - courseColor.b) * 0.5).round(),
    );

    final textColor = courseColor.withValues(alpha:1);
    final subtitleColor = textColor.withValues(alpha: 0.7);

    return Card(
      elevation: 4,
      shadowColor: courseColor.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.0),
          color: cardColor,
          border: Border.all(
            color: courseColor.withValues(alpha: 0.3),
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
                      color: courseColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Icon(
                      _getIconForType(assignment.type),
                      size: 20,
                      color: courseColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      assignment.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor,
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
                    color: subtitleColor,
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
                        color: subtitleColor,
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