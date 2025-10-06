import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:myapp/class_essentials/assignment.dart';
import 'package:myapp/class_essentials/assignment_manager.dart';
import 'package:myapp/class_essentials/theme.dart';

enum SortOption {
  dueDate('Due Date'),
  alphabetical('Alphabetical');

  const SortOption(this.label);
  final String label;
}

class CalendarScreen extends ConsumerStatefulWidget {
  final DateTime focusedDay;
  final Color currentColor;
  final Function(DateTime) getEventsToday;
  final Function(DateTime) getAssignmentsForDay;
  final List<Assignment> assignmentsPerDay;
  final AssignmentManager am;

  const CalendarScreen({
    super.key,
    required this.focusedDay,
    required this.currentColor,
    required this.assignmentsPerDay,
    required this.getEventsToday,
    required this.getAssignmentsForDay,
    required this.am,
  });

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen>
    with TickerProviderStateMixin {
  late DateTime _selectedDay;
  late DateTime _focusedDay;
  late List<Assignment> _assignmentsToday;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  SortOption _currentSortOption = SortOption.dueDate; // Default to due date

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _focusedDay = widget.focusedDay;

    // Use the new optimized method from AssignmentManager
    _assignmentsToday = widget.am.getAssignmentsForDate(_selectedDay);
    _applySorting();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      // Use the optimized method for getting assignments for the selected date
      _assignmentsToday = widget.am.getAssignmentsForDate(selectedDay);
      _applySorting();
    });

    // Trigger a subtle animation when changing days
    _fadeController.reset();
    _fadeController.forward();
  }

  void _applySorting() {
    if (_currentSortOption == SortOption.dueDate) {
      sortByDueDate(_assignmentsToday);
    } else {
      sortByName(_assignmentsToday);
    }
  }

  void sortByName(List<Assignment> assignments) {
    assignments.sort((a, b) => a.title.compareTo(b.title));
  }

  void sortByDueDate(List<Assignment> assignments) {
    assignments.sort((a, b) {
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

  // Updated event loader to work with the new AssignmentManager structure
  List<Assignment> _getEventsForDay(DateTime day) {
    return widget.am.getAssignmentsForDate(day);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(currentThemeProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    DateTime today = DateTime.now();

    return CustomScrollView(
      slivers: [
        // Calendar Container as a sliver
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24.0),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.lightTheme.colorScheme.surface,
                  theme.lightTheme.colorScheme.surface.withValues(alpha: 0.8),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.lightTheme.colorScheme.primary.withValues(alpha: 0.1),
                  spreadRadius: 2,
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: isDarkMode
                      ? Colors.black.withValues(alpha: 0.3)
                      : Colors.black.withValues(alpha: 0.05),
                  spreadRadius: 0,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24.0),
              child: TableCalendar(
                availableCalendarFormats: const {CalendarFormat.month: "Month"},
                headerStyle: HeaderStyle(
                  titleCentered: true,
                  formatButtonVisible: false,
                  leftChevronIcon: Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: theme.lightTheme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Icon(
                      Icons.chevron_left_rounded,
                      color: theme.lightTheme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  rightChevronIcon: Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: theme.lightTheme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: theme.lightTheme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  titleTextStyle: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: theme.lightTheme.colorScheme.onSurface,
                    letterSpacing: 0.5,
                  ),
                  headerPadding: const EdgeInsets.symmetric(vertical: 16.0),
                ),
                firstDay: today.subtract(const Duration(days: 29)),
                lastDay: today.add(const Duration(days: 30)),
                focusedDay: _focusedDay,
                eventLoader: _getEventsForDay,
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDay, day);
                },
                onDaySelected: _onDaySelected,
                calendarFormat: _calendarFormat,
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  defaultTextStyle: TextStyle(
                    color: theme.lightTheme.colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                  weekendTextStyle: TextStyle(
                    color: theme.lightTheme.colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                  markerDecoration: BoxDecoration(
                    color: theme.lightTheme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  markerSize: 8,
                  markersMaxCount: 3,
                  todayDecoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.lightTheme.colorScheme.secondary,
                        theme.lightTheme.colorScheme.secondary.withValues(alpha: 0.8),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: theme.lightTheme.colorScheme.secondary.withValues(alpha: 0.3),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  selectedDecoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.lightTheme.colorScheme.primary,
                        theme.lightTheme.colorScheme.primary.withValues(alpha: 0.8),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: theme.lightTheme.colorScheme.primary.withValues(alpha: 0.4),
                        spreadRadius: 1,
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  todayTextStyle: TextStyle(
                    color: theme.lightTheme.colorScheme.onSecondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                  selectedTextStyle: TextStyle(
                    color: theme.lightTheme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                  cellPadding: const EdgeInsets.all(8.0),
                  cellMargin: const EdgeInsets.all(4.0),
                ),
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: TextStyle(
                    color: theme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                  weekendStyle: TextStyle(
                    color: theme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: const SizedBox(height: 8),
        ),

        // Assignments Section with animations
        SliverToBoxAdapter(
          child: SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _assignmentsToday.isNotEmpty
                  ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                    child: Text(
                      _getDateHeaderText(_selectedDay),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: theme.lightTheme.colorScheme.onSurface,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),

                  // Sort dropdown - moved below date header with enhanced styling
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                    child: Container(
                      padding: const EdgeInsets.all(4.0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.lightTheme.colorScheme.primary.withValues(alpha: isDarkMode ? 0.12 : 0.08),
                            theme.lightTheme.colorScheme.primary.withValues(alpha: isDarkMode ? 0.06 : 0.04),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16.0),
                        border: Border.all(
                          color: theme.lightTheme.colorScheme.primary.withValues(alpha: 0.25),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: theme.lightTheme.colorScheme.primary.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                color: theme.lightTheme.colorScheme.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              child: Icon(
                                Icons.tune_rounded,
                                size: 20,
                                color: theme.lightTheme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Sort by:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
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
                                        _applySorting();
                                      });
                                    }
                                  },
                                  items: SortOption.values.map<DropdownMenuItem<SortOption>>((SortOption value) {
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
                                      color: theme.lightTheme.colorScheme.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6.0),
                                    ),
                                    child: Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      size: 20,
                                      color: theme.lightTheme.colorScheme.primary,
                                    ),
                                  ),
                                  dropdownColor: Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(12.0),
                                  elevation: 8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),
                ],
              )
                  : Padding(
                padding: const EdgeInsets.symmetric(vertical: 60.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24.0),
                      decoration: BoxDecoration(
                        color: theme.lightTheme.colorScheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.event_available_rounded,
                        size: 48,
                        color: theme.lightTheme.colorScheme.primary.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "No ${_getDateHeaderText(_selectedDay)}",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).brightness == Brightness.light
                            ? theme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.7)
                            : theme.darkTheme?.colorScheme.onSurface.withValues(alpha: 0.7),
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Enjoy your free time! 🎉",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).brightness == Brightness.light
                            ? theme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.7)
                            : theme.darkTheme?.colorScheme.onSurface.withValues(alpha: 0.7),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Assignment cards as slivers
        if (_assignmentsToday.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
                  Assignment assignment = _assignmentsToday[index];
                  // Cycle through course colors based on index
                  final courseColor = theme.courseColors[index % theme.courseColors.length];

                  return AnimatedContainer(
                    duration: Duration(milliseconds: 300 + (index * 100)),
                    curve: Curves.easeOutCubic,
                    margin: const EdgeInsets.only(bottom: 12.0),
                    child: EnhancedCalendarCard(
                      assignment: assignment,
                      theme: theme,
                      index: index,
                      courseColor: courseColor,  // Pass the color
                    ),
                  );
                },
                childCount: _assignmentsToday.length,
              ),
            ),
          ),

        // Bottom padding
        SliverToBoxAdapter(
          child: const SizedBox(height: 16),
        ),
      ],
    );
  }

  String _getDateHeaderText(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final selectedDay = DateTime(date.year, date.month, date.day);

    if (selectedDay == today) {
      return "Today's Assignments";
    } else if (selectedDay == tomorrow) {
      return "Tomorrow's Assignments";
    } else {
      final months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      return "Assignments for ${months[date.month - 1]} ${date.day}";
    }
  }
}

