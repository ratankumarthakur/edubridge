import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class teacher_fees extends StatefulWidget {
  final String classId;
  final String className;

  const teacher_fees(
      {super.key, required this.classId, required this.className});

  @override
  State<teacher_fees> createState() => _teacher_feesState();
}

class _teacher_feesState extends State<teacher_fees> {
  File? _imageFile;
  Uint8List? _imageData;
  String? _imageUrl;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _errorMsg;
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  List<Map<String, dynamic>> _students = [];
  Map<String, bool> _feesStatus = {};
  bool _loadingStudents = true;

  @override
  void initState() {
    super.initState();
    _fetchQrImage();
    _fetchStudents();
  }

  Future<void> _fetchQrImage() async {
    final doc = await FirebaseFirestore.instance
        .collection('classes')
        .doc(widget.classId)
        .get();
    if (doc.exists && doc.data() != null && doc.data()!['feesQrUrl'] != null) {
      setState(() {
        _imageUrl = doc.data()!['feesQrUrl'];
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
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    final fileName = 'fees_qr/${widget.classId}.jpg';
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
            .update({'feesQrUrl': downloadUrl});
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

  Future<void> _fetchStudents() async {
    setState(() {
      _loadingStudents = true;
    });
    final classDoc = await FirebaseFirestore.instance
        .collection('classes')
        .doc(widget.classId)
        .get();
    final classData = classDoc.data() ?? {};
    final List joinedUids = classData['joinedStudents'] ?? [];
    List<Map<String, dynamic>> students = [];
    for (var uid in joinedUids) {
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        students.add({
          'uid': uid,
          'name': userData['name'] ?? '',
          'email': userData['email'] ?? ''
        });
      }
    }
    setState(() {
      _students = students;
      _loadingStudents = false;
    });
    await _fetchFeesStatus();
  }

  String get _monthKey {
    return DateFormat('yyyy-MM').format(_selectedMonth);
  }

  Future<void> _fetchFeesStatus() async {
    final feesDoc = await FirebaseFirestore.instance
        .collection('classes')
        .doc(widget.classId)
        .collection('fees')
        .doc(_monthKey)
        .get();
    final data = feesDoc.data() ?? {};
    Map<String, bool> status = {};
    for (var student in _students) {
      status[student['uid']] = data[student['uid']] == true;
    }
    setState(() {
      _feesStatus = status;
    });
  }

  Future<void> _updateFeesStatus(String uid, bool paid) async {
    await FirebaseFirestore.instance
        .collection('classes')
        .doc(widget.classId)
        .collection('fees')
        .doc(_monthKey)
        .set({uid: paid}, SetOptions(merge: true));
    setState(() {
      _feesStatus[uid] = paid;
    });
  }

  Future<void> _pickMonth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(now.year - 2, 1),
      lastDate: DateTime(now.year + 2, 12),
      helpText: 'Select Month',
      fieldLabelText: 'Month/Year',
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      selectableDayPredicate: (date) => date.day == 1,
    );
    if (picked != null) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month);
      });
      await _fetchFeesStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.className} - Fees',style: TextStyle(fontSize: 18),),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Center(
                child: SizedBox(
                  height: 180,
                  width: 180,
                  child: Card(
                    elevation: 2,
                    child: _isUploading
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              LinearProgressIndicator(value: _uploadProgress),
                              const SizedBox(height: 8),
                              Text(
                                  '${(_uploadProgress * 100).toStringAsFixed(0)}% uploaded'),
                            ],
                          )
                        : (_imageUrl != null
                            ? ClipRRect(
                              borderRadius: BorderRadius.circular(11),
                              
          child: Image.network(
            _imageUrl!,
            width: 180,
            height: 180,
            fit: BoxFit.cover,
          ),
        )

                            : const Center(
                                child: Text('No QR/Photo uploaded'))),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.upload,color: Colors.white,),
                label: const Text('Upload QR/Photo'),
                onPressed: _isUploading ? null : _pickImageAndUpload,
              ),
              if (_errorMsg != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(_errorMsg!,
                      style: const TextStyle(color: Colors.red)),
                ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Month: ${DateFormat('MMMM yyyy').format(_selectedMonth)}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.calendar_month),
                    label: const Text('Change'),
                    onPressed: _pickMonth,
                  ),
                ],
              ),
              const Divider(),
              _loadingStudents
                  ? const Center(child: CircularProgressIndicator())
                  : _students.isEmpty
                      ? const Text('No students in this class.')
                      : FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('classes')
                              .doc(widget.classId)
                              .collection('fees')
                              .doc(_monthKey)
                              .get(),
                          builder: (context, snapshot) {
                            Map<String, dynamic> feeData = {};
                            if (snapshot.hasData &&
                                snapshot.data!.data() != null) {
                              feeData =
                                  snapshot.data!.data() as Map<String, dynamic>;
                            }
                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _students.length,
                              itemBuilder: (context, idx) {
                                final student = _students[idx];
                                final paid =
                                    _feesStatus[student['uid']] ?? false;
                                final screenshotUrl = feeData['url'] is String
                                    ? feeData['url']
                                    : null;
                                return ListTile(
                                  leading: const Icon(Icons.person),
                                  title: Text(student['name']),
                                  subtitle: Text(student['email']),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Switch(
                                        value: paid,
                                        onChanged: (val) => _updateFeesStatus(
                                            student['uid'], val),
                                        activeColor: Colors.green,
                                        inactiveThumbColor: Colors.red,
                                      ),
                                      if (screenshotUrl != null)
                                        GestureDetector(
                                          onTap: () {
                                            showDialog(
                                              context: context,
                                              builder: (_) => Dialog(
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        'Transaction Screenshot',
                                                        style: const TextStyle(
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Image.network(
                                                          screenshotUrl),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                                left: 8.0),
                                            child: SizedBox(
                                              width: 40,
                                              height: 40,
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                child: Image.network(
                                                  screenshotUrl,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error,
                                                          stackTrace) =>
                                                      const Icon(
                                                          Icons.broken_image,
                                                          color: Colors.red),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
            ],
          ),
        ),
      ),
    );
  }
}
