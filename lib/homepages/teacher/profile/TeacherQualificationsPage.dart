import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';

class TeacherQualificationsPage extends StatefulWidget {
  final String teacherUid;
  const TeacherQualificationsPage({super.key, required this.teacherUid});

  @override
  State<TeacherQualificationsPage> createState() =>
      _TeacherQualificationsPageState();
}

class _TeacherQualificationsPageState extends State<TeacherQualificationsPage> {
  final _formKey = GlobalKey<FormState>();
  final qualificationsCtrl = TextEditingController();
  final descriptionCtrl = TextEditingController();
  final collegeCtrl = TextEditingController();
  Uint8List? docBytes;
  String? docName;
  Uint8List? photoBytes;
  String? photoName;
  List<Map<String, dynamic>> subjects = [];
  List<Map<String, dynamic>> classes = [];
  String? selectedState;
  bool isUploading = false;

  void addSubject() {
    setState(() {
      subjects.add({'name': '', 'fees': ''});
    });
  }

  void addClass() {
    setState(() {
      classes.add({'name': '', 'section': ''});
    });
  }

  Future<String?> uploadFile(Uint8List bytes, String path) async {
    final ref = FirebaseStorage.instance.ref().child(path);
    await ref.putData(bytes);
    return await ref.getDownloadURL();
  }

  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isUploading = true);

    String? docUrl;
    String? photoUrl;

    if (docBytes != null) {
      docUrl = await uploadFile(
          docBytes!, 'teacher_docs/${widget.teacherUid}/qualification.pdf');
    }
    if (photoBytes != null) {
      photoUrl = await uploadFile(
          photoBytes!, 'teacher_docs/${widget.teacherUid}/photo.jpg');
    }

    final updateData = {
      'description': descriptionCtrl.text.trim(),
      'state': selectedState,
      'college': collegeCtrl.text.trim(),
      'qualifications': qualificationsCtrl.text.trim(),
      'subjects': subjects
          .where((s) =>
              s['name'].toString().trim().isNotEmpty &&
              s['fees'].toString().trim().isNotEmpty)
          .toList(),
      'classes': classes
          .where((c) =>
              c['name'].toString().trim().isNotEmpty &&
              c['fees'].toString().trim().isNotEmpty)
          .toList(),
    };

    if (docUrl != null) {
      updateData['docUrl'] = docUrl;
    }
    if (photoUrl != null) {
      updateData['photoUrl'] = photoUrl;
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.teacherUid)
        .set(updateData, SetOptions(merge: true));

    setState(() => isUploading = false);
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Details submitted!')));
      Navigator.pop(context);
    }
  }

  final List<String> indianStates = [
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chhattisgarh',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
    'Andaman and Nicobar Islands',
    'Chandigarh',
    'Dadra and Nagar Haveli and Daman and Diu',
    'Delhi',
    'Jammu and Kashmir',
    'Ladakh',
    'Lakshadweep',
    'Puducherry'
  ];

  @override
  void initState() {
    super.initState();
    loadExistingData();
  }

  Future<void> loadExistingData() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.teacherUid)
        .get();
    final data = doc.data();
    if (data != null) {
      qualificationsCtrl.text = data['qualifications'] ?? '';
      descriptionCtrl.text = data['description'] ?? '';
      collegeCtrl.text = data['college'] ?? '';
      selectedState = data['state'];
      docName = data['docUrl'] != null ? 'Document Uploaded' : null;
      photoName = data['photoUrl'] != null ? 'Photo Uploaded' : null;
      subjects = (data['subjects'] as List?)
              ?.map((e) => {
                    'name': e['name'] ?? '',
                    'fees': e['fees'] ?? '',
                  })
              .toList() ??
          [
            {'name': '', 'fees': ''}
          ];
      classes = (data['classes'] as List?)
              ?.map((e) => {
                    'name': e['name'] ?? '',
                    'fees': e['fees'] ?? '',
                  })
              .toList() ??
          [
            {'name': '', 'fees': ''}
          ];
      setState(() {});
    } else {
      // If no data, initialize with one empty entry
      subjects = [
        {'name': '', 'fees': ''}
      ];
      classes = [
        {'name': '', 'fees': ''}
      ];
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Teacher Qualifications')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: qualificationsCtrl,
                decoration:
                    const InputDecoration(labelText: 'Qualifications *'),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Enter your qualifications'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: descriptionCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedState,
                items: indianStates
                    .map((state) => DropdownMenuItem(
                          value: state,
                          child: Text(state),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => selectedState = v),
                decoration: const InputDecoration(labelText: 'State'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Select your state' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: collegeCtrl,
                decoration: const InputDecoration(labelText: 'College Name'),
              ),
              const SizedBox(height: 16),
              const Text('Classes & Fees (1-5):'),
              ...List.generate(classes.length, (i) {
                return Row(
                  key: ValueKey('class_$i'), // <-- Add this line
                  children: [
                    Expanded(
                      child: TextFormField(
                        key: ValueKey(
                            'class_name_${i}_${classes[i]['name']}'), // <-- Add key
                        decoration: const InputDecoration(labelText: 'Class'),
                        initialValue: classes[i]['name'],
                        onChanged: (v) => classes[i]['name'] = v,
                        validator: (v) {
                          if (i == 0 && (v == null || v.trim().isEmpty)) {
                            return 'At least 1 class required';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        key: ValueKey(
                            'class_fees_${i}_${classes[i]['fees']}'), // <-- Add key
                        decoration: const InputDecoration(labelText: 'Fees'),
                        keyboardType: TextInputType.number,
                        initialValue: classes[i]['fees'],
                        onChanged: (v) => classes[i]['fees'] = v,
                        validator: (v) {
                          if (i == 0 && (v == null || v.trim().isEmpty)) {
                            return 'Required';
                          }
                          return null;
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: classes.length > 1
                          ? () {
                              setState(() {
                                classes.removeAt(i);
                              });
                            }
                          : null,
                    ),
                  ],
                );
              }),
              if (classes.length < 5)
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add Class'),
                  onPressed: () {
                    if (classes.length < 5)
                      setState(() => classes.add({'name': '', 'fees': ''}));
                  },
                ),
              const SizedBox(height: 24),
              const Text('Subjects & Fees (1-5):'),
              ...List.generate(subjects.length, (i) {
                return Row(
                  key: ValueKey('subject_$i'), // <-- Add this line
                  children: [
                    Expanded(
                      child: TextFormField(
                        key: ValueKey(
                            'subject_name_${i}_${subjects[i]['name']}'), // <-- Add key
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
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        key: ValueKey(
                            'subject_fees_${i}_${subjects[i]['fees']}'), // <-- Add key
                        decoration: const InputDecoration(labelText: 'Fees'),
                        keyboardType: TextInputType.number,
                        initialValue: subjects[i]['fees'],
                        onChanged: (v) => subjects[i]['fees'] = v,
                        validator: (v) {
                          if (i == 0 && (v == null || v.trim().isEmpty)) {
                            return 'Required';
                          }
                          return null;
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: subjects.length > 1
                          ? () {
                              setState(() {
                                subjects.removeAt(i);
                              });
                            }
                          : null,
                    ),
                  ],
                );
              }),
              if (subjects.length < 5)
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add Subject'),
                  onPressed: () {
                    if (subjects.length < 5)
                      setState(() => subjects.add({'name': '', 'fees': ''}));
                  },
                ),
              const SizedBox(height: 24),
              const Text('Upload Supporting Document *'),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      final result = await FilePicker.platform
                          .pickFiles(type: FileType.any, withData: true);
                      if (result != null && result.files.single.bytes != null) {
                        setState(() {
                          docBytes = result.files.single.bytes;
                          docName = result.files.single.name;
                        });
                      }
                    },
                    child: const Text('Pick Document'),
                  ),
                  const SizedBox(width: 8),
                  Text(docName ?? 'No file selected'),
                ],
              ),
              // if (docBytes == null)
              //   const Padding(
              //     padding: EdgeInsets.only(top: 4),
              //     child: Text('Document is required', style: TextStyle(color: Colors.red)),
              //   ),
              const SizedBox(height: 16),
              const Text('Upload Photo (optional)'),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      final result = await FilePicker.platform
                          .pickFiles(type: FileType.image, withData: true);
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
              const SizedBox(height: 24),
              Row(mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: isUploading ? null : submit,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.purple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    child: isUploading
                        ?  Container(
                            height: 20,
                            width: 20,
                            //color: Colors.green,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.green,
                            ),
                          )
                        : const Text('Submit'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
