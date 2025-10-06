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
  bool autoHide;

   Folder({
    super.key,
    required this.courseName,
    required this.colorIndex,
    required this.am,
    required this.indexNum,
    required this.autoHide,
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
    print("State of autoHide: ${widget.autoHide}");
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AssignmentViewer(
          courseName: widget.courseName,
          courseColor: folderColor,
          am: widget.am,
          timeBased: timeBased,
          autoHide: widget.autoHide,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(currentThemeProvider);
    final isMetallic = ref.watch(metallicProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Get color from theme's course colors, cycling through if needed
    final folderColor = theme.courseColors[widget.colorIndex % theme.courseColors.length];

    // Responsive height
    final folderHeight = screenWidth < 600 ? 120.0 : 140.0;

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
                  // Adjust shadow intensity based on style
                  BoxShadow(
                    color: isMetallic
                        ? folderColor.withValues(alpha: 0.45)
                        : primaryColor.withValues(alpha: 0.25),
                    spreadRadius: isMetallic ? 1 : 0,
                    blurRadius: isMetallic ? 4 : 3,
                    offset: Offset(0, isMetallic ? 4 : 2),
                  ),
                  // Secondary shadow - more subtle for matte
                  BoxShadow(
                    color: isDarkMode
                        ? Colors.black.withValues(alpha: isMetallic ? 0.2 : 0.15)
                        : Colors.black.withValues(alpha: isMetallic ? 0.08 : 0.05),
                    spreadRadius: 0,
                    blurRadius: isMetallic ? 4 : 2,
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
                      // Folder icon with styling adjusted for metallic/matte
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(
                              alpha: isMetallic
                                  ? (colorBrightness > 0.5 ? 0.4 : 0.25)
                                  : (colorBrightness > 0.5 ? 0.25 : 0.15)
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

                      // Arrow indicator with styling adjusted for metallic/matte
                      Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(
                              alpha: isMetallic
                                  ? (colorBrightness > 0.5 ? 0.3 : 0.2)
                                  : (colorBrightness > 0.5 ? 0.2 : 0.15)
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