  import 'dart:async';
  import 'package:flutter/material.dart';
  import 'package:oauth1/oauth1.dart' as oauth1;
  import 'package:google_fonts/google_fonts.dart';
  import 'home.dart' as home;
  import 'package:url_launcher/url_launcher.dart';
  import 'package:flutter_secure_storage/flutter_secure_storage.dart';
  import 'package:flutter_native_splash/flutter_native_splash.dart';
  import 'package:myapp/class_essentials/theme.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:myapp/class_essentials/assignment_manager.dart';

  const storage = FlutterSecureStorage();

  void main() async {
    WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
    FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

    String? token = await storage.read(key: 'oauth_token');
    String? secret = await storage.read(key: 'oauth_secret');
    if (secret == null || token == null){
      FlutterNativeSplash.remove();
      runApp(
        const ProviderScope(
          child: MyApp()
        )
      );
    } else{
      runApp(
        ProviderScope(
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            home: home.Central(
              oauthToken: token,
              oauthSecret: secret,
            ),
          )
        )
      );
    }
  }

  void clearLogin() async {
    await storage.deleteAll();
  }
  
  class MyApp extends StatelessWidget {
    const MyApp({super.key});
  
    // This widget is the root of your application.
    @override
    Widget build(BuildContext context) {
      return MaterialApp(
        title: 'Schoology API Test',
        debugShowCheckedModeBanner: false,
        theme: basic.lightTheme,
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
    final Completer<void> _buttonCompleter = Completer<void>();
    var url = "url thingy";
  
    @override
    void dispose() {
      super.dispose();
    }
  
    @override
    void initState() {
      super.initState();
    }

    Future<void> stepOne() async {
      setState((){
        url = "First half of log in";
      });
      try {
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
        final oauth1.Authorization auth = oauth1.Authorization(clientCredentials, platform);
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
  
          // Using Coppell ISD's domain for authorization for now
          final authUri = 'https://$schoologyDomain/oauth/authorize?oauth_token=$tempToken';
          print('Open with your browser: $authUri');
          if(!await launchUrl(Uri.parse(authUri))){
            throw Exception('Could not open log-in link. Please check your settings, firewall, etc. for restrictions your device may have on opening urls.');
          }
  
          //break before continuing
          if(!_buttonCompleter.isCompleted){
            await _buttonCompleter.future;
          }
  
          final tempClient = oauth1.Client(
              platform.signatureMethod,
              clientCredentials,
              tempCredentials
          );
  
          final accessTokenResponse = await tempClient.get(
              Uri.parse('https://api.schoology.com/v1/oauth/access_token?oauth_verifier=$tempToken')
          );
  
          print('Access token response: ${accessTokenResponse.body}');
  
          final accessParams = Uri(query: accessTokenResponse.body).queryParameters;
          final accessToken = accessParams['oauth_token'];
          final accessTokenSecret = accessParams['oauth_token_secret'];
  
          if (accessToken == null || accessTokenSecret == null) {
            throw Exception('Failed to parse access tokens from response');
          }

          /*
          final authedClient = oauth1.Client(
              platform.signatureMethod,
              clientCredentials,
              oauth1.Credentials(accessToken, accessTokenSecret)
          );
  
          final response = await authedClient.get(
              Uri.parse('https://api.schoology.com/v1/messages/inbox')
          );
          print('API Response: ${response.body}');
          */
          await storage.write(key: 'oauth_token', value: accessToken);
          await storage.write(key: 'oauth_secret', value: accessTokenSecret);
          //after logging in, "restart" the app to trigger the main function's conditional checking for log-in credentials
          runApp(
            ProviderScope(
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                home: home.Central(
                  oauthToken: accessToken,
                  oauthSecret: accessTokenSecret,
                ),
              ))
          );
  
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
              Text(
                url,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              //this button must be pressed to complete log-in. don't remove it.
              IconButton(
                onPressed: (){
                  _buttonCompleter.complete();
                },
                icon: const Icon(
                  Icons.login_rounded,
                  color: Color.fromARGB(255, 175, 20, 210),
                )
              )
            ],
          ),
        ),
        //start log in process - must be completed with the other button
        floatingActionButton: FloatingActionButton(
          onPressed: stepOne,
          tooltip: 'Log in',
          child: const Icon(
            Icons.arrow_forward_ios_rounded,
            color: Color.fromARGB(255, 175, 20, 210),
          ),
        ),
        // This trailing comma makes auto-formatting nicer for build methods.
      );
    }
  }