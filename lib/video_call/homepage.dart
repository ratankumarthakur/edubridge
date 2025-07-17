import 'package:flutter/material.dart';
import 'package:tution/video_call/callpage.dart';

class HomePage extends StatelessWidget {
   HomePage({super.key});
 final textEditingController  = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.pink,),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(child: TextField(
              
            ),
            ),
            SizedBox(
              height: 20,
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CallPage(callID: textEditingController.text),
                  ),
                );
              },
              child: Text("Join Call"),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              ),
            ),
            
        ],
        )
        ));
      
  }
}