//import 'dart:async';
import 'package:flutter/material.dart';
import 'package:oauth1/oauth1.dart' as oauth1;
import 'main.dart' as main_screen;
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

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

//late final Box<dynamic> box;
final hiveManager = HiveBoxManager();


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await hiveManager.init();
  List<dynamic>? courses = hiveManager.box.get("courses", defaultValue: null);
  List<dynamic>? ids = hiveManager.box.get("ids", defaultValue: null);
  if(courses == null || ids == null){
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


class _MyHomePageState extends State<MyHomePage> {
  int currentIndex = 1; //0 is extra page, 1 is home page, 2 is settings
  String testWords = "Hello World!";
  late String oToken;
  late String oSecret;
  late bool needCourses;
  List<String> allTitles = [];

  @override
  void initState(){
    super.initState();
    oToken = widget.oauthToken;
    oSecret = widget.oauthSecret;
    needCourses = widget.coursesNeeded;
    if(needCourses){
      getCourses();
    }
  }

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
      Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      List<dynamic> sections = jsonResponse['section'];
      List<dynamic> courseTitles = sections.map((section) => section['course_title']).toList();
      List<dynamic> courseIds = sections.map((section) => section['id']).toList();
      await hiveManager.box.put("courses", courseTitles);
      await hiveManager.box.put("ids", courseIds);

    } catch(e){
      print("Error during API process: $e");
    }
  }

  //temp function
  void viewCourses()async{
    print("Fetching courses");
    if(!hiveManager.isInitialized){
      await hiveManager.init();
      await getCourses();
    }
    List<dynamic>? courses = hiveManager.box.get("ids");
    print("Fetched courses");
    setState((){
      if(courses != null && courses.isNotEmpty){
        testWords = courses.join(", ");
      } else{
        testWords = "No courses found.";
      }
    });
  }

  //also temp function
  void viewAssignments()async{
    if(!hiveManager.isInitialized){
      await hiveManager.init();
      await getCourses();
    }
    //List<String> allTitles = [];
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

      int start = 0;
      const int limit = 20;
      bool hasMore = true;
      List<String> currentTitles = [];

      while (hasMore) {
        final response = await authedClient.get(
            Uri.parse('https://api.schoology.com/v1/sections/${ids[2]}/assignments?start=$start&limit=$limit')
        );

        if (response.statusCode != 200) {
          throw Exception('Failed to fetch assignments: ${response.statusCode}');
        }

        Map<String, dynamic> data = jsonDecode(response.body);
        List<dynamic> assignments = data['assignment'];

        if (assignments.isEmpty) {
          hasMore = false;
        } else {
          // Extract only the titles from the assignments
          List<String> titles = assignments.map<String>((assignment) => assignment['title'] as String).toList();
          currentTitles.addAll(titles);
          start += limit;
        }
      }
      setState((){
        allTitles = currentTitles;
      });
      /*
      for(int i = 0; i < allTitles.length; i++){
        print(allTitles[i]);
      }
      */
    } catch(e){
      print("Something went wrong: Error $e");
    }
  }

  void logout(context){
    main_screen.clearLogin();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const main_screen.MyApp()),
    );
  }

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

  Widget _homeScreen(){
    return Center(
        child: Column(
            children: <Widget>[
              const SizedBox(
                height: 100,
              ),
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    IconButton(
                      icon: const Icon(Icons.assignment_ind_rounded),
                      onPressed: viewCourses,
                    ),
                    IconButton(
                      icon: const Icon(Icons.assignment_turned_in_rounded),
                      onPressed: viewAssignments,
                    ),
                    IconButton(
                        icon: const Icon(Icons.delete_forever_rounded),
                        onPressed: (){
                          setState((){
                            testWords = "";
                            allTitles = [];
                          });
                        }
                    ),
                  ]
              ),
              Text(
                "\n$testWords",
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 5, 0, 0),
                  child: allTitles.isEmpty ? const Center(child: Text("Nothing to display.")) :
                  ListView.builder(
                    itemCount: allTitles.length,
                    itemBuilder: (BuildContext context, int index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(
                          allTitles[index],
                          style: const TextStyle(fontSize: 16),
                        ),
                      );
                    }
                  )
                )
              )
            ]
        )
    );
  }

  Widget _settingsScreen(){
    return Center(
        child: Column(
            children: [
              const SizedBox(
                height: 100,
              ),
              const Text(
                  "Settings"
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded),
                onPressed: (){
                  logout(context);
                },
              ),
            ]
        )
    );
  }

  Widget _calendarScreen(){
    return const Center(
        child: Text(
            "Calendar (or smth else)"
        )
    );
  }

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
          indicatorColor: const Color.fromARGB(210, 175, 20, 210),
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
              icon: Icon(Icons.settings_accessibility_rounded),
              label: "Settings",
            ),
          ]
      ),
      //VVV MAIN CODE IS BELOW VVV
      body: _chooseScreen(currentIndex),

    );
  }
}



/*
class Section {
  final String id;
  final String courseTitle;
  final String courseId;

  Section({
    required this.id,
    required this.courseTitle,
    required this.courseId,
  });

  factory Section.fromJson(Map<String, dynamic> json) {
    return Section(
      id: json['id'],
      courseTitle: json['course_title'],
      courseId: json['course_id'],
    );
  }
}

// Usage
List<Section> sections = (jsonResponse['section'] as List)
    .map((sectionJson) => Section.fromJson(sectionJson))
    .toList();
 */