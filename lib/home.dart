//import 'dart:async';
import 'package:flutter/material.dart';
import 'package:oauth1/oauth1.dart' as oauth1;
import 'main.dart' as main_screen;
//import 'dart:convert';

void main() {
  runApp(const Central());
}

class Central extends StatelessWidget {
  final String? oauthToken;
  final String? oauthSecret;
  const Central({
    super.key,
    this.oauthToken = "",
    this.oauthSecret = "",
  });


  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Home Screen',
      debugShowCheckedModeBanner: false,
      home: MyHomePage(oauthToken: oauthToken ?? "null", oauthSecret: oauthSecret ?? "null"),
    );
  }
}


class MyHomePage extends StatefulWidget {
  final String oauthToken;
  final String oauthSecret;

  const MyHomePage({
    super.key,
    this.oauthToken = "",
    this.oauthSecret = "",
  });

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}


class _MyHomePageState extends State<MyHomePage> {
  int currentIndex = 1; //0 is extra page, 1 is home page, 2 is settings
  String testWords = "Hello World!";
  late String oToken;
  late String oSecret;

  @override
  void initState(){
    super.initState();
    oToken = widget.oauthToken;
    oSecret = widget.oauthSecret;
  }

  Future<String> getAssignment()async{
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
      final response = await authedClient.get(
          Uri.parse('https://api.schoology.com/v1/users/25745219/sections')
      );
      /*
      final response = await authedClient.get(
          Uri.parse('https://api.schoology.com/v1/messages/inbox')
      );
      final response = await authedClient.get(
          Uri.parse('https://api.schoology.com/v1/app-user-info/api_uid')
      );
      uid: 25745219
      */
      setState((){
        testWords = response.body;
      });
    } catch(e){
      print("Error during API process: $e");
    }
    return "filler";
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
                      onPressed: getAssignment,
                    ),
                    IconButton(
                        icon: const Icon(Icons.delete_forever_rounded),
                        onPressed: (){
                          setState((){
                            testWords = "";
                          });
                        }
                    ),
                  ]
              ),
              Text(
                "\n$testWords",
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