import 'dart:io';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:chat/authentication/LoginPage.dart';
import 'package:chat/chat/latest.dart';
import 'package:chat/homepages/teacher/class/schedule_list.dart';
import 'package:chat/liveclasses/teacherside.dart';
import 'package:chat/quiz/quizlist.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:chat/fees/teacher_fees.dart';

class TeacherClassActionsPage extends StatefulWidget {
  final String classId;
  final String className;

  const TeacherClassActionsPage({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  State<TeacherClassActionsPage> createState() =>
      _TeacherClassActionsPageState();
}

class _TeacherClassActionsPageState extends State<TeacherClassActionsPage> {
  File? _imageFile;
  Uint8List? _imageData;
  String _imageButtonText = 'Upload Timetable Image';
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
    if (doc.exists &&
        doc.data() != null &&
        doc.data()!['timetableUrl'] != null) {
      setState(() {
        _imageUrl = doc.data()!['timetableUrl'];
        _imageButtonText = 'Change Timetable';
      });
    }
  }

  Future<void> _pickImageAndUpload() async {
    setState(() {
      _isUploading = true;
      _errorMsg = null;
    });

    XFile? pickedFile;

    if (kIsWeb) {
      pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        _imageData = await pickedFile.readAsBytes();
      }
    } else {
      pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        _imageFile = File(pickedFile.path);
      }
    }

    if (pickedFile == null) {
      setState(() {
        _isUploading = false;
        _errorMsg = 'No file selected.';
      });
      return;
    }

