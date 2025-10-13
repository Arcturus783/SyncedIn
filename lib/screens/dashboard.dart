import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:myapp/class_essentials/assignment.dart';
import 'package:myapp/class_essentials/assignment_manager.dart';
import 'package:myapp/class_essentials/theme.dart';
import 'package:myapp/widgets/assignment_viewer.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  final AssignmentManager am;

  const DashboardScreen({
    super.key,
    required this.am,
  });

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with TickerProviderStateMixin {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  late AnimationController _greetingController;
  late Animation<double> _greetingFadeAnimation;
  late Animation<Color?> _greetingColorAnimation;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();

    // Animation for greeting text
    _greetingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _greetingFadeAnimation = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _greetingController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _greetingController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return "Good morning!";
    } else if (hour < 17) {
      return "Good afternoon!";
    } else {
      return "Good evening!";
    }
  }

  Color _getGreetingColor(AppTheme theme) {
    final hour = DateTime.now().hour;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    if (hour < 12) {
      // Morning - yellow/gold tones
      return isDarkMode 
          ? const Color.fromARGB(255, 255, 214, 10)
          : const Color.fromARGB(255, 255, 179, 0);
    } else if (hour < 17) {
      // Afternoon - bright blue/orange tones
      return isDarkMode
          ? const Color.fromARGB(255, 56, 189, 248)
          : const Color.fromARGB(255, 14, 165, 233);
    } else {
      // Evening - purple/indigo tones
      return isDarkMode
          ? const Color.fromARGB(255, 168, 85, 247)
          : const Color.fromARGB(255, 124, 58, 237);
    }
  }

  List<Assignment> _getEventsForDay(DateTime day) {
    return widget.am.getAssignmentsForDate(day);
  }

  void _refreshAssignments() {
    setState(() {
      // Forces rebuild with updated assignment states
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(currentThemeProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Get today's incomplete assignments
    final todayAssignments = widget.am
        .getAssignmentsDueToday()
        .where((a) => !a.completed)
        .toList();
    
    // Get overdue incomplete assignments
    final overdueAssignments = widget.am
        .getOverdueAssignments()
        .where((a) => !a.completed)
        .toList();

    // Calculate responsive padding
    double horizontalPadding;
    if (screenWidth < 600) {
      horizontalPadding = 16.0;
    } else if (screenWidth < 900) {
      horizontalPadding = screenWidth * 0.1;
    } else {
      horizontalPadding = screenWidth * 0.2;
    }

    final greetingColor = _getGreetingColor(theme);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Animated Greeting Section
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 24.0),
            child: FadeTransition(
              opacity: _greetingFadeAnimation,
              child: Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      greetingColor.withValues(alpha: 0.15),
                      greetingColor.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24.0),
                  border: Border.all(
                    color: greetingColor.withValues(alpha: 0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: greetingColor.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            greetingColor.withValues(alpha: 0.3),
                            greetingColor.withValues(alpha: 0.2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16.0),
                        boxShadow: [
                          BoxShadow(
                            color: greetingColor.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        DateTime.now().hour < 12 
                            ? Icons.wb_sunny_rounded 
                            : DateTime.now().hour < 17 
                                ? Icons.wb_cloudy_rounded 
                                : Icons.nightlight_round,
                        size: 32,
                        color: greetingColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        _getGreeting(),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: greetingColor,
                          letterSpacing: 0.5,
                          shadows: [
                            Shadow(
                              color: greetingColor.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Today's Assignments Section
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Container(
              margin: const EdgeInsets.only(bottom: 16.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.lightTheme.colorScheme.primary.withValues(alpha: 0.12),
                    theme.lightTheme.colorScheme.primary.withValues(alpha: 0.06),
                  ],
                ),
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(
                  color: theme.lightTheme.colorScheme.primary.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: theme.lightTheme.colorScheme.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Icon(
                      Icons.today_rounded,
                      color: theme.lightTheme.colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Due Today",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          todayAssignments.isEmpty 
                              ? "No assignments due today! 🎉"
                              : "${todayAssignments.length} assignment${todayAssignments.length != 1 ? 's' : ''} remaining",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Today's Assignments List
        if (todayAssignments.isNotEmpty)
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final assignment = todayAssignments[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: AssignmentCard(
                      assignment: assignment,
                      courseColor: theme.courseColors[index % theme.courseColors.length],
                      index: index,
                      autoHide: false,
                      onAssignmentChanged: _refreshAssignments,
                    ),
                  );
                },
                childCount: todayAssignments.length,
              ),
            ),
          ),

        // Mini Calendar Section
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16.0),
            child: Container(
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
                  availableCalendarFormats: const {CalendarFormat.week: "Week"},
                  calendarFormat: CalendarFormat.week,
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
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: theme.lightTheme.colorScheme.onSurface,
                      letterSpacing: 0.5,
                    ),
                    headerPadding: const EdgeInsets.symmetric(vertical: 12.0),
                  ),
                  firstDay: DateTime.now().subtract(const Duration(days: 365)),
                  lastDay: DateTime.now().add(const Duration(days: 365)),
                  focusedDay: _focusedDay,
                  eventLoader: _getEventsForDay,
                  selectedDayPredicate: (day) {
                    return isSameDay(_selectedDay, day);
                  },
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  calendarStyle: CalendarStyle(
                    outsideDaysVisible: false,
                    defaultTextStyle: TextStyle(
                      color: theme.lightTheme.colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                    weekendTextStyle: TextStyle(
                      color: theme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                    todayDecoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.lightTheme.colorScheme.primary.withValues(alpha: 0.3),
                          theme.lightTheme.colorScheme.primary.withValues(alpha: 0.2),
                        ],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.lightTheme.colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    selectedDecoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.lightTheme.colorScheme.primary,
                          theme.lightTheme.colorScheme.primary.withValues(alpha: 0.8),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: theme.lightTheme.colorScheme.primary.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    todayTextStyle: TextStyle(
                      color: theme.lightTheme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                    selectedTextStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                    markerDecoration: BoxDecoration(
                      color: theme.lightTheme.colorScheme.secondary,
                      shape: BoxShape.circle,
                    ),
                    markerSize: 6.0,
                    markersMaxCount: 3,
                  ),
                  daysOfWeekStyle: DaysOfWeekStyle(
                    weekdayStyle: TextStyle(
                      color: theme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    weekendStyle: TextStyle(
                      color: theme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Overdue Assignments Section
        if (overdueAssignments.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16.0),
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.red.shade400.withValues(alpha: 0.12),
                      Colors.red.shade400.withValues(alpha: 0.06),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(
                    color: Colors.red.shade400.withValues(alpha: 0.25),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10.0),
                      decoration: BoxDecoration(
                        color: Colors.red.shade400.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Icon(
                        Icons.warning_rounded,
                        color: Colors.red.shade600,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Overdue",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.red.shade700,
                            ),
                          ),
                          Text(
                            "${overdueAssignments.length} assignment${overdueAssignments.length != 1 ? 's' : ''} past due",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Overdue Assignments List
        if (overdueAssignments.isNotEmpty)
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              0,
              horizontalPadding,
              24.0,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final assignment = overdueAssignments[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: AssignmentCard(
                      assignment: assignment,
                      courseColor: Colors.red.shade600,
                      index: index,
                      autoHide: false,
                      onAssignmentChanged: _refreshAssignments,
                    ),
                  );
                },
                childCount: overdueAssignments.length,
              ),
            ),
          ),

        // Bottom padding
        const SliverToBoxAdapter(
          child: SizedBox(height: 24.0),
        ),
      ],
    );
  }
}
