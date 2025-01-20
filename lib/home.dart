//import 'dart:async';
import 'package:flutter/material.dart';
import 'package:oauth1/oauth1.dart' as oauth1;
import 'main.dart' as main_screen;
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:table_calendar/table_calendar.dart';

//this class manages our library storing data like course names and IDs
class HiveBoxManager{
  static final HiveBoxManager _instance= HiveBoxManager._internal();
  late final Box<dynamic> box;
  bool _initialized = false;

  factory HiveBoxManager(){
    return _instance;
  }

  HiveBoxManager._internal();

  Future<void> init() async{
    if(!_initialized){
      await Hive.initFlutter();
      box = await Hive.openBox("userData");
      _initialized = true;
    }
  }
  bool get isInitialized => _initialized;
}

final hiveManager = HiveBoxManager();


void main() async {
  WidgetsFlutterBinding.ensureInitialized(); //VERY IMPORTANT!
  await hiveManager.init();
  List<dynamic>? courses = hiveManager.box.get("courses", defaultValue: null);
  List<dynamic>? ids = hiveManager.box.get("ids", defaultValue: null);
  String? name = hiveManager.box.get("name", defaultValue: null);
  if(courses == null || ids == null || name == null){
    runApp(const Central(coursesNeeded: true,));
  } else{
    runApp(const Central());
  }
}

class Central extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Home Screen',
      debugShowCheckedModeBanner: false,
      home: MyHomePage(oauthToken: oauthToken ?? "null", oauthSecret: oauthSecret ?? "null", coursesNeeded: coursesNeeded,),
    );
  }
}


class MyHomePage extends StatefulWidget {
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
  State<MyHomePage> createState() => _MyHomePageState();
}

class Assignment{
  final String title;
  final String dueDate;
  final String type;

  Assignment({
    required this.title,
    required this.dueDate,
    required this.type,
  });
}

class _MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin{
  int currentIndex = 1; //0 is extra page, 1 is home page, 2 is settings
  String testWords = "Hello World!";

  late String oToken;
  late String oSecret;
  late bool needCourses;

  int numCourses = 0;
  String name = "";

  bool showHiddenAssignments = false;
  List<String> dismissedAssignments = [];
  List<Assignment> assignmentsPerDay = [];
  Map<String, List<Assignment>> assignments = {};

  Color currentColor = const Color.fromARGB(195, 230, 135, 245);

  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  //keep transparency 195 for consistency - mess around with everything else
  List<Color> colorOptions = [const Color.fromARGB(195, 239, 23, 23), const Color.fromARGB(195, 225, 50, 25),
    const Color.fromARGB(195, 220, 210, 60), const Color.fromARGB(195, 230, 135, 245)];

  late AnimationController _aAnimController;
  late Animation<Offset> _slideInAnimation;
  late Animation<Offset> _slideOutAnimation;

  @override
  void initState(){
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
    initializeData();
    /*
    if(needCourses){
      getCourses();
    }
    setName();
    viewAssignments();
     */
  }

  @override
  void dispose(){
    _aAnimController.dispose();
    super.dispose();
  }

  //initializes everything ideally
  Future<void> initializeData()async{
      try{
        if(!hiveManager.isInitialized){
          await hiveManager.init();
        }
        if(needCourses){
          await getCourses();
        }
        setState((){
          name = hiveManager.box.get("name", defaultValue: "");
        });
        setState((){
          dismissedAssignments = hiveManager.box.get("dismissedAssignments", defaultValue: [""]);
        });
        setState((){
          currentColor = Color.fromARGB(195, hiveManager.box.get("redColor", defaultValue: 230), hiveManager.box.get("blueColor", defaultValue: 135), hiveManager.box.get("greenColor", defaultValue: 245));
        });
        FlutterNativeSplash.remove();
        viewAssignments();
      } catch(e){
        print("Error initializing data: $e");
      }
  }

