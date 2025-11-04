import '../class_essentials/assignment.dart';
import '../class_essentials/hive.dart';
import '../screens/settings.dart';
import '../screens/calendar.dart';
import 'package:flutter/material.dart';
import 'main.dart' as main_screen;
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:myapp/class_essentials/theme.dart';
import 'package:myapp/widgets/course_listview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/class_essentials/assignment_manager.dart';

final hiveManager = HiveBoxManager();
ThemeManager tm = ThemeManager();

class Central extends ConsumerWidget {
  final String? oauthToken;
  final String? oauthSecret;
  final bool coursesNeeded;

  const Central({
    super.key,
    this.oauthToken = "",
    this.oauthSecret = "",
    this.coursesNeeded = false,
  });

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Brightness b = MediaQuery.of(context).platformBrightness;
    return MaterialApp(
      title: 'Home Screen',
      debugShowCheckedModeBanner: false,
      theme: (b == Brightness.light)
          ? ref.watch(currentThemeProvider).lightTheme
          : ref
          .watch(currentThemeProvider)
          .darkTheme, //uses the theme manager to get the theme
      home: MyHomePage(
        oauthToken: oauthToken ?? "null",
        oauthSecret: oauthSecret ?? "null",
        coursesNeeded: coursesNeeded,
      ),
    );
  }
}

class MyHomePage extends ConsumerStatefulWidget {
  final String oauthToken;
  final String oauthSecret;
  final bool coursesNeeded;

  const MyHomePage({
    super.key,
    this.oauthToken = "",
    this.oauthSecret = "",
    this.coursesNeeded = false,
  });

