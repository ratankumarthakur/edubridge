import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
class studentside extends StatefulWidget {
  const studentside({super.key});

  @override
  State<studentside> createState() => _studentsideState();
}

class _studentsideState extends State<studentside> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(onPressed: (){
           launchUrl(Uri.parse('https://meet.google.com/landing'));
        },
        child: Text('join live class')),
    ));
  }
}