  //this initializes the course names and IDs so we can get assignments for each course
  //ideally doesn't run because it gets it from storage, but if value isn't found then this will run (as seen in main method)
  Future<void> getCourses()async{
    try{
      const String schoologyDomain = "schoology.coppellisd.com";
      final oauth1.Platform platform = oauth1.Platform(
          'https://api.schoology.com/v1/oauth/request_token',
          'https://$schoologyDomain/oauth/authorize',
          'https://api.schoology.com/v1/oauth/access_token',
          oauth1.SignatureMethods.hmacSha1
      );
      const String consK = "4228fad5be57913f4a288c71007cce38066a6a9c6";
      const String consS = "f16aa4e412861b3be29314970e2740ba";
      final oauth1.ClientCredentials clientCredentials = oauth1.ClientCredentials(consK, consS);
      final authedClient = oauth1.Client(
          platform.signatureMethod,
          clientCredentials,
          oauth1.Credentials(oToken, oSecret)
      );
      final uidResponse = await authedClient.get(
          Uri.parse('https://api.schoology.com/v1/app-user-info/api_uid')
      );
      Map<String, dynamic> uidJson = jsonDecode(uidResponse.body);
      dynamic uid = uidJson['api_uid'];
      final response = await authedClient.get(
          Uri.parse('https://api.schoology.com/v1/users/$uid/sections')
      );
      final nameResponse = await authedClient.get(
        Uri.parse('https://api.schoology.com/v1/users/$uid')
      );
      Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      Map<String, dynamic> jsonNameResponse = jsonDecode(nameResponse.body);
      List<dynamic> sections = jsonResponse['section'];
      List<dynamic> courseTitles = sections.map((section) => section['course_title']).toList();
      List<dynamic> courseIds = sections.map((section) => section['id']).toList();
      await hiveManager.box.put("courses", courseTitles);
      await hiveManager.box.put("ids", courseIds);
      await hiveManager.box.put("name", jsonNameResponse['name_first']);
      setState((){
        numCourses = courseTitles.length;
        name = " ${jsonNameResponse['name_display']}";
      });
    } catch(e){
      print("Error during API process: $e");
    }
  }

  //temporary function in case of API issues
  void viewCourses()async{
    print("Fetching courses");
    if(!hiveManager.isInitialized){
      await hiveManager.init();
      await getCourses();
    }
    List<dynamic>? courses = hiveManager.box.get("courses");
    print("Fetched courses");
    setState((){
      if(courses != null && courses.isNotEmpty){
        testWords = courses.join(", ");
      } else{
        testWords = "No courses found.";
      }
    });
  }

  void setName()async{
    if(!hiveManager.isInitialized){
      await hiveManager.init();
    }
    setState((){
      name = hiveManager.box.get("name", defaultValue:"");
    });
  }

  void changeColors(Color col)async{
    setState((){
      currentColor = Color.fromARGB(195, col.red, col.blue, col.green);
    });
    if(!hiveManager.isInitialized){
      await hiveManager.init();
    }
    hiveManager.box.put("redColor", col.red);
    hiveManager.box.put("blueColor", col.blue);
    hiveManager.box.put("greenColor", col.green);
  }

