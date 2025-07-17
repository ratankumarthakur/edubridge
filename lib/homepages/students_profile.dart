import 'package:chat/homepages/StudentQualificationsPage.dart';
import 'package:chat/homepages/student_class_action_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:url_launcher/url_launcher.dart';

class StudentProfilePage extends StatefulWidget {
  const StudentProfilePage({super.key});

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  User? get user => FirebaseAuth.instance.currentUser;

  Future<Map<String, dynamic>?> getStudentData() async {
    if (user == null) return null;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();
    return doc.data();
  }

  @override
  Widget build(BuildContext context) {
    final studentUid = user?.uid;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              await GoogleSignIn().signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
        ],
      ),
      body: studentUid == null
          ? const Center(child: Text('Not logged in'))
          : FutureBuilder<Map<String, dynamic>?>(
              future: getStudentData(),
              builder: (context, snapshot) {
                final studentData = snapshot.data;
                final joinedClasses =
                    (studentData?['joinedClasses'] as List<dynamic>? ?? [])
                        .cast<String>();
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Info
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundImage: studentData?['photoUrl'] != null
                                ? NetworkImage(studentData!['photoUrl'])
                                : null,
                            child: studentData?['photoUrl'] == null
                                ? const Icon(Icons.person, size: 40)
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  studentData?['name'] ?? 'Student Name',
                                  style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  user?.email ?? 'Student',
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (studentData != null) ...[
                        if (studentData['studentClass'] != null &&
                            studentData['studentClass'].toString().isNotEmpty)
                          Text('Class: ${studentData['studentClass']}'),
                        if (studentData['studentSubjects'] != null &&
                            (studentData['studentSubjects'] as List).isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Subjects:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              ...List.generate(
                                (studentData['studentSubjects'] as List).length,
                                (i) {
                                  final subj =
                                      studentData['studentSubjects'][i];
                                  return Text('${subj['name']}');
                                },
                              ),
                            ],
                          ),
                        if (studentData['minFees'] != null &&
                            studentData['maxFees'] != null)
                          Text(
                              'Fees Range: ₹${studentData['minFees']} - ₹${studentData['maxFees']}'),
                        if (studentData['resultDocUrl'] != null)
                          TextButton.icon(
                            icon: const Icon(Icons.picture_as_pdf),
                            label: const Text('View Last Class Result'),
                            onPressed: () {
                              launchUrl(Uri.parse(studentData['resultDocUrl']));
                            },
                          ),
                        const Divider(),
                      ],
                      ElevatedButton.icon(
                        icon: const Icon(Icons.edit),
                        label: const Text('Add/Update Details'),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  StudentDetailsPage(studentUid: studentUid),
                            ),
                          );
                          setState(() {});
                        },
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.group_add),
                        label: const Text('Join New Class'),
                        onPressed: () async {
                          final joined = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const JoinClassPage(),
                            ),
                          );
                          if (joined == true) setState(() {});
                        },
                      ),
                      const SizedBox(height: 24),
                      const Text('Your Classes:',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Expanded(
                        child: joinedClasses.isEmpty
                            ? const Center(
                                child: Text('No classes joined yet.'))
                            : StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('classes')
                                    .where(FieldPath.documentId,
                                        whereIn: joinedClasses)
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                        child: CircularProgressIndicator());
                                  }
                                  if (snapshot.hasError) {
                                    return Center(
                                        child:
                                            Text('Error: ${snapshot.error}'));
                                  }
                                  final docs = snapshot.data?.docs ?? [];
                                  if (docs.isEmpty) {
                                    return const Center(
                                        child: Text('No classes found.'));
                                  }
                                  return ListView.builder(
                                    itemCount: docs.length,
                                    itemBuilder: (context, i) {
                                      final data = docs[i].data()
                                          as Map<String, dynamic>;
                                      return Card(
                                        child: ListTile(
                                          title: Text(data['name'] ?? ''),
                                          subtitle:
                                              Text('Code: ${data['code']}'),
                                          trailing: IconButton(
                                            icon: const Icon(Icons.exit_to_app,
                                                color: Colors.red),
                                            tooltip: 'Leave Class',
                                            onPressed: () async {
                                              final user = FirebaseAuth
                                                  .instance.currentUser;
                                              if (user == null) return;
                                              // Remove class from student's joinedClasses
                                              await FirebaseFirestore.instance
                                                  .collection('users')
                                                  .doc(user.uid)
                                                  .update({
                                                'joinedClasses':
                                                    FieldValue.arrayRemove(
                                                        [docs[i].id])
                                              });
                                              // Remove student from class's joinedStudents and blockedStudents
                                              await FirebaseFirestore.instance
                                                  .collection('classes')
                                                  .doc(docs[i].id)
                                                  .update({
                                                'joinedStudents':
                                                    FieldValue.arrayRemove(
                                                        [user.uid]),
                                                'blockedStudents':
                                                    FieldValue.arrayRemove(
                                                        [user.uid]),
                                              });
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                      content: Text(
                                                          'You have left the class.')),
                                                );
                                                setState(() {});
                                              }
                                            },
                                          ),
                                          onTap: () async {
                                            final user = FirebaseAuth
                                                .instance.currentUser;
                                            if (user == null) return;
                                            final classDoc =
                                                await FirebaseFirestore.instance
                                                    .collection('classes')
                                                    .doc(docs[i].id)
                                                    .get();
                                            final classData = classDoc.data()
                                                    as Map<String, dynamic>? ??
                                                {};
                                            final joined =
                                                (classData['joinedStudents']
                                                            as List<dynamic>? ??
                                                        [])
                                                    .cast<String>();
                                            final blocked =
                                                (classData['blockedStudents']
                                                            as List<dynamic>? ??
                                                        [])
                                                    .cast<String>();
                                            if (blocked.contains(user.uid)) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                      content: Text(
                                                          'You have been blocked from this class by the teacher.')),
                                                );
                                              }
                                              return;
                                            }
                                            if (!joined.contains(user.uid)) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                      content: Text(
                                                          'You have been removed from this class.')),
                                                );
                                              }
                                              return;
                                            }
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    StudentClassActionPage(
                                                  classId: docs[i].id,
                                                  className: data['name'] ?? '',
                                                ),
                                              ),
                                            );
                                          },
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
              },
            ),
    );
  }
}

