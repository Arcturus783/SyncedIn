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
  int currentIndex = 1; //0 is extra page, 1 is home page, 2 is settings
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
        return CourseScreen(courses: courses, am: am, autoHide: autoHide,);
      case 2:
        return SettingsScreen(
          logout: logout,
          hiveManager: hiveManager,
          autoHide: autoHide,
          visibleCalendar: visibleCalendar,
        );
      default:
        return CourseScreen(
          courses: courses,
          am: am,
          autoHide: autoHide,
        );
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
    Color textColor = (theme.brightness == Brightness.dark)
        ? Colors.white.withValues(alpha: 0.85)
        : Colors.black.withValues(alpha: 0.85);
    final isLightTheme = theme.brightness == Brightness.light;

    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: isLightTheme
          ? const Color.fromARGB(255, 248, 248, 245)
          : const Color.fromARGB(255, 30, 30, 40),
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        title: const Text("App Name"),
        titleTextStyle: TextStyle(
          fontSize: 32,
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.w700,
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
