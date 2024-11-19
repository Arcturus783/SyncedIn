//import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
//import 'package:flutter_neumorphic/flutter_neumorphic.dart';
//import 'package:oauth1/oauth1.dart' as auth;

/*
IMPORTANT - Here are the fonts in use.
Title/App Name: Rubik
Secondary Headings (Like on the app bar): Figtree
Paragraph/"Standard text": Ubuntu
*/

void main() {
  runApp(const Central());
}

class Central extends StatelessWidget {
  const Central({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Home Screen',
      debugShowCheckedModeBanner: false,

      home: MyHomePage(),
    );
  }
}





class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}




class _MyHomePageState extends State<MyHomePage> {

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
        backgroundColor: Colors.transparent,
        //VVV MAIN CODE IS BELOW VVV
        body: const Center(

        )

    );
  }
}
