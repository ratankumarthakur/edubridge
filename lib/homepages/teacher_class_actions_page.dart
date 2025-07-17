import 'dart:io';
import 'dart:typed_data';

import 'package:chat/homepages/schedule_list.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dotted_border/dotted_border.dart';
// import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
  State<TeacherClassActionsPage> createState() => _TeacherClassActionsPageState();
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
    if (doc.exists && doc.data() != null && doc.data()!['timetableUrl'] != null) {
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
      uploadTask = ref.putData(_imageData!, SettableMetadata(contentType: 'image/jpeg'));
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
        title: Text(widget.className),
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
        child: SafeArea(
          child: FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('classes').doc(widget.classId).get(),
            builder: (context, classSnap) {
              if (!classSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final classData = classSnap.data!.data() as Map<String, dynamic>? ?? {};
              final List joinedUids = classData['joinedStudents'] ?? [];
              final List blockedUids = classData['blockedStudents'] ?? [];
              if (joinedUids.isEmpty) {
                return const Center(child: Text('No students joined.'));
              }
              return ListView(
                children: [
                  const DrawerHeader(
                    child: Center(child: Text('Students in this Class', style: TextStyle(fontSize: 18))),
                  ),
                  ...joinedUids.map<Widget>((uid) {
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
                      builder: (context, userSnap) {
                        if (!userSnap.hasData) {
                          return const ListTile(title: Text('Loading...'));
                        }
                        if (!userSnap.data!.exists) {
                          return ListTile(title: Text(uid), subtitle: const Text('No user data'));
                        }
                        final user = userSnap.data!.data() as Map<String, dynamic>;
                        final isBlocked = blockedUids.contains(uid);
                        return ListTile(
                          leading: const Icon(Icons.person),
                          title: Text(user['name'] ?? 'No Name'),
                          subtitle: Text(user['email'] ?? ''),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  isBlocked ? Icons.lock_open : Icons.block,
                                  color: isBlocked ? Colors.green : Colors.red,
                                ),
                                tooltip: isBlocked ? 'Unblock' : 'Block',
                                onPressed: () async {
                                  final ref = FirebaseFirestore.instance.collection('classes').doc(widget.classId);
                                  if (isBlocked) {
                                    await ref.update({
                                      'blockedStudents': FieldValue.arrayRemove([uid])
                                    });
                                  } else {
                                    await ref.set({
                                      'blockedStudents': FieldValue.arrayUnion([uid])
                                    }, SetOptions(merge: true));
                                  }
                                  setState(() {});
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.grey),
                                tooltip: 'Remove from class',
                                onPressed: () async {
                                  final ref = FirebaseFirestore.instance.collection('classes').doc(widget.classId);
                                  await ref.update({
                                    'joinedStudents': FieldValue.arrayRemove([uid]),
                                    'blockedStudents': FieldValue.arrayRemove([uid])
                                  });
                                  setState(() {});
                                },
                              ),
                            ],
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
                    child: SizedBox(
                      height: 200,
                      width: 200,
                      child: DottedBorder(
                        color: Colors.grey.shade700,
                        strokeWidth: 2,
                        dashPattern: const [6, 3],
                        borderType: BorderType.RRect,
                        radius: const Radius.circular(12),
                        child: Center(
                          child: kIsWeb && _imageData != null
                              ? Image.memory(_imageData!, fit: BoxFit.cover)
                              : _imageFile != null
                                  ? Image.file(_imageFile!, fit: BoxFit.cover)
                                  : (_imageUrl != null
                                      ? Image.network(
                                          _imageUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) =>
                                              const Text('Failed to load image', style: TextStyle(color: Colors.red)),
                                        )
                                      : const Text('Timetable not uploaded yet')),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_isUploading)
                    Column(
                      children: [
                        LinearProgressIndicator(value: _uploadProgress),
                        const SizedBox(height: 8),
                        Text('${(_uploadProgress * 100).toStringAsFixed(0)}% uploaded'),
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
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.videocam),
              label: const Text('Live Class'),
              onPressed: () {
                // TODO: Implement live class feature
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.attach_money),
              label: const Text('Fees'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => teacher_fees(
                      classId: widget.classId,
                      className: widget.className,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.schedule),
              label: const Text('Set Schedule'),
              onPressed: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ScheduleListPage(classId: widget.classId, className: widget.className),
    ),
  );
},
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.check_circle),
              label: const Text('Attendance'),
              onPressed: () {
                // TODO: Implement attendance feature
              },
            ),
          ],
        ),
      ),
    );
  }
}