  //also temporary function
  void viewAssignments()async{
    try {
      List<dynamic> ids = hiveManager.box.get("ids");
      const String schoologyDomain = "schoology.coppellisd.com";
      final oauth1.Platform platform = oauth1.Platform(
          'https://api.schoology.com/v1/oauth/request_token',
          'https://$schoologyDomain/oauth/authorize',
          'https://api.schoology.com/v1/oauth/access_token',
          oauth1.SignatureMethods.hmacSha1);
      const String consK = "4228fad5be57913f4a288c71007cce38066a6a9c6";
      const String consS = "f16aa4e412861b3be29314970e2740ba";
      final oauth1.ClientCredentials clientCredentials =
          oauth1.ClientCredentials(consK, consS);
      final authedClient = oauth1.Client(platform.signatureMethod,
          clientCredentials, oauth1.Credentials(oToken, oSecret));
      //DateTime today = DateTime.now();

      List<Future<void>> fetchFutures = [];
      List<dynamic> courses = hiveManager.box.get("courses");
      for(int a = 0; a < ids.length; a++){
        fetchFutures.add(_fetchAssignments(ids[a], courses[a], authedClient));
      }

      await Future.wait(fetchFutures);
      /*
      for (int x = 0; x < ids.length; x++) {
        int start = 0;
        const int limit = 20;
        bool hasMore = true;
        List<Assignment> courseAssignments = [];
        var courseName = hiveManager.box.get("courses")[x];

        // Process all assignments for this course
        while (hasMore) {
          final response = await authedClient.get(
              Uri.parse('https://api.schoology.com/v1/sections/${ids[x]}/assignments?start=$start&limit=$limit')
          );

          if (response.statusCode != 200) {
            throw Exception('Failed to fetch assignments: ${response.statusCode}');
          }

          Map<String, dynamic> data = jsonDecode(response.body);
          List<dynamic> assignments = data['assignment'];

          if (assignments.isEmpty) {
            hasMore = false;
          } else {
            for(var assignment in assignments){
              courseAssignments.add(Assignment(
                title: assignment["title"],
                dueDate: assignment['due'],
                type: assignment['type'],
              ));
            }
            /*
            setState(() {
              allTitles.addAll(assignments.map<String>((assignment) => assignment['title'] as String));
              allDates.addAll(assignments.map<String>((assignment) => assignment['due'] as String));
              allDueToday.addAll(assignments.map<bool>((assignment) => (DateTime.parse(assignment['due']).day == today.day) ? true : false));
            });
             */
            start += limit;
          }
          //delay prevents rate limiting
          await Future.delayed(const Duration(milliseconds: 20));
        }
       setState((){
         assignments[courseName] = courseAssignments;
       });
      }

       */
    } catch(e){
      print("Something went wrong: Error $e");
    }
  }

  Future<void> _fetchAssignments(String id, String courseName, oauth1.Client authedClient)async{
    int start = 0;
    const int limit = 20;
    bool hasMore = true;
    List<Assignment> courseAssignments = [];


    while (hasMore) {
      final response = await authedClient.get(
          Uri.parse(
              'https://api.schoology.com/v1/sections/$id/assignments?start=$start&limit=$limit')
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch assignments: ${response.statusCode}');
      }

      Map<String, dynamic> data = jsonDecode(response.body);
      List<dynamic> assignments = data['assignment'];

      if (assignments.isEmpty) {
        hasMore = false;
      } else {
        courseAssignments.addAll(assignments.map((a) =>
            Assignment(
              title: a["title"],
              dueDate: a['due'],
              type: a['type'],
            )));
        start += limit;
      }

      await Future.delayed(const Duration(milliseconds: 50));
    }
    setState(() {
      assignments[courseName] = courseAssignments;
    });
  }
  //returns to home screen and clears everything
  void logout(context){
    hiveManager.box.deleteFromDisk();
    main_screen.clearLogin();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const main_screen.MyApp()),
    );
  }

  List<Assignment> _getEventsToday(DateTime day){
    List<Assignment> aTD = [];
    if(assignments.isNotEmpty) {
      for (List<Assignment> courseAssignments in assignments.values) {
        for (Assignment a in courseAssignments) {
          try {
            if (DateTime
                .parse(a.dueDate.trim())
                .day == day.day) {
              aTD.add(a);
            }
          } catch (e) {
            print("Error displaying events: $e");
          }
        }
      }
    }
    return aTD;
  }

  void getAssignmentsForDay(DateTime day){
    setState((){
      assignmentsPerDay = _getEventsToday(day);
    });
    assignmentsPerDay = [];
    if(assignments.isNotEmpty){
      for(List<Assignment> courseAssignments in assignments.values){
        for(Assignment a in courseAssignments){
          try{
            if(DateTime.parse(a.dueDate.trim()).day == day.day){
              setState((){
                assignmentsPerDay.add(a);
              });
            }
          } catch(e){
            print("Error displaying events: $e");
          }
        }
      }
    }
  }

  //just helps organize our code
  Widget _chooseScreen(int num){
    switch(num){
      case 0:
        return _calendarScreen();
      case 1:
        return _homeScreen();
      case 2:
        return _settingsScreen();
      default:
        return _homeScreen();
    }
  }

  /*
  ----------------------------------------------------------------------------
  -------------------------------Home Screen UI-------------------------------
  ----------------------------------------------------------------------------
   */

  Widget _homeScreen() {
    return Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 25, 0, 10),
                child: Text(
                    "Hello $name!",
                    textAlign: TextAlign.left,
                    style: const TextStyle(
                      fontSize: 30,
                    )
                ),
              ),
              Padding(
                  padding: const EdgeInsets.fromLTRB(0, 18, 10, 0),
                  child: IconButton(
                      icon: const Icon(Icons.hide_image_rounded),
                      iconSize: 30,
                      onPressed: (){
                          setState((){
                            showHiddenAssignments = !showHiddenAssignments;
                            if(showHiddenAssignments){
                              _aAnimController.forward();
                            } else{
                              _aAnimController.reverse();
                            }
                          });
                      }
                  )
              ),
            ]
          ),
          // Main content area - lists all the courses AND assignments (think of the itemBuilders like nested for loops)

          Expanded(
            child: Stack(
              children: [
                SlideTransition(
                  position: _slideOutAnimation,
                child: assignments.isEmpty
                ? const Center(child: Text("No assignments to display"))
                : ListView.builder(
              itemCount: assignments.length,
              //this iterates and displays each individual course
              itemBuilder: (BuildContext context, int courseIndex) {
                String courseTitle = assignments.keys.elementAt(courseIndex);
                List<Assignment> courseAssignments = assignments[courseTitle] ?? [];
                // Pre-filter assignments
                List<Assignment> currentMonthAssignments = courseAssignments.where((assignment) {
                  if (assignment.dueDate.trim().isEmpty) return true;
                  try {
                    DateTime dueDate = DateTime.parse(assignment.dueDate);
                    DateTime now = DateTime.now();
                    return dueDate.day == now.day || dueDate == DateTime(now.year, now.month, now.day + 1);
                  } catch (e) {
                    return true; // Include assignments with invalid dates
                  }
                }).toList();

                return Card(
                    margin: const EdgeInsets.all(8.0),
                    //color: const Color.fromARGB(195, 230, 135, 245),
                    color: currentColor,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            courseTitle,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        if (currentMonthAssignments.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(child: Text("No assignments for this course")),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: currentMonthAssignments.length,
                            itemBuilder: (BuildContext context, int index) {
                              Assignment assignment = currentMonthAssignments[index];
                              if(!dismissedAssignments.contains(assignment.title)){
                                if (assignment.dueDate
                                    .trim()
                                    .isEmpty) {
                                  //this allows the user to slide and remove an assignment
                                  return Dismissible(
                                      key: Key(assignment.title),
                                      direction: DismissDirection.endToStart,
                                      onDismissed: (direction) {
                                        setState(() {
                                          currentMonthAssignments.removeAt(
                                              index); //remove from active list
                                          assignments[courseTitle]?.removeAt(
                                              index); //remove from assignments for the course list (??)
                                          dismissedAssignments.add(
                                              assignment.title);
                                          hiveManager.box.put(
                                              "dismissedAssignments",
                                              dismissedAssignments);
                                        });
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                '${assignment.title} removed'),
                                            action: SnackBarAction(
                                              label: 'UNDO',
                                              onPressed: () {
                                                setState(() {
                                                  currentMonthAssignments
                                                      .insert(
                                                      index, assignment);
                                                  assignments[courseTitle]
                                                      ?.insert(
                                                      index, assignment);
                                                  dismissedAssignments.remove(
                                                      assignment.title);
                                                  hiveManager.box.put(
                                                      "dismissedAssignments",
                                                      dismissedAssignments);
                                                });
                                              },
                                            ),
                                          ),
                                        );
                                      },
                                      child: Card(
                                          color: const Color.fromARGB(
                                              225, 252, 252, 252),
                                          child: ListTile(
                                            title: Text(
                                              assignment.title,
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                            subtitle: const Text("No Due Date"),
                                            trailing: (assignment.type ==
                                                "assessment")
                                                ? const Icon(
                                                Icons.assessment_rounded)
                                                : (assignment.type ==
                                                "discussion")
                                                ? const Icon(
                                                Icons.message_rounded)
                                                : const Icon(
                                                Icons.assignment_rounded),
                                            contentPadding: const EdgeInsets
                                                .symmetric(
                                                horizontal: 16.0,
                                                vertical: 4.0
                                            ),
                                          )
                                      )
                                  );
                                }
                                try {
                                  return Dismissible(
                                  key: Key(assignment.title),
                                  direction: DismissDirection.endToStart,
                                  onDismissed: (direction) {
                                    setState(() {
                                      currentMonthAssignments.removeAt(
                                          index); //remove from active list
                                      assignments[courseTitle]?.removeAt(
                                          index); //remove from assignments for the course list (??)
                                      dismissedAssignments.add(
                                          assignment.title);
                                      hiveManager.box.put(
                                          "dismissedAssignments",
                                          dismissedAssignments);
                                    });
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            '${assignment.title} removed'),
                                        action: SnackBarAction(
                                          label: 'UNDO',
                                          onPressed: () {
                                            setState(() {
                                              currentMonthAssignments.insert(index, assignment);
                                              assignments[courseTitle]?.insert(index, assignment);
                                              dismissedAssignments.remove(assignment.title);
                                              hiveManager.box.put("dismissedAssignments", dismissedAssignments);
                                            });
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                    child: Card(
                                        color: const Color.fromARGB(
                                            225, 252, 252, 252),
                                        child: ListTile(
                                          title: Text(
                                            assignment.title,
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                          subtitle: Text(
                                              "Due: ${assignment.dueDate.split(
                                                  " ")[0]}\n${assignment.dueDate
                                                  .split(" ")[1]}"),
                                          trailing: (assignment.type ==
                                              "assessment") ? const Tooltip(
                                            message: "Assessment",
                                            child: Icon(
                                                Icons.assessment_rounded),) :
                                          (assignment.type == "discussion")
                                              ? const Tooltip(
                                              message: "Discussion",
                                              child: Icon(Icons.message_rounded))
                                              :
                                          const Tooltip(message: "Assignment",
                                              child: Icon(
                                                  Icons.assignment_rounded)),
                                          contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 16.0, vertical: 4.0),
                                        )
                                    )
                                  );
                                } catch (e) {
                                  return Tooltip(
                                      message: assignment.dueDate,
                                      child: Card(
                                          child: ListTile(
                                            title: Text(assignment.title),
                                            subtitle: const Text(
                                                "Invalid Due Date"),
                                            trailing: (assignment.type ==
                                                "assessment")
                                                ? const Icon(
                                                Icons.assessment_rounded)
                                                : (assignment.type ==
                                                "discussion")
                                                ? const Icon(
                                                Icons.message_rounded)
                                                : const Icon(
                                                Icons.assignment_rounded),
                                            contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 16.0,
                                                vertical: 4.0),
                                          )
                                      )
                                  );
                                }
                              } else{
                                return Container();
                              }
                            },
                          ),
                      ],
                    ),
                );
              },
            ),
                ),
                SlideTransition(
                  position: _slideInAnimation,
                  child: Expanded(
                    child: Center(
                        child: dismissedAssignments.isEmpty || (dismissedAssignments.length == 1 && dismissedAssignments[0] == "") ?
                        const Text("No dismissed assignments")
                        : ListView.builder(
                          itemCount: dismissedAssignments.length,
                          itemBuilder: (BuildContext context, int dismissedIndex){
                            String assignment = dismissedAssignments[dismissedIndex];
                            if(assignment.trim().isNotEmpty) {
                                  return Dismissible(
                                    key: Key(assignment),
                                    direction: DismissDirection.endToStart,
                                    onDismissed: (direction) {
                                        setState((){
                                          dismissedAssignments.remove(assignment);
                                          hiveManager.box.put("dismissedAssignments", dismissedAssignments);
                                        });
                                    },
                                    child: Card(
                                    color: const Color.fromARGB(
                                        200, 244, 244, 244),
                                    child: ListTile(
                                      title: Text(
                                        assignment,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                      //subtitle: Text("Due: ${assignment.dueDate.split(" ")[0]}\n${assignment.dueDate.split(" ")[1]}"),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 16.0,
                                              vertical: 4.0),
                                    )
                                  )
                                 );
                                } else{
                                  return Container();
                                }
                              }
                        )
                    )
                  )
                )
              ]
          )
          )
        ],
      );
  }

  /*
  ----------------------------------------------------------------------------
  -----------------------------Settings Screen UI-----------------------------
  ----------------------------------------------------------------------------
   */

  Widget _settingsScreen(){
    return Center(
        child: Column(
            children: [
              const SizedBox(
                height: 100,
              ),
              const Text(
                  "Settings (button below is to logout)"
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded),
                onPressed: (){
                  logout(context);
                },
              ),
              const Text(
                "Color Picker (saves color choice); Add like 8-16 choices",
              ),
              const SizedBox(height: 50),
              Expanded(
                child: BlockPicker(
                  pickerColor: currentColor,
                  availableColors: colorOptions,
                  onColorChanged: changeColors,
                )
              )
            ]
        )
    );
  }

  /*
  ----------------------------------------------------------------------------
  -----------------------------Calendar Screen UI-----------------------------
  ----------------------------------------------------------------------------
   */
  //documentation for calendar package
  //https://pub.dev/documentation/table_calendar/latest/
  //examples: https://github.com/aleksanderwozniak/table_calendar/tree/master/example/lib/pages
  Widget _calendarScreen(){
    CalendarFormat calendarFormat = CalendarFormat.month;
    return Column(
        children: <Widget>[
          TableCalendar(
            availableCalendarFormats: const {CalendarFormat.month: "Month"},
            headerStyle: const HeaderStyle(
              titleCentered: true,
              titleTextStyle: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
              )
            ),
            firstDay: DateTime.utc(2025, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            eventLoader: _getEventsToday,
            selectedDayPredicate: (day){
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              getAssignmentsForDay(selectedDay);
              setState(() {
                _focusedDay = focusedDay;
                _selectedDay = selectedDay;
              });
            },
            calendarFormat: calendarFormat,
            onFormatChanged: (format) {
              setState(() {
                calendarFormat = format;
              });
            },
            calendarStyle: CalendarStyle(
              //you can specify a font too for the calendar text here
              defaultTextStyle: const TextStyle(color: Color.fromARGB(255, 5, 5, 5)),
              markerSize: 7, //size of an event dot
              markersMaxCount: 3, //default is 4, looks crowded if they have 4+ assignments
              todayDecoration: BoxDecoration(
                color: currentColor,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: currentColor,
                shape: BoxShape.circle,
              ),
            ),
        ),
          const SizedBox(height: 30),
          Expanded(
            child: ListView.builder(
              itemCount: assignmentsPerDay.length,
              itemBuilder: (BuildContext context, int index){
                //return Text("1. ${assignmentsPerDay[index].title}");
                Assignment assignment = assignmentsPerDay[index];
                return Card(
                    color: const Color.fromARGB(225, 252, 252, 252),
                    child: ListTile(
                      title: Text(
                        assignment.title,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      subtitle: Text("Due: ${assignment.dueDate.split(" ")[0]}\n${assignment.dueDate.split(" ")[1]}"),
                      trailing: (assignment.type == "assessment") ? const Tooltip(message: "Assessment", child: Icon(Icons.assessment_rounded),):
                      (assignment.type == "discussion") ? const Tooltip(message: "Discussion", child: Icon(Icons.message_rounded)) :
                      const Tooltip(message: "Assignment", child: Icon(Icons.assignment_rounded)),
                      contentPadding:
                      const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 4.0),
                    )
                );
              }
            )
          )

        ]
    );
  }


  /*
  ----------------------------------------------------------------------------
  ---------------------App Bar + Bottom Navigation Bar UI---------------------
  ----------------------------------------------------------------------------
   */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(248, 253, 253, 253),
      appBar: AppBar(
        //this puts it at the left of the AppBar. Swap for a logo later instead of icon.
        leading: const Icon(
          Icons.logo_dev_rounded,
          size: 40,
        ),
        backgroundColor: const Color.fromARGB(180, 225, 225, 225),
        title: const Text(
            "App Name",
            style: TextStyle(
              fontSize: 20,
            )
        ),
      ),
      bottomNavigationBar: NavigationBar(
          backgroundColor: const Color.fromARGB(150, 230, 230, 230),
          onDestinationSelected: (int index) {
            setState((){
              currentIndex = index;
            });
          },
          indicatorColor: currentColor,//const Color.fromARGB(210, 175, 20, 210),
          selectedIndex: currentIndex,
          destinations: const <Widget>[
            NavigationDestination(
              icon: Icon(Icons.calendar_month_rounded),
              label: "Calendar", //temporary label, can be removed
            ),
            NavigationDestination(
              icon: Icon(Icons.assignment_turned_in_rounded),
              label: "Assignments",
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_applications_rounded),
              label: "Settings",
            ),
          ]
      ),
      body: _chooseScreen(currentIndex),
    );
  }
}

//this is the monstrosity that displays assignments - just a copy if it's needed (*cough* if Claude destroys the normal version)
/*
return Center(
        child: Column(
          children: <Widget>[
              const SizedBox(height: 60),
              const Text("Calendar Screen - for now just loads all assignments"),
            Expanded(
              child: assignments.isEmpty
                  ? const Center(child: Text("No assignments to display"))
                  : ListView.builder(
                itemCount: assignments.length,
                itemBuilder: (BuildContext context, int courseIndex) {
                  String courseTitle = assignments.keys.elementAt(courseIndex);
                  List<Assignment> courseAssignments = assignments[courseTitle] ?? [];

                  return Card(
                    margin: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            courseTitle,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        if (courseAssignments.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(child: Text("No assignments for this course")),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: courseAssignments.length,
                            itemBuilder: (BuildContext context, int index) {
                              Assignment assignment = courseAssignments[index];
                              return Tooltip(
                                  message: assignment.dueDate,
                                  child: ListTile(
                                    title: Text(assignment.title),
                                    subtitle:
                                    Text("Due: ${assignment.dueDate}"),
                                    contentPadding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 16.0, vertical: 4.0),
                                  )
                              );
                            },
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ]
        )
    );
 */