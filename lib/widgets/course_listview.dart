import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/widgets/folder.dart';
import 'package:myapp/class_essentials/theme.dart';
import 'package:myapp/class_essentials/assignment_manager.dart';

class CourseScreen extends ConsumerWidget {
  final List<dynamic> courses;
  final AssignmentManager am;
  /*
  final List<String> courses = [
    'Mathematics',
    'Computer Science',
    'Physics',
    'Chemistry',
    'Biology',
    'English Literature',
    'History',
    'Art & Design',
    'Music Theory',
    'Philosophy',
    'Psychology',
    'Economics',
    'Political Science',
    'Environmental Science',
  ];
  */
  CourseScreen({Key? key, required this.courses, required this.am}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(currentThemeProvider);
    final screenWidth = MediaQuery.of(context).size.width;

    // Calculate responsive horizontal padding
    double horizontalPadding;
    if (screenWidth < 600) {
      // Mobile: moderate padding
      horizontalPadding = 24.0;
    } else if (screenWidth < 900) {
      // Tablet: more padding to prevent folders from being too wide
      horizontalPadding = screenWidth * 0.15;
    } else {
      // Desktop: significant padding to create a centered column
      horizontalPadding = screenWidth * 0.25;
    }

    return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.only(
            left: horizontalPadding,
            right: horizontalPadding,
            top: 16.0,
            bottom: 32.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Optional header section
              Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Text(
                  '${courses.length} Courses',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // Course folders list
              ...courses.asMap().entries.map((entry) {
                int index = entry.key;
                if(index > 15) index = index % 15; // Cycle through colors if more than 15 courses
                String courseName = entry.value;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Folder(
                    courseName: courseName,
                    colorIndex: index,
                    am: am,
                    onTap: () {
                      // Handle folder tap - you can navigate to course details here
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Opening $courseName'),
                          duration: const Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      );
                    },
                  ),
                );
              }),
            ],
          ),
        ),
      );
  }
}