class EnhancedCalendarCard extends StatefulWidget {
  final Assignment assignment;
  final AppTheme theme;
  final int index;
  final Color courseColor;  // Add this parameter

  const EnhancedCalendarCard({
    super.key,
    required this.assignment,
    required this.theme,
    required this.index,
    required this.courseColor,  // Add this parameter
  });

  @override
  State<EnhancedCalendarCard> createState() => _EnhancedCalendarCardState();
}

class _EnhancedCalendarCardState extends State<EnhancedCalendarCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeInOut,
    ));
    _elevationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  void _onHover(bool isHovered) {
    setState(() => _isHovered = isHovered);
    if (isHovered) {
      _hoverController.forward();
    } else {
      _hoverController.reverse();
    }
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

  // Remove the _getColorForType method - no longer needed

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = widget.courseColor;  // Use the passed color
    final darkerColor = Color.fromARGB(
      cardColor.a.round(),
      (cardColor.r * 0.85).round(),
      (cardColor.g * 0.85).round(),
      (cardColor.b * 0.85).round(),
    );

    final colorBrightness = _calculateBrightness(cardColor);
    final textColor = colorBrightness > 0.5 ? Colors.black87 : Colors.white;
    final subtextColor = colorBrightness > 0.5 ? Colors.black54 : Colors.white70;

    String date = widget.assignment.dueDate?.toString().split(" ")[0] ?? "No Due Date";
    String time = widget.assignment.dueDate?.toString().split(" ")[1].split(".")[0] ?? "";

    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      child: AnimatedBuilder(
        animation: _hoverController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.0),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    cardColor,
                    darkerColor,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: cardColor.withValues(alpha: 0.4 + (_elevationAnimation.value * 0.2)),
                    spreadRadius: 1 + (_elevationAnimation.value * 2),
                    blurRadius: 8 + (_elevationAnimation.value * 4),
                    offset: Offset(0, 4 + (_elevationAnimation.value * 2)),
                  ),
                  BoxShadow(
                    color: isDarkMode
                        ? Colors.black.withValues(alpha: 0.3)
                        : Colors.black.withValues(alpha: 0.08),
                    spreadRadius: 0,
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      // Enhanced Icon Container
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(
                            alpha: colorBrightness > 0.5 ? 0.4 : 0.25,
                          ),
                          borderRadius: BorderRadius.circular(16.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              spreadRadius: 0,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          _getIconForType(widget.assignment.type),
                          size: 28,
                          color: colorBrightness > 0.5 ? Colors.black54 : Colors.white70,
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Enhanced Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.assignment.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: textColor,
                                letterSpacing: 0.3,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            if (widget.assignment.dueDate != null) ...[
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    size: 14,
                                    color: subtextColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "Due: $date",
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: subtextColor,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                              if (time.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time_rounded,
                                      size: 14,
                                      color: subtextColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      time,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: subtextColor,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ] else ...[
                              Row(
                                children: [
                                  Icon(
                                    Icons.schedule_rounded,
                                    size: 14,
                                    color: subtextColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "No due date",
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: subtextColor,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Enhanced Type Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 6.0,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(
                            alpha: colorBrightness > 0.5 ? 0.3 : 0.2,
                          ),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Text(
                          widget.assignment.type.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: colorBrightness > 0.5 ? Colors.black54 : Colors.white70,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  double _calculateBrightness(Color color) {
    return (0.587 * color.r + 0.299 * color.g + 0.114 * color.b) / 255;
  }
}