import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/class_essentials/theme.dart';
import 'assignment_viewer.dart'; // Import the new assignment viewer
import 'package:myapp/class_essentials/assignment_manager.dart';

class Folder extends ConsumerStatefulWidget {
  final String courseName;
  final int colorIndex;
  final VoidCallback? onTap;
  final AssignmentManager am;
  final int indexNum;

  const Folder({
    super.key,
    required this.courseName,
    required this.colorIndex,
    required this.am,
    required this.indexNum,
    this.onTap,
  });

  @override
  ConsumerState<Folder> createState() => _FolderState();
}

class _FolderState extends ConsumerState<Folder>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
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
      end: 0.95,
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

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AssignmentViewer(
          courseName: widget.courseName,
          courseColor: folderColor,
          am: widget.am,
          timeBased: timeBased,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(currentThemeProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Get color from theme's course colors, cycling through if needed
    final folderColor = theme.courseColors[widget.colorIndex % theme.courseColors.length];

    // Responsive height
    final folderHeight = screenWidth < 600 ? 120.0 : 140.0;

    // Create a more subtle darker variation for gradient
    final darkerColor = Color.fromARGB(
      folderColor.a.round(),
      (folderColor.r * 0.85).round(),
      (folderColor.g * 0.85).round(),
      (folderColor.b * 0.85).round(),
    );

    // Determine text and icon colors for optimal contrast
    final colorBrightness = _calculateBrightness(folderColor);
    final textColor = colorBrightness > 0.5
        ? Colors.black87
        : Colors.white;
    final iconColor = colorBrightness > 0.5
        ? Colors.black54
        : Colors.white70;

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
                borderRadius: BorderRadius.circular(20.0),
                // Simplified gradient - just main color to slightly darker
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    folderColor,
                    darkerColor,
                  ],
                ),
                boxShadow: [
                  // Primary shadow - reduced opacity
                  BoxShadow(
                    color: folderColor.withValues(alpha: 0.45),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 4),
                  ),
                  // Secondary shadow for subtle depth
                  BoxShadow(
                    color: isDarkMode
                        ? Colors.black.withValues(alpha: 0.2)
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 20.0,
                  ),
                  child: Row(
                    children: [
                      // Folder icon with simplified styling
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          // More solid background for icon
                          color: Colors.white.withValues(
                              alpha: colorBrightness > 0.5 ? 0.4 : 0.25
                          ),
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        child: Icon(
                          Icons.folder_rounded,
                          size: 28,
                          color: iconColor,
                        ),
                      ),

                      const SizedBox(width: 20),

                      // Course name and details
                      Expanded(
                        child:
                        (widget.courseName != 'Today' &&
                            widget.courseName != 'Tomorrow' &&
                            widget.courseName != 'This Week' &&
                            widget.courseName != 'Overdue' &&
                            widget.courseName != 'No Date/Other')
                        ?
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              widget.courseName,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: textColor,
                                letterSpacing: 0.3,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),

                            const SizedBox(height: 4),

                            // Subtle course indicator
                            Text(
                              'Course ${widget.indexNum}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: textColor.withValues(alpha: 0.75),
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ) :

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              widget.courseName,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: textColor,
                                letterSpacing: 0.3,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // Arrow indicator with simplified styling
                      Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(
                              alpha: colorBrightness > 0.5 ? 0.3 : 0.2
                          ),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: iconColor,
                        ),
                      ),
                    ],
                  ),
                ),
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