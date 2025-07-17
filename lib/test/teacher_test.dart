import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class TeacherTestPage extends StatefulWidget {
  final String teacherUid;
  const TeacherTestPage({required this.teacherUid, Key? key}) : super(key: key);

  @override
  State<TeacherTestPage> createState() => _TeacherTestPageState();
}
bool c=false;
class _TeacherTestPageState extends State<TeacherTestPage> {
  bool showOnlyMine = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Teacher Test Creation page')),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CreateTestPage(teacherUid: widget.teacherUid)),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Text('Show only my tests', style: TextStyle(fontSize: 16)),
                Switch(
                  value: showOnlyMine,
                  onChanged: (val) => setState(() => showOnlyMine = val),
                  activeColor: Colors.green,
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('tests')
                  .orderBy('startTime', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                List docs = snapshot.data!.docs;
                if (showOnlyMine) {
                  docs = docs.where((doc) => doc['createdBy'] == widget.teacherUid).toList();
                }
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final test = docs[i];
                    final now = DateTime.now();
                    final end = (test['endTime'] as Timestamp).toDate();
                    final isOver = now.isAfter(end);
                    if(test['createdBy'] == widget.teacherUid){
                      c=true;
                    }
                    return Card(
                       color: test['createdBy'] == widget.teacherUid ? Colors.green : null,
                      child: ListTile(
                        //tileColor: test['createdBy'] == widget.teacherUid ? Colors.green : null,
                        title: Text(test['name']),
                        subtitle: Text('${test['class']} | ${test['description']}'),
                        trailing: isOver
                            ? ElevatedButton(
                                child: const Text('View Submissions'),
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => TestSubmissionsPage(
                                      testId: test.id,
                                      testName: test['name'],
                                    ),
                                  ),
                                ),
                              )
                            : null,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class CreateTestPage extends StatefulWidget {
  final String teacherUid;
  const CreateTestPage({this.teacherUid = '', Key? key}) : super(key: key);
  @override
  State<CreateTestPage> createState() => _CreateTestPageState();
}

class _CreateTestPageState extends State<CreateTestPage> {

  final nameCtrl = TextEditingController();
  final classCtrl = TextEditingController();

  final descCtrl = TextEditingController();
  final marksCtrl = TextEditingController();
  final codeCtrl = TextEditingController();
  DateTime? start, end;
  PlatformFile? pdfFile;
  bool uploading = false;

  Future<void> pickPdf() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null) setState(() => pdfFile = result.files.first);
  }

  Future<void> createTest() async {
    if (pdfFile == null || start == null || end == null) return;
    setState(() => uploading = true);

    final ref = FirebaseStorage.instance.ref('tests/${pdfFile!.name}');
    await ref.putData(pdfFile!.bytes!);
    final pdfUrl = await ref.getDownloadURL();

    await FirebaseFirestore.instance.collection('tests').add({
      'name': nameCtrl.text,
      'class':classCtrl.text,
      'description': descCtrl.text,
      'totalMarks': int.tryParse(marksCtrl.text) ?? 0,
      'startTime': start,
      'endTime': end,
      'code': codeCtrl.text,
      'pdfUrl': pdfUrl,
      'createdBy':widget.teacherUid , // Replace with actual teacher UID or name
    });

    setState(() => uploading = false);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create New Test')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Test Name')),
            TextField(controller: classCtrl, decoration: const InputDecoration(labelText: 'Class Name')),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
            TextField(controller: marksCtrl, decoration: const InputDecoration(labelText: 'Total Marks'), keyboardType: TextInputType.number),
            TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Test Code')),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.picture_as_pdf),
              label: Text(pdfFile == null ? 'Upload PDF' : pdfFile!.name),
              onPressed: pickPdf,
            ),
            // if (pdfFile != null)
            //   Padding(
            //     padding: const EdgeInsets.only(top: 8.0),
            //     child: Text(
            //       'Selected file: ${pdfFile!.name}',
            //       style: const TextStyle(fontSize: 14, color: Colors.teal),
            //     ),
            //   ),
            const SizedBox(height: 12),
            ListTile(
              title: Text(start == null ? 'Pick Start Date & Time' : start.toString()),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2100));
                if (date != null) {
                  final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                  if (time != null) {
                    setState(() => start = DateTime(date.year, date.month, date.day, time.hour, time.minute));
                  }
                }
              },
            ),
            ListTile(
              title: Text(end == null ? 'Pick End Date & Time' : end.toString()),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2100));
                if (date != null) {
                  final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                  if (time != null) {
                    setState(() => end = DateTime(date.year, date.month, date.day, time.hour, time.minute));
                  }
                }
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: uploading ? null : createTest,
              child: uploading ? const CircularProgressIndicator() : const Text('Create Test'),
            ),
          ],
        ),
      ),
    );
  }
}

class TestSubmissionsPage extends StatelessWidget {

