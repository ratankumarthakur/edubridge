// import 'package:chat/test/pdf_shower.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:url_launcher/url_launcher.dart';

class StudentTestPage extends StatelessWidget {
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Test Page')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('tests')
            .orderBy('startTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          final now = DateTime.now();
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final test = docs[i];
              final start = (test['startTime'] as Timestamp).toDate();
              final end = (test['endTime'] as Timestamp).toDate();
              final isLive = now.isAfter(start) && now.isBefore(end);
              final isOver = now.isAfter(end);
              return ListTile(
                leading: isLive
                    ? AvatarGlow(
                        glowColor: Colors.green,
                        //glowBorderRadius: BorderRadius.circular(24),
                        //radius: 24,
                        child: const CircleAvatar(
                            backgroundColor: Colors.green,
                            child: Icon(Icons.play_arrow, color: Colors.white)),
                      )
                    : null,
                title: Text(test['name']),
                subtitle: Text(isLive
                    ? 'Live'
                    : isOver
                        ? 'Over'
                        : 'Upcoming'),
                tileColor: isLive ? Colors.green[50] : null,
                onTap: () {
                  if (isLive) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => EnterTestPage(test: test)),
                    );
                  } else if (isOver) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => ViewCheckedScriptPage(test: test)),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

class EnterTestPage extends StatefulWidget {
  final dynamic test;
  const EnterTestPage({required this.test});
  @override
  State<EnterTestPage> createState() => _EnterTestPageState();
}

class _EnterTestPageState extends State<EnterTestPage> {
  final codeCtrl = TextEditingController();
  PlatformFile? answerFile;
  bool uploading = false;
  bool codeOk = false;

  Future<void> pickPdf() async {
    final result = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null) setState(() => answerFile = result.files.first);
  }

  Future<void> submitAnswer() async {
    if (answerFile == null) return;
    setState(() => uploading = true);
    final ref = FirebaseStorage.instance.ref('answers/${answerFile!.name}');
    await ref.putData(answerFile!.bytes!);
    final answerUrl = await ref.getDownloadURL();
    await FirebaseFirestore.instance
        .collection('tests')
        .doc(widget.test.id)
        .collection('submissions')
        .add({
      'studentUid': 'student1', // Replace with actual student UID
      'studentName': 'Student Name', // Replace with actual student name
      'answerPdfUrl': answerUrl,
      'submittedAt': DateTime.now(),
    });
    setState(() => uploading = false);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.test['name'])),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: codeOk
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Test PDF:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  //Text('Open PDF: ${widget.test['pdfUrl']}'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Open Test PDF'),
                    onPressed: () async {
                      final url = widget.test['pdfUrl'];
                      if (await canLaunchUrl(Uri.parse(url))) {
                        await launchUrl(Uri.parse(url), mode: LaunchMode.inAppWebView);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Could not open PDF')),
                        );
                      }
                    },
                    // onPressed: () {
                    //   Navigator.push(
                    //     context,
                    //     MaterialPageRoute(
                    //       builder: (_) => PDFViewerPage(
                    //         url: widget.test['pdfUrl'], // Test PDF url
                    //         title: 'Test PDF',
                    //       ),
                    //     ),
                    //   );
                    // },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: Icon(Icons.upload_file),
                    label: Text(answerFile == null
                        ? 'Upload Answer PDF'
                        : answerFile!.name),
                    onPressed: pickPdf,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: uploading ? null : submitAnswer,
                    child: uploading
                        ? CircularProgressIndicator()
                        : Text('Submit Answer'),
                  ),
                ],
              )
            : Column(
                children: [
                  TextField(
                      controller: codeCtrl,
                      decoration:
                          InputDecoration(labelText: 'Enter Test Code')),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (codeCtrl.text.trim() == widget.test['code']) {
                        setState(() => codeOk = true);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Incorrect code')));
                      }
                    },
                    child: const Text('Enter Test'),
                  ),
                ],
              ),
      ),
    );
  }
}

class ViewCheckedScriptPage extends StatefulWidget {
  final dynamic test;
  const ViewCheckedScriptPage({required this.test});
  @override
  State<ViewCheckedScriptPage> createState() => _ViewCheckedScriptPageState();
}

class _ViewCheckedScriptPageState extends State<ViewCheckedScriptPage> {
  final codeCtrl = TextEditingController();
  bool codeOk = false;
  String? checkedUrl;
  int? marks;

  Future<void> fetchCheckedScript() async {
    final subs = await FirebaseFirestore.instance
        .collection('tests')
        .doc(widget.test.id)
        .collection('submissions')
        .where('studentUid',
            isEqualTo: 'student1') // Replace with actual student UID
        .get();
    if (subs.docs.isNotEmpty) {
      final sub = subs.docs.first;
      setState(() {
        checkedUrl = sub['checkedPdfUrl'];
        marks = sub['marks'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.test['name'])),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: codeOk
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (checkedUrl != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        //Text('Checked PDF: $checkedUrl'),
                        Text('Marks obtained : ${marks ?? "Not evaluated"}'),
                        Text('Download the checked script:'),
                        IconButton(
                          icon: const Icon(Icons.picture_as_pdf),
                          onPressed: () async {
                            final url = checkedUrl;
                            if (url != null &&
                                await canLaunchUrl(Uri.parse(url))) {
                              await launchUrl(Uri.parse(url),
                                  mode: LaunchMode.externalApplication);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Could not open PDF')),
                              );
                            }
                          },
                        ),
                      ],
                    )
                  else
                    const Text('Checked script not uploaded yet.'),
                ],
              )
            : Column(
                children: [
                  TextField(
                      controller: codeCtrl,
                      decoration:
                          InputDecoration(labelText: 'Enter Test Code')),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      if (codeCtrl.text.trim() == widget.test['code']) {
                        setState(() => codeOk = true);
                        await fetchCheckedScript();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Incorrect code')));
                      }
                    },
                    child: const Text('View Checked Script'),
                  ),
                ],
              ),
      ),
    );
  }
}

// To show the marks dialog, use this function inside an async method or callback:
Future<String?> showMarksDialog(BuildContext context) async {
  final marksCtrl = TextEditingController();
  return await showDialog<String>(
    context: context,
    builder: (_) {
      return AlertDialog(
        title: const Text('Enter Marks'),
        content: TextField(
          controller: marksCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Marks'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, marksCtrl.text),
              child: const Text('Submit')),
        ],
      );
    },
  );
}

Future<void> updateCheckedScript(
    String testId, String checkedUrl, String? marks, String subId) async {
  await FirebaseFirestore.instance
      .collection('tests')
      .doc(testId)
      .collection('submissions')
      .doc(subId)
      .update({
    'checkedPdfUrl': checkedUrl,
    'marks': int.tryParse(marks ?? '0') ?? 0,
  });
}