  @override
  ConsumerState<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends ConsumerState<MyHomePage>
    with SingleTickerProviderStateMixin {
  int currentIndex = 0; //0 is dashboard, 1 is calendar, 2 is assignments, 3 is settings
  String testWords = "Hello World!";

  late String oToken;
  late String oSecret;
  late bool needCourses;

  int numCourses = 0;

  bool showHiddenAssignments = false;
  List<String> dismissedAssignments = [];
  List<Assignment> disA = [];
  List<Assignment> assignmentsPerDay = [];
  List<dynamic> courses = [];
  Map<String, List<Assignment>> assignments = {};

  final DateTime _focusedDay = DateTime.now();
  final DateTime _focusedDayW = DateTime.now();
  final DateTime _selectedDayW = DateTime.now();
  final DateTime _selectedDay = DateTime.now();

  late AnimationController _aAnimController;
  late Animation<Offset> _slideInAnimation;
  late Animation<Offset> _slideOutAnimation;

  late AssignmentManager am;

  bool autoHide = hiveManager.box.get("autoHide", defaultValue: false);
  bool visibleCalendar = hiveManager.box.get("visibleCalendar", defaultValue: false);



  @override
  void initState() {
    super.initState();
    _aAnimController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideOutAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.0),
      end: const Offset(-1.0, 0.0),
    ).animate(CurvedAnimation(
      parent: _aAnimController,
      curve: Curves.easeInOut,
    ));
    _slideInAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: const Offset(0.0, 0.0),
    ).animate(CurvedAnimation(
      parent: _aAnimController,
      curve: Curves.easeInOut,
    ));

    oToken = widget.oauthToken;
    oSecret = widget.oauthSecret;
    needCourses = widget.coursesNeeded;
    am = AssignmentManager(hiveManager, oToken, oSecret);
    courses =
        hiveManager.box.get("courses", defaultValue: ["No Courses Found!"]);
    if (courses == ["No Courses Found!"]) needCourses = true;
    initializeData();
  }

  @override
  void dispose() {
    _aAnimController.dispose();
    super.dispose();
  }

  Future<void> initializeData() async {
    try {
      /*
      if (!hiveManager.isInitialized) {
        await hiveManager.init();
      }
      */

      if (needCourses) {
        print("Getting courses...");
        await am.getCourses();
        setState(() {
          courses = hiveManager.box
              .get("courses", defaultValue: ["No Courses Found!"]);
        });
      }

      setState(() {
        dismissedAssignments =
            hiveManager.box.get("dismissedAssignments", defaultValue: [""]) ??
                [""];
        disA =
            hiveManager.box.get("disA", defaultValue: List<Assignment>.empty());
      });

      FlutterNativeSplash.remove();
      am.loadAssignments();
    } catch (e) {
      print("Error initializing data: $e");
      FlutterNativeSplash.remove();
    }
  }

  //returns to home screen and clears everything
  // Fixed logout function that properly clears data without closing the box
  Future<void> logout(BuildContext context) async {
    try {
      // Clear all data from Hive box instead of deleting it
      if (hiveManager.isInitialized) {
        await hiveManager.box.clear();
      }

      // Clear OAuth credentials
      main_screen.clearLogin();

      // Navigate to login screen and remove all previous routes
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const main_screen.MyApp(),
          ),
              (route) => false, // Remove all previous routes
        );
      }
    } catch (e) {
      print("Error during logout: $e");

      // Fallback navigation even if clearing fails
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const main_screen.MyApp(),
          ),
              (route) => false,
        );
      }
    }
  }

  List<Assignment> _getEventsToday(DateTime day) {
    List<Assignment> aTD = [];
    if (assignments.isNotEmpty) {
      for (List<Assignment> courseAssignments in assignments.values) {
        for (Assignment a in courseAssignments) {
          if (a.dueDate == null || a.dueDate.toString().trim().isEmpty) {
            continue;
          }
          try {
            DateTime dt = a.dueDate!;
            if (dt.day == day.day &&
                dt.month == day.month &&
                dt.year == dt.year) {
              aTD.add(a);
            }
          } catch (e) {
            print(
                "Error displaying events for day $day and assignment ${a.dueDate}: $e");
          }
        }
      }
    }
    return aTD;
  }

  int assignmentsNoDueDate() {
    int sum = 0;
    for (List<Assignment> courseAssignments in assignments.values) {
      for (Assignment a in courseAssignments) {
        if (a.dueDate == null) {
          sum++;
        }
      }
    }
    return sum;
  }

  DateTime _nearestSunday(DateTime today) {
    int current = today.weekday;
    if (current == 7) return today;
    int nextSunday = 7 - current;
    int lastSunday = current;
    if (nextSunday > lastSunday) {
      return today.subtract(Duration(days: lastSunday));
    } else {
      return today.add(Duration(days: nextSunday));
    }
  }

  void getAssignmentsForDay(DateTime day) {
    setState(() {
      assignmentsPerDay = _getEventsToday(day);
    });
    assignmentsPerDay = [];
    if (assignments.isNotEmpty) {
      for (List<Assignment> courseAssignments in assignments.values) {
        for (Assignment a in courseAssignments) {
          try {
            if (a.dueDate != null && a.dueDate!.day == day.day) {
              setState(() {
                assignmentsPerDay.add(a);
              });
            }
          } catch (e) {
            print("Error displaying events: $e");
          }
        }
      }
    }
  }

  Widget _chooseScreen(int num, double width, double height) {
    switch (num) {
      case 0:
        return CalendarScreen(
          getAssignmentsForDay: getAssignmentsForDay,
          getEventsToday: _getEventsToday,
          assignmentsPerDay: assignmentsPerDay,
          focusedDay: _focusedDay,
          currentColor: const Color.fromARGB(255, 140, 140, 140),
          am: am,
        );
    //return _calendarScreen();
      case 1:
        return CourseScreen(courses: courses, am: am, autoHide: hiveManager.box.get("autoHide", defaultValue: false));
      case 2:
        return SettingsScreen(
          logout: logout,
          hiveManager: hiveManager,
          autoHide: hiveManager.box.get("autoHide", defaultValue: false),
          visibleCalendar: visibleCalendar,
        );
      default:
        return CourseScreen(courses: courses, am: am, autoHide: hiveManager.box.get("autoHide", defaultValue: false));
    }
  }

  // Helper method to get current theme's primary color
  Color _getAccentColor() {
    final theme = ref.watch(currentThemeProvider);
    final isMetallic = ref.watch(metallicProvider);

    // Get the first color from the theme's gradient as the accent
    if (theme.courseColors.isNotEmpty) {
      final accentColor = theme.courseColors[0];

      if (!isMetallic) {
        // For matte themes, slightly desaturate
        final hsl = HSLColor.fromColor(accentColor);
        return hsl.withSaturation(hsl.saturation * 0.8).toColor();
      }
      return accentColor;
    }

    // Fallback to a default color
    return Colors.blue;
  }

  // Build a theme-aware decorative element for the app bar
  Widget _buildAppBarDecoration(bool isLightTheme, bool isMetallic) {
    final accentColor = _getAccentColor();

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: isMetallic
            ? LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor,
            accentColor.withValues(alpha: 0.7),
          ],
        )
            : null,
        color: isMetallic ? null : accentColor.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Gloss overlay for metallic
          if (isMetallic)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.25),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.1),
                    ],
                  ),
                ),
              ),
            ),
          // Icon in center
          Center(
            child:
              ImageIcon(
                  const AssetImage("assets/logoIcon.png"),
                  size: 50,
                  color: (Theme.of(context).brightness == Brightness.light) ? Colors.white : const Color.fromARGB(255, 15, 18, 20),
              ),

            /*Icon(
              Icons.scanner,
              color: Colors.white.withValues(alpha: 0.95),
              size: 26,
            ),*/
          ),
        ],
      ),
    );
  }

  // Get pending assignments count for notification badge
  int _getPendingAssignmentsCount() {
    try {
      final today = am.getAssignmentsDueToday();
      final overdue = am.getOverdueAssignments();

      final todayIncomplete = today.where((a) => !a.completed).length;
      final overdueIncomplete = overdue.where((a) => !a.completed).length;

      return todayIncomplete + overdueIncomplete;
    } catch (e) {
      return 0;
    }
  }

  /*
  ----------------------------------------------------------------------------
  ---------------------App Bar + Bottom Navigation Bar UI---------------------
  ----------------------------------------------------------------------------
   */

  @override
  Widget build(BuildContext context) {
    ThemeData theme =
    MediaQuery.of(context).platformBrightness == Brightness.dark &&
        ref.watch(currentThemeProvider).darkTheme != null
        ? ref.watch(currentThemeProvider).darkTheme!
        : ref.watch(currentThemeProvider).lightTheme;

    final isMetallic = ref.watch(metallicProvider);
    Color textColor = (theme.brightness == Brightness.dark)
        ? Colors.white.withValues(alpha: 0.85)
        : Colors.black.withValues(alpha: 0.85);
    final isLightTheme = theme.brightness == Brightness.light;
    final accentColor = _getAccentColor();
    final pendingCount = _getPendingAssignmentsCount();

    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: isLightTheme
          ? const Color.fromARGB(255, 248, 248, 245)
          : const Color.fromARGB(255, 30, 30, 40),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: isLightTheme
                    ? Colors.black.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            toolbarHeight: 72,
            leadingWidth: 72,
            // Left side - Theme-aware decorative element (or logo placeholder)
            leading: Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 12, bottom: 12),
              child: _buildAppBarDecoration(isLightTheme, isMetallic),
            ),
            // Center - App title with enhanced styling
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      textColor,
                      textColor.withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: const Text(
                    "SyncedIn",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: Colors.white, // Required for ShaderMask
                    ),
                  ),
                ),
                // Optional decorative dot
                Padding(
                  padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.5),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            centerTitle: true,
            // Right side - Notification badge (optional)
            /*
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0, top: 12, bottom: 12),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isLightTheme
                            ? Colors.black.withValues(alpha: 0.04)
                            : Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isLightTheme
                              ? Colors.black.withValues(alpha: 0.08)
                              : Colors.white.withValues(alpha: 0.1),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        Icons.notifications_outlined,
                        color: textColor.withValues(alpha: 0.7),
                        size: 24,
                      ),
                    ),
                    // Badge for pending assignments
                    if (pendingCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.red.shade400,
                                Colors.red.shade600,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withValues(alpha: 0.4),
                                blurRadius: 6,
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
                              pendingCount > 99 ? '99+' : '$pendingCount',
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
            ],*/
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
          backgroundColor: theme.colorScheme.surface,
          onDestinationSelected: (int index) {
            setState(() {
              currentIndex = index;
            });
          },
          indicatorColor: theme.indicatorColor,
          selectedIndex: currentIndex,
          destinations: const <Widget>[
            NavigationDestination(
              icon: Icon(Icons.calendar_month_rounded),
              label: "Calendar",
            ),
            NavigationDestination(
              icon: Icon(Icons.assignment_turned_in_rounded),
              label: "Assignments",
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_rounded),
              label: "Settings",
            )
          ]),
      body: _chooseScreen(currentIndex, width, height),
    );
  }
}