  final String testId;
  final String testName;
  const TestSubmissionsPage({required this.testId, required this.testName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Submissions: $testName')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('tests').doc(testId).collection('submissions').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('No submissions yet.'));
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final sub = docs[i];
              return ListTile(
                title: Text(sub['studentName'] ?? 'Unknown'),
                subtitle: Text(
                  (sub.data() != null && (sub.data() as Map<String, dynamic>).containsKey('marks'))
                      ? 'Marks: ${sub['marks']}'
                      : 'Marks: Not evaluated',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.picture_as_pdf),
                      onPressed: () async {
                        final url = sub['answerPdfUrl'];
                        if (await canLaunchUrl(Uri.parse(url))) {
                          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Could not open PDF')),
                          );
                        }
                      },
                    ),
                    if(c==true)
                    IconButton(
                      icon: const Icon(Icons.upload_file),
                      onPressed: () async {
                        // Upload checked PDF and marks
                        final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
                        if (result != null) {
                          final file = result.files.first;
                          final ref = FirebaseStorage.instance.ref('checked/${file.name}');
                          await ref.putData(file.bytes!);
                          final checkedUrl = await ref.getDownloadURL();
                          final marks = await showDialog<String>(
                            context: context,
                            builder: (_) {
                              final marksCtrl = TextEditingController();
                              return AlertDialog(
                                title: const Text('Enter Marks'),
                                content: TextField(controller: marksCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Marks')),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                                  TextButton(onPressed: () => Navigator.pop(context, marksCtrl.text), child: const Text('Submit')),
                                ],
                              );
                            },
                          );
                          await FirebaseFirestore.instance.collection('tests').doc(testId).collection('submissions').doc(sub.id).update({
                            'checkedPdfUrl': checkedUrl,
                            'marks': int.tryParse(marks ?? '0') ?? 0,
                          });
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}



// import 'package:flutter/material.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class CreateTestPage extends StatefulWidget {
//   @override
//   State<CreateTestPage> createState() => _CreateTestPageState();
// }

// class _CreateTestPageState extends State<CreateTestPage> {
//   final nameCtrl = TextEditingController();
//   final descCtrl = TextEditingController();
//   final marksCtrl = TextEditingController();
//   final codeCtrl = TextEditingController();
//   DateTime? start, end;
//   PlatformFile? pdfFile;
//   bool uploading = false;

//   Future<void> pickPdf() async {
//     final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
//     if (result != null) setState(() => pdfFile = result.files.first);
//   }

//   Future<void> createTest() async {
//     if (pdfFile == null || start == null || end == null) return;
//     setState(() => uploading = true);

//     // Upload PDF
//     final ref = FirebaseStorage.instance.ref('tests/${pdfFile!.name}');
//     await ref.putData(pdfFile!.bytes!);
//     final pdfUrl = await ref.getDownloadURL();

//     // Save test in Firestore
//     await FirebaseFirestore.instance.collection('tests').add({
//       'name': nameCtrl.text,
//       'description': descCtrl.text,
//       'totalMarks': int.tryParse(marksCtrl.text) ?? 0,
//       'startTime': start,
//       'endTime': end,
//       'code': codeCtrl.text,
//       'pdfUrl': pdfUrl,
//       'createdBy': 'TEACHER_UID', // Replace with actual teacher UID
//     });

//     setState(() => uploading = false);
//     Navigator.pop(context);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Create New Test')),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: ListView(
//           children: [
//             TextField(controller: nameCtrl, decoration: InputDecoration(labelText: 'Test Name')),
//             TextField(controller: descCtrl, decoration: InputDecoration(labelText: 'Description')),
//             TextField(controller: marksCtrl, decoration: InputDecoration(labelText: 'Total Marks'), keyboardType: TextInputType.number),
//             TextField(controller: codeCtrl, decoration: InputDecoration(labelText: 'Test Code')),
//             const SizedBox(height: 12),
//             ElevatedButton.icon(
//               icon: Icon(Icons.picture_as_pdf),
//               label: Text(pdfFile == null ? 'Upload PDF' : pdfFile!.name),
//               onPressed: pickPdf,
//             ),
//             const SizedBox(height: 12),
//             ListTile(
//               title: Text(start == null ? 'Pick Start Date & Time' : start.toString()),
//               trailing: Icon(Icons.calendar_today),
//               onTap: () async {
//                 final date = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2100));
//                 if (date != null) {
//                   final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
//                   if (time != null) {
//                     setState(() => start = DateTime(date.year, date.month, date.day, time.hour, time.minute));
//                   }
//                 }
//               },
//             ),
//             ListTile(
//               title: Text(end == null ? 'Pick End Date & Time' : end.toString()),
//               trailing: Icon(Icons.calendar_today),
//               onTap: () async {
//                 final date = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2100));
//                 if (date != null) {
//                   final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
//                   if (time != null) {
//                     setState(() => end = DateTime(date.year, date.month, date.day, time.hour, time.minute));
//                   }
//                 }
//               },
//             ),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: uploading ? null : createTest,
//               child: uploading ? CircularProgressIndicator() : Text('Create Test'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }