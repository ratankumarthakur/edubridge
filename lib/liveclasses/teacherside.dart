import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class teacherside extends StatefulWidget {
  const teacherside({super.key});

  @override
  State<teacherside> createState() => _teachersideState();
}

class _teachersideState extends State<teacherside> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(onPressed: (){
           launchUrl(Uri.parse('https://meet.google.com/landing'));
        },
        child: Text('open the class')),
      ),
    );
  }
}