class JoinClassPage extends StatefulWidget {
  const JoinClassPage({super.key});

  @override
  State<JoinClassPage> createState() => _JoinClassPageState();
}

class _JoinClassPageState extends State<JoinClassPage> {
  final TextEditingController searchCtrl = TextEditingController();
  String searchText = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join a Class')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchCtrl,
              decoration: const InputDecoration(
                labelText: 'Search Class Name',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (val) => setState(() => searchText = val.trim()),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('classes').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final docs = snapshot.data?.docs ?? [];
                final filtered = docs.where((doc) {
                  final name = (doc['name'] ?? '').toString().toLowerCase();
                  return name.contains(searchText.toLowerCase());
                }).toList();
                if (filtered.isEmpty) {
                  return const Center(child: Text('No classes found.'));
                }
                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final data = filtered[i].data() as Map<String, dynamic>;
                    return Card(
                      child: ListTile(
                        title: Text(data['name'] ?? ''),
                        subtitle: Text('Teacher Code: ${data['code']}'),
                        onTap: () async {
                          final code = await showDialog<String>(
                            context: context,
                            builder: (context) {
                              final codeCtrl = TextEditingController();
                              return AlertDialog(
                                title: Text('Enter code for "${data['name']}"'),
                                content: TextField(
                                  controller: codeCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Class Code',
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(
                                          context, codeCtrl.text.trim());
                                    },
                                    child: const Text('Join'),
                                  ),
                                ],
                              );
                            },
                          );
                          if (code == null || code.isEmpty) return;
                          // Check code
                          if (code == data['code']) {
                            final user = FirebaseAuth.instance.currentUser;
                            if (user != null) {
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(user.uid)
                                  .update({
                                'joinedClasses':
                                    FieldValue.arrayUnion([filtered[i].id])
                              });
                              await FirebaseFirestore.instance
                                  .collection('classes')
                                  .doc(filtered[i].id)
                                  .set({
                                'joinedStudents':
                                    FieldValue.arrayUnion([user.uid])
                              }, SetOptions(merge: true));
                            }
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Class joined!')),
                              );
                              Navigator.pop(context, true);
                            }
                          } else {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Incorrect code!')),
                              );
                            }
                          }
                        },
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
