import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/class_essentials/theme.dart';
import 'assignment_viewer.dart';
import 'package:myapp/class_essentials/assignment_manager.dart';
import 'package:myapp/class_essentials/taskmanager.dart';

class Folder extends ConsumerStatefulWidget {
  final String courseName;
  final int colorIndex;
  final VoidCallback? onTap;
  final AssignmentManager am;
  final int indexNum;
  bool autoHide;
  final TaskManager? taskManager;

  Folder({
    super.key,
    required this.courseName,
    required this.colorIndex,
    required this.am,
    required this.indexNum,
    required this.autoHide,
    required this.taskManager,
    this.onTap,
  });

  @override
  ConsumerState<Folder> createState() => _FolderState();
}

class _FolderState extends ConsumerState<Folder>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glossAnimation;
  bool _isPressed = false;
  bool timeBased = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // Subtle gloss shift animation
    _glossAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _animationController.reverse();

    // Navigate to assignment viewer when folder is tapped
    if(widget.courseName == 'Today' || widget.courseName == 'Tomorrow' ||
        widget.courseName == 'This Week' || widget.courseName == 'Overdue' ||
        widget.courseName == 'No Date/Other'){
      timeBased = true;
    } else {
      timeBased = false;
    }
    _navigateToAssignments();

    widget.onTap?.call();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  void _navigateToAssignments() {
    final theme = ref.read(currentThemeProvider);
    final folderColor = theme.courseColors[widget.colorIndex % theme.courseColors.length];
    print("State of autoHide: ${widget.autoHide}");
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AssignmentViewer(
          courseName: widget.courseName,
          courseColor: folderColor,
          am: widget.am,
          timeBased: timeBased,
          autoHide: widget.autoHide,
          taskManager: widget.taskManager,
        ),
      ),
    );
  }

  // Get assignment count and completion stats
  Map<String, int> _getAssignmentStats() {
    List<dynamic> assignments;

    if(timeBased) {
      switch(widget.courseName){
        case 'Today':
          assignments = widget.am.getAssignmentsDueToday();
          break;
        case 'Tomorrow':
          assignments = widget.am.getAssignmentsDueTomorrow();
          break;
        case 'This Week':
          assignments = widget.am.getAssignmentsDueLaterThisWeek();
          break;
        case 'Overdue':
          assignments = widget.am.getOverdueAssignments();
          break;
        case 'No Date/Other':
          assignments = widget.am.getOtherAssignments();
          break;
        default:
          assignments = [];
      }
    } else {
      assignments = widget.am.getAssignmentsForCourse(widget.courseName);
    }

    final total = assignments.length;
    final completed = assignments.where((a) => a.completed).length;
    final incomplete = total - completed;

    return {
      'total': total,
      'completed': completed,
      'incomplete': incomplete,
    };
  }

  // Get icon for time-based folders
  IconData _getTimeBasedIcon() {
    switch(widget.courseName) {
      case 'Today':
        return Icons.today_rounded;
      case 'Tomorrow':
        return Icons.wb_sunny_rounded;
      case 'This Week':
        return Icons.calendar_view_week_rounded;
      case 'Overdue':
        return Icons.error_outline_rounded;
      case 'No Date/Other':
        return Icons.folder_special_rounded;
      default:
        return Icons.folder_rounded;
    }
  }

  // Get subtitle text for time-based folders
  String _getTimeBasedSubtitle(Map<String, int> stats) {
    final incomplete = stats['incomplete']!;
    final total = stats['total']!;

    if (incomplete == 0 && total == 0) {
      return 'No assignments';
    } else if (incomplete == 0) {
      return 'All complete! 🎉';
    } else if (widget.courseName == 'Overdue') {
      return incomplete == 1 ? '1 overdue task' : '$incomplete overdue tasks';
    } else {
      return incomplete == 1 ? '1 pending task' : '$incomplete pending tasks';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(currentThemeProvider);
    final isMetallic = ref.watch(metallicProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final stats = _getAssignmentStats();

    // Get color from theme's course colors, cycling through if needed
    final folderColor = theme.courseColors[widget.colorIndex % theme.courseColors.length];

    // Responsive height - slightly taller for better visual balance
    final folderHeight = screenWidth < 600 ? 130.0 : 150.0;

    // Create different color variations based on metallic/matte preference
    final Color primaryColor;
    final Color? secondaryColor;

    if (isMetallic) {
      // Metallic look - keep current gradient approach
      primaryColor = folderColor;
      secondaryColor = Color.fromARGB(
        folderColor.a.round(),
        (folderColor.r * 0.85).round(),
        (folderColor.g * 0.85).round(),
        (folderColor.b * 0.85).round(),
      );
    } else {
      // Matte look - slightly reduce saturation while keeping vibrancy
      final HSLColor hsl = HSLColor.fromColor(folderColor);
      primaryColor = hsl.withSaturation(hsl.saturation * 0.85).withLightness(
          hsl.lightness > 0.5 ? hsl.lightness * 0.95 : hsl.lightness * 1.05
      ).toColor();
      secondaryColor = null; // No gradient for matte look
    }

    // Determine text and icon colors for optimal contrast
    final colorBrightness = _calculateBrightness(primaryColor);
    final textColor = colorBrightness > 0.5
        ? Colors.black87
        : Colors.white;
    final iconColor = colorBrightness > 0.5
        ? Colors.black54
        : Colors.white70;

    // Determine if this is a time-based folder
    timeBased = widget.courseName == 'Today' ||
        widget.courseName == 'Tomorrow' ||
        widget.courseName == 'This Week' ||
        widget.courseName == 'Overdue' ||
        widget.courseName == 'No Date/Other';

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: _onTapDown,
            onTapUp: _onTapUp,
            onTapCancel: _onTapCancel,
            child: Container(
              height: folderHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24.0), // Slightly more rounded
                // Conditional decoration based on metallic preference
                gradient: isMetallic && secondaryColor != null
                    ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [primaryColor, secondaryColor],
                )
                    : null,
                color: isMetallic ? null : primaryColor, // Solid color for matte
                boxShadow: [
                  // Adjust shadow intensity based on style and press state
                  BoxShadow(
                    color: isMetallic
                        ? folderColor.withValues(alpha: _isPressed ? 0.35 : 0.45)
                        : primaryColor.withValues(alpha: _isPressed ? 0.2 : 0.25),
                    spreadRadius: isMetallic ? (_isPressed ? 0 : 1) : 0,
                    blurRadius: isMetallic ? (_isPressed ? 4 : 6) : (_isPressed ? 2 : 4),
                    offset: Offset(0, _isPressed ? 2 : (isMetallic ? 4 : 3)),
                  ),
                  // Secondary shadow for more depth
                  BoxShadow(
                    color: isDarkMode
                        ? Colors.black.withValues(alpha: isMetallic ? 0.25 : 0.18)
                        : Colors.black.withValues(alpha: isMetallic ? 0.1 : 0.07),
                    spreadRadius: 0,
                    blurRadius: isMetallic ? 6 : 3,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Subtle gloss overlay for metallic mode
                  if (isMetallic)
                    Positioned.fill(
                      child: AnimatedBuilder(
                        animation: _glossAnimation,
                        builder: (context, child) {
                          return Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24.0),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withValues(
                                    alpha: _isPressed ? 0.05 : 0.18,
                                  ),
                                  Colors.transparent,
                                  Colors.black.withValues(
                                    alpha: _isPressed ? 0.03 : 0.1,
                                  ),
                                ],
                                stops: const [0.0, 0.5, 1.0],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                  // Inner border effect for depth
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24.0),
                        border: Border.all(
                          color: Colors.white.withValues(
                            alpha: isMetallic
                                ? (colorBrightness > 0.5 ? 0.35 : 0.25)
                                : (colorBrightness > 0.5 ? 0.2 : 0.15),
                          ),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),

                  // Main content
                  Material(
                    color: Colors.transparent,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 20.0,
                      ),
                      child: Row(
                        children: [
                          // Icon container with enhanced styling
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(
                                  alpha: isMetallic
                                      ? (colorBrightness > 0.5 ? 0.45 : 0.3)
                                      : (colorBrightness > 0.5 ? 0.3 : 0.2)
                              ),
                              borderRadius: BorderRadius.circular(18.0),
                              boxShadow: [
                                if (isMetallic)
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.12),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Icon(
                                  timeBased ? _getTimeBasedIcon() : Icons.folder_rounded,
                                  size: 32,
                                  color: iconColor,
                                ),
                                // Assignment count badge overlay
                                if (stats['incomplete']! > 0)
                                  Positioned(
                                    right: 4,
                                    top: 4,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6.0,
                                        vertical: 4.0,
                                      ),
                                      decoration: BoxDecoration(
                                        color: widget.courseName == 'Overdue'
                                            ? (colorBrightness > 0.5
                                            ? Colors.red.shade700
                                            : Colors.red.shade500)
                                            : (colorBrightness > 0.5
                                            ? Colors.deepOrange.shade600
                                            : Colors.orange.shade400),
                                        borderRadius: BorderRadius.circular(10.0),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.25),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 20,
                                        minHeight: 18,
                                      ),
                                      child: Center(
                                        child: Text(
                                          stats['incomplete']! > 99
                                              ? '99+'
                                              : '${stats['incomplete']}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900,
                                            height: 1.0,
                                            letterSpacing: -0.3,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 20),

                          // Course/folder name and details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Title
                                Text(
                                  widget.courseName,
                                  style: TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w700,
                                    color: textColor,
                                    letterSpacing: 0.3,
                                    height: 1.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),

                                const SizedBox(height: 8),

                                // Subtitle - different for course vs time-based
                                if (timeBased) ...[
                                  // Time-based subtitle
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10.0,
                                          vertical: 4.0,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: colorBrightness > 0.5 ? 0.5 : 0.25,
                                          ),
                                          borderRadius: BorderRadius.circular(12.0),
                                          boxShadow: [
                                            if (isMetallic)
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.08),
                                                blurRadius: 2,
                                                offset: const Offset(0, 1),
                                              ),
                                          ],
                                        ),
                                        child: Text(
                                          _getTimeBasedSubtitle(stats),
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: textColor.withValues(alpha: 0.85),
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ] else ...[
                                  // Course subtitle
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10.0,
                                          vertical: 4.0,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: colorBrightness > 0.5 ? 0.45 : 0.25,
                                          ),
                                          borderRadius: BorderRadius.circular(12.0),
                                          boxShadow: [
                                            if (isMetallic)
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.08),
                                                blurRadius: 2,
                                                offset: const Offset(0, 1),
                                              ),
                                          ],
                                        ),
                                        child: Text(
                                          'Course ${widget.indexNum}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: textColor.withValues(alpha: 0.8),
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ),
                                      if (stats['total']! > 0) ...[
                                        const SizedBox(width: 12),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8.0,
                                            vertical: 4.0,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(
                                              alpha: colorBrightness > 0.5 ? 0.5 : 0.3,
                                            ),
                                            borderRadius: BorderRadius.circular(12.0),
                                            boxShadow: [
                                              if (isMetallic)
                                                BoxShadow(
                                                  color: Colors.black.withValues(alpha: 0.08),
                                                  blurRadius: 2,
                                                  offset: const Offset(0, 1),
                                                ),
                                            ],
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.check_circle_outline,
                                                size: 14,
                                                color: textColor.withValues(alpha: 0.7),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${stats['completed']}/${stats['total']}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  color: textColor.withValues(alpha: 0.8),
                                                  letterSpacing: 0.2,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),

                          const SizedBox(width: 12),

                          // Arrow indicator with enhanced styling
                          Container(
                            padding: const EdgeInsets.all(10.0),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(
                                  alpha: isMetallic
                                      ? (colorBrightness > 0.5 ? 0.4 : 0.25)
                                      : (colorBrightness > 0.5 ? 0.25 : 0.18)
                              ),
                              borderRadius: BorderRadius.circular(14.0),
                              boxShadow: [
                                if (isMetallic)
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                              ],
                            ),
                            child: Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 18,
                              color: iconColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Progress bar at the bottom (only for course folders with assignments)
                  if (!timeBased && stats['total']! > 0)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        height: 5,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(24.0),
                            bottomRight: Radius.circular(24.0),
                          ),
                          color: Colors.black.withValues(alpha: 0.12),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: stats['total']! > 0
                              ? stats['completed']! / stats['total']!
                              : 0.0,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(24.0),
                                bottomRight: Radius.circular(24.0),
                              ),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.green.shade300,
                                  Colors.green.shade500,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withValues(alpha: 0.4),
                                  blurRadius: 4,
                                  offset: const Offset(0, -1),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Decorative accent line at the bottom for time-based folders
                  if (timeBased)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        height: 5,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(24.0),
                            bottomRight: Radius.circular(24.0),
                          ),
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.3),
                              Colors.white.withValues(alpha: 0.15),
                              Colors.white.withValues(alpha: 0.3),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Helper method to calculate color brightness
  double _calculateBrightness(Color color) {
    return (0.587 * color.r + 0.299 * color.g + 0.114 * color.b) / 255;
  }
}