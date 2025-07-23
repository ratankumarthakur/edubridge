import 'dart:io';
import 'dart:typed_data';

// import 'package:chat/homepages/schedule_list.dart';
import 'package:chat/chat/latest.dart';
import 'package:chat/fees/student_fees.dart';
import 'package:chat/homepages/student/home/class/schedule_show_list.dart';
import 'package:chat/homepages/teacher/class/teacher_class_actions_page.dart';
import 'package:chat/quiz/student_quiz.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class StudentClassActionPage extends StatefulWidget {
  final String classId;
  final String className;

  const StudentClassActionPage({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  State<StudentClassActionPage> createState() => _StudentClassActionPageState();
}

class _StudentClassActionPageState extends State<StudentClassActionPage> {
  File? _imageFile;
  Uint8List? _imageData;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _imageUrl;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _fetchTimetableUrl();
  }

  Future<void> _fetchTimetableUrl() async {
    final doc = await FirebaseFirestore.instance
        .collection('classes')
        .doc(widget.classId)
        .get();
    if (doc.exists && doc.data() != null && doc.data()!['timetableUrl'] != null) {
      setState(() {
        _imageUrl = doc.data()!['timetableUrl'];
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.className)),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 30),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.lightBlue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  buildTimetableDisplay(),
                  
                  
                ],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.videocam,color: Colors.white,),
              label: const Text('Live Class'),
              onPressed: () {
                // TODO: Implement live class feature
                 launchUrl(Uri.parse('https://meet.google.com/landing'));
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.attach_money,color: Colors.white,),
              label: const Text('Fees'),
              onPressed: () {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User not logged in!')),
                  );
                  return;
                }
                final studentUid = user.uid;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => student_fees(
                      classId: widget.classId,
                      className: widget.className,
                      studentUid: studentUid,
                    ),
                  ),
                );
                // TODO: Implement fees feature
              },
            ),
            const SizedBox(height: 16),
            
            
            ElevatedButton.icon(
              icon: const Icon(Icons.chat,color: Colors.white,),
              label: const Text('Chat'),
              
                 onPressed: ()  => Get.to(() => ClassChatPage(
                                classId: widget.classId, ),),  
              
            ),
            SizedBox(height: 20,),
            ElevatedButton.icon(
              icon: const Icon(Icons.schedule,color: Colors.white,),
              label: const Text('See Schedule'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ScheduleShowListPage(classId: widget.classId, className: widget.className),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.quiz_rounded,color: Colors.white,),
              label: const Text('Prticipate in a quiz'),
              
                 onPressed: (){ Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AvailableQuizzesScreen(),
                  ),
                ); }
              
            ),
          ],
        ),
      ),
    );
  }
Widget buildTimetableDisplay() {
    final imageWidget = kIsWeb && _imageData != null
        ? Image.memory(_imageData!, fit: BoxFit.fill)
        : _imageFile != null
            ? Image.file(_imageFile!, fit: BoxFit.fill)
            : _imageUrl != null
                ? Image.network(
                    _imageUrl!,
                    fit: BoxFit.fill,
                    errorBuilder: (context, error, stackTrace) => const Text(
                        'Failed to load image',
                        style: TextStyle(color: Colors.red)),
                  )
                : const Text('Timetable not uploaded yet');

    final hasImage =
        _imageData != null || _imageFile != null || _imageUrl != null;

    return Padding(
      padding: const EdgeInsets.all(1.0),
      child: hasImage
          ? Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 4)),
                ],
              ),
              clipBehavior: Clip.hardEdge,
              child: imageWidget,
            )
          : DottedBorder(
              color: Colors.grey.shade700,
              strokeWidth: 2,
              dashPattern: const [6, 3],
              borderType: BorderType.RRect,
              radius: const Radius.circular(12),
              child: SizedBox(
                height: 150,
                width: double.infinity,
                child: Center(child: imageWidget),
              ),
            ),
    );
  }
}