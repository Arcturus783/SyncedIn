import 'dart:async';
import 'package:flutter/material.dart';
//import 'package:http/http.dart' as http;
import 'package:oauth1/oauth1.dart' as auth;
import 'package:google_fonts/google_fonts.dart';
import 'home.dart' as home;
//import 'package:url_launcher/url_launcher.dart';
//import 'dart:convert';

/*
IMPORTANT - Here are the fonts we're using.
Title/App Name: Rubik
Secondary Headings (Like on the app bar): Figtree
Paragraph/"Standard text": Ubuntu
*/

void main() {
  runApp(const MyApp());

  runApp(
    const MaterialApp(
      home: home.Central(),
    )
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Schoology API Test',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 8, 16, 137)),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _counter = 0;
  var url = "url thingy";
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController callbackController = TextEditingController();

  late auth.AuthorizationResponse tempCredentials;
  late auth.Authorization authorize;

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    callbackController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initializeOAuth();
  }

  /*
  void login() async {
    try {
      tempCredentials = await authorize
          .requestTemporaryCredentials('coolSchoologyAPIapp://oauth-callback');
      var authorizationUrl = authorize
          .getResourceOwnerAuthorizationURI(tempCredentials.credentials.token);

      setState(() {
        url = 'Please open this URL in a browser: $authorizationUrl';
      });

      //await launchUrl(Uri.parse(authorizationUrl));
      //this line is commented because of issues with the launchUrl library

      // The user will now be redirected to the Schoology authorization page
      // After authorization, your app should be opened again via the callback URL
    } catch (e) {
      setState(() {
        url = 'Error occurred during login: $e';
      });
    }
  }
  */

  void _initializeOAuth() {
    var platform = auth.Platform(
      'https://api.schoology.com/v1/oauth/request_token',
      'https://www.schoology.com/oauth/authorize',
      'https://api.schoology.com/v1/oauth/access_token',
      auth.SignatureMethods.hmacSha1,
    );
    var clientCredentials = auth.ClientCredentials(
        '4228fad5be57913f4a288c71007cce38066a6a9c6',
        'f16aa4e412861b3be29314970e2740ba');

    authorize = auth.Authorization(clientCredentials, platform);
  }

  /*
  void _handleCallback() async {
    String callbackUrl = callbackController.text;
    try {
      var uri = Uri.parse(callbackUrl);
      var verifier = uri.queryParameters['oauth_verifier'];

      if (verifier != null) {
        try {
          var accessToken = await authorize.requestTokenCredentials(
              tempCredentials.credentials, verifier);

          setState(() {
            url =
                'Successfully logged in! Token: ${accessToken.credentials.token}';
          });
        } catch (e) {
          setState(() {
            url = 'Error getting access token: $e';
          });
        }
      } else {
        setState(() {
          url = 'No verifier received in the callback URL';
        });
      }
    } catch (e) {
      setState(() {
        url = 'Error processing callback URL: $e';
      });
    }
  }
  */

  void startAuth() async {
    try {
      var res = await authorize.requestTemporaryCredentials('oob');
      String authUrl =
          authorize.getResourceOwnerAuthorizationURI(res.credentials.token);

      setState(() {
        url = authUrl;
      });

      String verifier = await getVerifier();

      var tokenCredentials =
          await authorize.requestTokenCredentials(res.credentials, verifier);

      setState(() {
        url = 'Authenticated! Token: ${tokenCredentials.credentials.token}';
      });
    } catch (e) {
      setState(() {
        url = 'Error: $e';
      });
    }
  }

  Future<String> getVerifier() async {
    // This is just a placeholder. In a real app, you'd get this from user input after they authorize.
    Completer<String> completer = Completer<String>();
    bool waitingForVerifier = true;

    callbackController.addListener(() {
      if (callbackController.text.isNotEmpty && waitingForVerifier) {
        waitingForVerifier = false;
        completer.complete(callbackController.text);
      }
    });

    String verifier = await completer.future;

    return verifier;
  }

//-------------------------------------------------------------\\
//------Back End^------------------------vFront End------------\\
//-------------------------------------------------------------\\

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 175, 20, 210),
        title: Text('Insert App Name',
            style: GoogleFonts.figtree(
                textStyle: const TextStyle(
                    color: Color.fromARGB(255, 241, 241, 241)))),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Username',
              ),
            ),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Password',
              ),
            ),
            TextField(
                controller: callbackController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Callback URL',
                )),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Text(
              url,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          startAuth();
          //login();
          //_handleCallback();
        },
        tooltip: 'Log in',
        child: const Icon(
          Icons.arrow_forward_ios_rounded,
          color: Color.fromARGB(255, 175, 20, 210),
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}





//k 4228fad5be57913f4a288c71007cce38066a6a9c6
//s f16aa4e412861b3be29314970e2740ba


