import 'dart:io';
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
  double w = 100.0;
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
    w = MediaQuery.of(context).size.width;
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
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 15),
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
            const SizedBox(height: 12),
            GlassImageCard(
              imageUrl:
                  'https://media.istockphoto.com/id/1330795444/vector/purple-satin-wavy-background-silk-fabric-texture-waves-and-swirl-drapery-abstract-pattern.jpg?s=612x612&w=0&k=20&c=K98gTLp9B8XAATv2aHtgCRai21UxPWyzlS2YnJ_GYs8=',
              text: 'Take live class',
              width: MediaQuery.sizeOf(context).width > 600 ? 130 : 100,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => teacherside(
                            classId: widget.classId,
                            className: widget.className,
                          )),
                );
              },
            ),
            SizedBox(
              height: 25,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GlassImageCard(
                  imageUrl:
                      'https://media.istockphoto.com/id/1330795444/vector/purple-satin-wavy-background-silk-fabric-texture-waves-and-swirl-drapery-abstract-pattern.jpg?s=612x612&w=0&k=20&c=K98gTLp9B8XAATv2aHtgCRai21UxPWyzlS2YnJ_GYs8=',
                  text: 'Manage Fees',
                  width: MediaQuery.sizeOf(context).width > 600 ? 130 : 100,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => teacher_fees(
                          classId: widget.classId,
                          className: widget.className,
                        ),
                      ),
                    );
                  },
                ),
                GlassImageCard(
                  imageUrl:
                      'https://media.istockphoto.com/id/1330795444/vector/purple-satin-wavy-background-silk-fabric-texture-waves-and-swirl-drapery-abstract-pattern.jpg?s=612x612&w=0&k=20&c=K98gTLp9B8XAATv2aHtgCRai21UxPWyzlS2YnJ_GYs8=',
                  text: 'Quiz',
                  width: MediaQuery.sizeOf(context).width > 600 ? 130 : 100,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TeacherQuizzesPage(
                          classname: widget.className,
                          classid: widget.classId,
                        ),
                      ),
                    );
                  },
                ),
                GlassImageCard(
                  imageUrl:
                      'https://media.istockphoto.com/id/1330795444/vector/purple-satin-wavy-background-silk-fabric-texture-waves-and-swirl-drapery-abstract-pattern.jpg?s=612x612&w=0&k=20&c=K98gTLp9B8XAATv2aHtgCRai21UxPWyzlS2YnJ_GYs8=',
                  text: 'Schedule',
                  width: MediaQuery.sizeOf(context).width > 600 ? 130 : 100,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ScheduleListPage(
                          classId: widget.classId,
                          className: widget.className,
                        ),
                      ),
                    );
                  },
                ),
                GlassImageCard(
                  imageUrl:
                      'https://media.istockphoto.com/id/1330795444/vector/purple-satin-wavy-background-silk-fabric-texture-waves-and-swirl-drapery-abstract-pattern.jpg?s=612x612&w=0&k=20&c=K98gTLp9B8XAATv2aHtgCRai21UxPWyzlS2YnJ_GYs8=',
                  text: 'Chat',
                  width: MediaQuery.sizeOf(context).width > 600 ? 130 : 100,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ClassChatPage(
                          classId: widget.classId,
                        ),
                      ),
                    );
                  },
                ),
              ],
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

class GlassImageCard extends StatelessWidget {
  final String imageUrl;
  final String text;
  final double width;
  final double aspectRatio;
  final double cornerRadius;
  final VoidCallback? onTap; // Callback for tap events

  const GlassImageCard({
    super.key,
    required this.imageUrl,
    required this.text,
    this.width = 30,
    this.aspectRatio = 2.0, // 1.0 makes it a square
    this.cornerRadius = 20.0,
    this.onTap, // Add onTap to the constructor
  });

  @override
  Widget build(BuildContext context) {
    // Wrap the entire card in a GestureDetector to make it tappable
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        // This clips the child (the Stack) to have rounded corners
        borderRadius: BorderRadius.circular(cornerRadius),
        child: SizedBox(
          width: width,
          child: AspectRatio(
            aspectRatio: aspectRatio,
            child: Stack(
              // Stack allows us to layer widgets on top of each other
              fit: StackFit.expand, // Makes children fill the Stack
              children: [
                // Layer 1: The Image
                Image.asset(
                  'assets/background.jpg',
                  fit: BoxFit.cover, // Ensures the image covers the whole area
                  // A loading builder is good practice for network images
                  // loadingBuilder: (context, child, loadingProgress) {
                  //   if (loadingProgress == null) return child;
                  //   return const Center(child: CircularProgressIndicator());
                  // },
                  // An error builder handles cases where the image fails to load
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    );
                  },
                ),

                // Layer 2: The Text
                Center(
                  // bottom: 2.0,
                  // left: 12.0,
                  // right: 12.0,
                  child: Text(
                    text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      shadows: <Shadow>[
                        Shadow(
                          offset: Offset(0.0, 1.0),
                          blurRadius: 4.0,
                          color: Color.fromARGB(150, 0, 0, 0),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                // Layer 3: The Shiny Glass Overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        // The gradient creates the "shiny" or "glare" effect
                        Colors.white.withOpacity(0.3),
                        Colors.white.withOpacity(0.05),
                      ],
                      stops: const [
                        0.0,
                        0.6
                      ], // Controls where the gradient transitions
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
