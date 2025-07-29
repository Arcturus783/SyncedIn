import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/widgets/folder.dart';
import 'package:myapp/class_essentials/theme.dart';
import 'package:myapp/class_essentials/assignment_manager.dart';

class CourseScreen extends ConsumerStatefulWidget {
  final List<dynamic> courses;
  final AssignmentManager am;
  bool autoHide;
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
  CourseScreen({Key? key, required this.courses, required this.am, required this.autoHide}) : super(key: key);

  @override
  ConsumerState<CourseScreen> createState() => _CourseScreenState();
}

class _CourseScreenState extends ConsumerState<CourseScreen> {
  bool _isTimeBasedView = false; // false = courses view, true = time-based view

  // Time-based folder data
  final List<String> _timeBasedFolders = [
    'Today',
    'Tomorrow',
    'This Week',
    'Overdue',
    'No Date/Other'
  ];

  // Helper method to distribute color indices across the gradient
  List<int> _distributeColorIndices(int itemCount, int totalColors) {
    if (itemCount <= 1) return [0];
    if (itemCount >= totalColors) {
      // If we have more items than colors, cycle through all colors
      return List.generate(itemCount, (index) => index % totalColors);
    }

    // Distribute indices evenly across the gradient
    List<int> indices = [];
    for (int i = 0; i < itemCount; i++) {
      // Calculate the position in the gradient (0.0 to 1.0)
      double position = i / (itemCount - 1);
      // Map to color index (0 to totalColors-1)
      int colorIndex = (position * (totalColors - 1)).round();
      indices.add(colorIndex);
    }
    return indices;
  }

  @override
  Widget build(BuildContext context) {
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

    // Calculate color indices based on current view
    final List<int> colorIndices = _isTimeBasedView
        ? _distributeColorIndices(_timeBasedFolders.length, 15)
        : _distributeColorIndices(widget.courses.length, 15);

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
            // Toggle switch section
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Courses',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: !_isTimeBasedView
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      fontWeight: !_isTimeBasedView ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Switch.adaptive(
                      value: _isTimeBasedView,
                      onChanged: (value) {
                        setState(() {
                          _isTimeBasedView = value;
                        });
                      },
                      activeColor: Theme.of(context).colorScheme.primary,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  Text(
                    'Time-based',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _isTimeBasedView
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      fontWeight: _isTimeBasedView ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),

            // Header section
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Text(
                _isTimeBasedView
                    ? ''
                    : '${widget.courses.length} Courses',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // Folders list - either courses or time-based
            if (_isTimeBasedView)
            // Time-based folders
              ..._timeBasedFolders.asMap().entries.map((entry) {
                int index = entry.key;
                String folderName = entry.value;
                int colorIndex = colorIndices[index];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Folder(
                    courseName: folderName,
                    colorIndex: colorIndex,
                    am: widget.am,
                    indexNum: 0,
                    autoHide: widget.autoHide,
                  ),
                );
              })
            else
            // Course folders
              ...widget.courses.asMap().entries.map((entry) {
                int index = entry.key;
                String courseName = entry.value;
                int colorIndex = colorIndices[index];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Folder(
                    courseName: courseName,
                    colorIndex: colorIndex,
                    am: widget.am,
                    indexNum: index + 1,
                    autoHide: widget.autoHide,
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}