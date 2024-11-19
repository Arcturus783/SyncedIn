import 'dart:async';
import 'package:flutter/material.dart';
//import 'package:http/http.dart' as http;
import 'package:oauth1/oauth1.dart' as oauth1;
import 'package:google_fonts/google_fonts.dart';
//import 'home.dart' as home;
//import 'package:url_launcher/url_launcher.dart';
//import 'dart:convert';
import 'dart:io';


void main() {
  runApp(const MyApp());
  /*
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: home.Central(),
    )
  );
  */
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
  }

  Future<void> stepOne() async {
    try {
      print("point A");
      const String SCHOOLOGY_DOMAIN = "schoology.coppellisd.com";
      final oauth1.Platform platform = oauth1.Platform(
          'https://api.schoology.com/v1/oauth/request_token',
          'https://$SCHOOLOGY_DOMAIN/oauth/authorize',
          'https://api.schoology.com/v1/oauth/access_token',
          oauth1.SignatureMethods.hmacSha1
      );
      const String consK = "4228fad5be57913f4a288c71007cce38066a6a9c6";
      const String consS = "f16aa4e412861b3be29314970e2740ba";
      final oauth1.ClientCredentials clientCredentials = oauth1.ClientCredentials(consK, consS);
      final oauth1.Authorization auth = oauth1.Authorization(clientCredentials, platform);
      print("point B");
      try {
        final oauth1.Client client = oauth1.Client(
            platform.signatureMethod,
            clientCredentials,
            null
        );
        final requestTokenResponse = await client.get(
            Uri.parse('https://api.schoology.com/v1/oauth/request_token')
        );

        final params = Uri(query: requestTokenResponse.body).queryParameters;
        final tempToken = params['oauth_token'];
        final tempTokenSecret = params['oauth_token_secret'];

        if (tempToken == null || tempTokenSecret == null) {
          throw Exception('Failed to parse oauth tokens from response');
        }

        final tempCredentials = oauth1.Credentials(tempToken, tempTokenSecret);
        print("point C");

        // Using Coppell ISD's domain for authorization
        final authUri = 'https://$SCHOOLOGY_DOMAIN/oauth/authorize?oauth_token=$tempToken';
        print('Open with your browser: $authUri');

        print('After authorizing, enter the verifier (PIN):');
        String verifier = stdin.readLineSync() ?? '';

        final tempClient = oauth1.Client(
            platform.signatureMethod,
            clientCredentials,
            tempCredentials
        );

        final accessTokenResponse = await tempClient.get(
            Uri.parse('https://api.schoology.com/v1/oauth/access_token?oauth_verifier=$verifier')
        );

        print('Access token response: ${accessTokenResponse.body}');

        final accessParams = Uri(query: accessTokenResponse.body).queryParameters;
        final accessToken = accessParams['oauth_token'];
        final accessTokenSecret = accessParams['oauth_token_secret'];

        if (accessToken == null || accessTokenSecret == null) {
          throw Exception('Failed to parse access tokens from response');
        }

        final authedClient = oauth1.Client(
            platform.signatureMethod,
            clientCredentials,
            oauth1.Credentials(accessToken, accessTokenSecret)
        );

        final response = await authedClient.get(
            Uri.parse('https://api.schoology.com/v1/messages/inbox')
        );
        print('API Response: ${response.body}');

      } catch (e, stackTrace) {
        print('Error during OAuth process: $e');
        print('Detailed stack trace:');
        print(stackTrace.toString().split('\n').take(10).join('\n'));
      }

    } catch (e) {
      print('Error during OAuth setup: $e');
      print('Stack trace: ${StackTrace.current}');
    }
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
        onPressed: stepOne,
        tooltip: 'Log in',
        child: const Icon(
          Icons.arrow_forward_ios_rounded,
          color: Color.fromARGB(255, 175, 20, 210),
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}