    setState(() {
      _imageButtonText = 'Change Timetable';
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    final fileName = 'timetables/${widget.classId}.jpg';
    final ref = FirebaseStorage.instance.ref().child(fileName);
    UploadTask uploadTask;

    if (kIsWeb && _imageData != null) {
      uploadTask =
          ref.putData(_imageData!, SettableMetadata(contentType: 'image/jpeg'));
    } else if (_imageFile != null) {
      uploadTask = ref.putFile(_imageFile!);
    } else {
      setState(() {
        _isUploading = false;
        _errorMsg = 'No file selected.';
      });
      return;
    }

    uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) async {
      final progress = snapshot.bytesTransferred / snapshot.totalBytes;
      setState(() => _uploadProgress = progress);

      if (snapshot.state == TaskState.success) {
        final downloadUrl = await ref.getDownloadURL();
        // Store the download URL in Firestore under the class document
        await FirebaseFirestore.instance
            .collection('classes')
            .doc(widget.classId)
            .update({'timetableUrl': downloadUrl});
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
          _imageUrl = downloadUrl;
        });
      }
    }, onError: (e) {
      setState(() {
        _isUploading = false;
        _errorMsg = 'Upload error: $e';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.className,
          style: TextStyle(fontSize: 18),
        ),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.people),
              tooltip: 'Show Students',
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),
      endDrawer: Drawer(
        backgroundColor: Colors.purple.shade100,
        child: SafeArea(
          child: FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('classes')
                .doc(widget.classId)
                .get(),
            builder: (context, classSnap) {
              if (!classSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final classData =
                  classSnap.data!.data() as Map<String, dynamic>? ?? {};
              final List joinedUids = classData['joinedStudents'] ?? [];
              final List blockedUids = classData['blockedStudents'] ?? [];
              if (joinedUids.isEmpty) {
                return const Center(child: Text('No students joined yet.'));
              }
              return ListView(
                children: [
                  DrawerHeader(
                    curve: Curves.easeInOut,
                    child: Center(
                        child: Column(
                      children: [
                        Image.network(
                            height: 110,
                            'https://img.pikbest.com/png-images/20240526/teenage-student-cartoon-illustration-_10584503.png!sw800'),
                        Text('Students in this Class',
                            style:
                                TextStyle(fontSize: 15, color: Colors.purple)),
                      ],
                    )),
                  ),
                  ...joinedUids.map<Widget>((uid) {
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
                          .get(),
                      builder: (context, userSnap) {
                        if (!userSnap.hasData) {
                          return const ListTile(title: Text('Loading...'));
                        }
                        if (!userSnap.data!.exists) {
                          return ListTile(
                              title: Text(uid),
                              subtitle: const Text('No user data'));
                        }
                        final user =
                            userSnap.data!.data() as Map<String, dynamic>;
                        final isBlocked = blockedUids.contains(uid);
                        return Card(
                          color: Colors.purple.shade50,
                          elevation: 10,
                          shadowColor: Colors.purple,
                          child: ListTile(
                            leading: const Icon(
                              Icons.person,
                              color: Colors.purple,
                            ),
                            title: Text(user['name'] ?? 'No Name'),
                            subtitle: Text(
                              user['email'] ?? '',
                              style:
                                  TextStyle(fontSize: 9, color: Colors.purple),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    isBlocked ? Icons.lock_open : Icons.block,
                                    color:
                                        isBlocked ? Colors.green : Colors.red,
                                  ),
                                  tooltip: isBlocked ? 'Unblock' : 'Block',
                                  onPressed: () async {
                                    final ref = FirebaseFirestore.instance
                                        .collection('classes')
                                        .doc(widget.classId);
                                    if (isBlocked) {
                                      await ref.update({
                                        'blockedStudents':
                                            FieldValue.arrayRemove([uid])
                                      });
                                    } else {
                                      await ref.set({
                                        'blockedStudents':
                                            FieldValue.arrayUnion([uid])
                                      }, SetOptions(merge: true));
                                    }
                                    setState(() {});
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  tooltip: 'Remove from class',
                                  onPressed: () async {
                                    final ref = FirebaseFirestore.instance
                                        .collection('classes')
                                        .doc(widget.classId);
                                    await ref.update({
                                      'joinedStudents':
                                          FieldValue.arrayRemove([uid]),
                                      'blockedStudents':
                                          FieldValue.arrayRemove([uid])
                                    });
                                    setState(() {});
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }).toList(),
                ],
              );
            },
          ),
        ),
      ),
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
                  Center(
                    child: buildTimetableDisplay(),
                  ),
                  const SizedBox(height: 20),
                  if (_isUploading)
                    Column(
                      children: [
                        LinearProgressIndicator(value: _uploadProgress),
                        const SizedBox(height: 8),
                        Text(
                            '${(_uploadProgress * 100).toStringAsFixed(0)}% uploaded'),
                      ],
                    ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isUploading ? null : _pickImageAndUpload,
                    child: Text(_imageButtonText),
                  ),
                  if (_errorMsg != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        _errorMsg!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
            ),
            //const SizedBox(height: 12),
            TextButton(
                          onPressed: () => Get.to(() =>teacherside() ),
                          child: Text(
                            'Live class',
                            style: TextStyle(
                                color: Colors.green,
                                fontSize: 20,
                                fontWeight: FontWeight.bold),
                          )),
                          TextButton(
                          onPressed: () => Get.to(() => teacher_fees(
                              classId: widget.classId,
                              className: widget.className,
                            ),),
                          child: Text(
                            'Fees',
                            style: TextStyle(
                                color: const Color.fromARGB(255, 2, 75, 4),
                                fontSize: 20,
                                fontWeight: FontWeight.bold),
                          )),
                          TextButton(
                          onPressed: ()  => Get.to(() => TeacherQuizzesPage(
                            classname: widget.className,
                            classid: widget.classId,
                          ),),
                          child: Text(
                            'Quiz',
                            style: TextStyle(
                                color: Color.fromARGB(255, 2, 75, 4),
                                fontSize: 20,
                                fontWeight: FontWeight.bold),
                          )),
                          TextButton(
                        
                          onPressed: ()  => Get.to(() => ScheduleListPage(
                                classId: widget.classId, className: widget.className, ),),  
                          child: Text(
                      
                            'Schedule',
                            style: TextStyle(
                                color: const Color.fromARGB(255, 24, 94, 35),
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          )),
                          TextButton(
                        
                          onPressed: ()  => Get.to(() => ClassChatPage(
                                classId: widget.classId, ),),  
                          child: Text(
                      
                            'Chat',
                            style: TextStyle(
                                color: const Color.fromARGB(255, 24, 94, 35),
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          )),

            // Stack(
            //   children: [
            //     Image.asset('assets/class.png'),
            //     Positioned(
            //         left: 147,
            //         top: 100,
            //         child: AvatarGlow(
            //           glowColor: const Color.fromARGB(255, 4, 245, 12),
            //           glowCount: 3,
                      
            //           child: TextButton(
            //               onPressed: () => Get.to(() =>teacherside() ),
            //               child: Text(
            //                 'Live class',
            //                 style: TextStyle(
            //                     color: Colors.white,
            //                     fontSize: 20,
            //                     fontWeight: FontWeight.bold),
            //               )),
            //         )),
            //         Positioned(
            //         left: 30,
            //         top: 210,
            //         child: AvatarGlow(
            //           glowColor: const Color.fromARGB(255, 248, 183, 4),
            //           child: TextButton(
            //               onPressed: () => Get.to(() => teacher_fees(
            //                   classId: widget.classId,
            //                   className: widget.className,
            //                 ),),
            //               child: Text(
            //                 'Fees',
            //                 style: TextStyle(
            //                     color: const Color.fromARGB(255, 2, 75, 4),
            //                     fontSize: 20,
            //                     fontWeight: FontWeight.bold),
            //               )),
            //         )),
            //     Positioned(
            //         left: 165,
            //         top: 210,
            //         child: AvatarGlow(
            //           glowColor: const Color.fromARGB(255, 248, 183, 4),
            //           child: TextButton(
            //               onPressed: ()  => Get.to(() => TeacherQuizzesPage(
            //                 classname: widget.className,
            //                 classid: widget.classId,
            //               ),),
            //               child: Text(
            //                 'Quiz',
            //                 style: TextStyle(
            //                     color: Color.fromARGB(255, 2, 75, 4),
            //                     fontSize: 20,
            //                     fontWeight: FontWeight.bold),
            //               )),
            //         )),
                
            //     Positioned(
            //         right: 19,
            //         top: 210,
            //         child: AvatarGlow(
            //           glowColor:  const Color.fromARGB(255, 248, 183, 4),
            //           child: TextButton(
                        
            //               onPressed: ()  => Get.to(() => ClassChatPage(
            //                     classId: widget.classId, ),),  
            //               child: Text(
                      
            //                 'Schedule',
            //                 style: TextStyle(
            //                     color: const Color.fromARGB(255, 24, 94, 35),
            //                     fontSize: 18,
            //                     fontWeight: FontWeight.bold),
            //               )),
            //         )),
                        
                
                
            //   ],
            // )
          ],
        ),
      ),
    );
  }
  Widget glowingButton({
  required String label,
  required Widget targetPage,
  double top = 100,
  double left = 0,
  double? right,
  Color glowColor = const Color.fromARGB(255, 4, 245, 12),
  Color textColor = Colors.white,
}) {
  return Positioned(
    top: top,
    left: left,
    right: right ?? 0,
    child: AvatarGlow(
      glowColor: glowColor,
      glowRadiusFactor: 1.2,
      //endRadius: 70,
      child: TextButton(
        onPressed: () => Get.to(() => targetPage),
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'nunito',
          ),
        ),
      ),
    ),
  );
}
  Widget gradientImageButton({
    required String label,
    required Widget targetPage,
    double height = 50,
  }) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        height: height,
        width: 200,
        decoration: BoxDecoration(
          image: const DecorationImage(
            image: AssetImage('assets/background.jpg'),
            fit: BoxFit.cover,
          ),
          borderRadius: BorderRadius.circular(32),
        ),
        child: Stack(
          children: [
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
              ),
            ),
            // Transparent button on top
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32),
                ),
              ),
              onPressed: () => Get.to(() => targetPage),
              child: Center(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    fontFamily: 'nunito-regular',
                  ),
                ),
              ),
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

