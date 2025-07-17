import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';

class StudentDetailsPage extends StatefulWidget {
  final String studentUid;
  const StudentDetailsPage({super.key, required this.studentUid});

  @override
  State<StudentDetailsPage> createState() => _StudentDetailsPageState();
}

class _StudentDetailsPageState extends State<StudentDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final classCtrl = TextEditingController();
  final minFeesCtrl = TextEditingController();
  final maxFeesCtrl = TextEditingController();
  Uint8List? photoBytes;
  String? photoName;
  Uint8List? resultDocBytes;
  String? resultDocName;
  List<Map<String, dynamic>> subjects = [];
  bool isUploading = false;

  @override
  void initState() {
    super.initState();
    loadExistingData();
  }

  Future<void> loadExistingData() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.studentUid)
        .get();
    final data = doc.data();
    if (data != null) {
      classCtrl.text = data['studentClass'] ?? '';
      minFeesCtrl.text = data['minFees']?.toString() ?? '';
      maxFeesCtrl.text = data['maxFees']?.toString() ?? '';
      photoName = data['photoUrl'] != null ? 'Photo Uploaded' : null;
      resultDocName = data['resultDocUrl'] != null ? 'Result Uploaded' : null;
      subjects = (data['studentSubjects'] as List?)
              ?.map((e) => {'name': e['name'] ?? ''})
              .toList() ??
          [
            {'name': ''}
          ];
      setState(() {});
    } else {
      subjects = [
        {'name': ''}
      ];
      setState(() {});
    }
  }

  Future<String?> uploadFile(Uint8List bytes, String path) async {
    final ref = FirebaseStorage.instance.ref().child(path);
    await ref.putData(bytes);
    return await ref.getDownloadURL();
  }

  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isUploading = true);

    String? photoUrl;
    String? resultDocUrl;

    if (photoBytes != null) {
      photoUrl = await uploadFile(photoBytes!, 'student_docs/${widget.studentUid}/photo.jpg');
    }
    if (resultDocBytes != null) {
      resultDocUrl = await uploadFile(resultDocBytes!, 'student_docs/${widget.studentUid}/result.pdf');
    }

    final updateData = {
      'studentClass': classCtrl.text.trim(),
      'minFees': minFeesCtrl.text.trim(),
      'maxFees': maxFeesCtrl.text.trim(),
      'studentSubjects': subjects
          .where((s) => s['name'].toString().trim().isNotEmpty)
          .toList(),
    };

    if (photoUrl != null) {
      updateData['photoUrl'] = photoUrl;
    }
    if (resultDocUrl != null) {
      updateData['resultDocUrl'] = resultDocUrl;
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.studentUid)
        .set(updateData, SetOptions(merge: true));

    setState(() => isUploading = false);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Details submitted!')));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Details')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text('Upload Photo *'),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
                      if (result != null && result.files.single.bytes != null) {
                        setState(() {
                          photoBytes = result.files.single.bytes;
                          photoName = result.files.single.name;
                        });
                      }
                    },
                    child: const Text('Pick Photo'),
                  ),
                  const SizedBox(width: 8),
                  Text(photoName ?? 'No file selected'),
                ],
              ),
              if (photoBytes == null && photoName == null)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text('Photo is required', style: TextStyle(color: Colors.red)),
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: classCtrl,
                decoration: const InputDecoration(labelText: 'Class *'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Enter your class' : null,
              ),
              const SizedBox(height: 16),
              const Text('Subjects you want to study (1-5):'),
              ...List.generate(subjects.length, (i) {
                return Row(
                  key: ValueKey('subject_$i'),
                  children: [
                    Expanded(
                      child: TextFormField(
                        key: ValueKey('subject_name_${i}_${subjects[i]['name']}'),
                        decoration: const InputDecoration(labelText: 'Subject'),
                        initialValue: subjects[i]['name'],
                        onChanged: (v) => subjects[i]['name'] = v,
                        validator: (v) {
                          if (i == 0 && (v == null || v.trim().isEmpty)) {
                            return 'At least 1 subject required';
                          }
                          return null;
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        setState(() {
                          subjects.removeAt(i);
                        });
                      },
                    ),
                  ],
                );
              }),
              if (subjects.length < 5)
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add Subject'),
                  onPressed: () {
                    if (subjects.length < 5) setState(() => subjects.add({'name': ''}));
                  },
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: minFeesCtrl,
                      decoration: const InputDecoration(labelText: 'Min Fees *'),
                      keyboardType: TextInputType.number,
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: maxFeesCtrl,
                      decoration: const InputDecoration(labelText: 'Max Fees *'),
                      keyboardType: TextInputType.number,
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Upload Last Class Result (optional)'),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      final result = await FilePicker.platform.pickFiles(type: FileType.any, withData: true);
                      if (result != null && result.files.single.bytes != null) {
                        setState(() {
                          resultDocBytes = result.files.single.bytes;
                          resultDocName = result.files.single.name;
                        });
                      }
                    },
                    child: const Text('Pick Document'),
                  ),
                  const SizedBox(width: 8),
                  Text(resultDocName ?? 'No file selected'),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: isUploading ? null : submit,
                child: isUploading
                    ? const CircularProgressIndicator()
                    : const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}