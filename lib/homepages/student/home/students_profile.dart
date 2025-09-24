import 'package:avatar_glow/avatar_glow.dart';
import 'package:chat/homepages/student/home/StudentQualificationsPage.dart';
import 'package:chat/homepages/student/home/joinclass.dart';
import 'package:chat/homepages/student/home/class/student_class_action_page.dart';
import 'package:chat/teacher_student_onboarding/TeachersListPage.dart';
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
            icon: const Icon(Icons.group,color: Colors.white,),
            tooltip: 'See available teachers list',
            onPressed: (){
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>TeachersListPage(),
                  ),
                );
            }
          ),
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
      floatingActionButton: AvatarGlow(
        glowColor: Colors.purple,
        // endRadius: 60.0,
        duration: Duration(milliseconds: 2000),
        repeat: true,
        child: FloatingActionButton(
            backgroundColor: Colors.purple.shade100,
            shape: CircleBorder(),
            onPressed: () async {
                            final joined = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const JoinClassPage(),
                              ),
                            );
                            if (joined == true) setState(() {});
                          },
            child: Icon(Icons.add)),
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
                          Row(
                            children: [
                              Text(
                                'Class: ',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              Text(
                                '${studentData['studentClass']}',
                                style: TextStyle(fontWeight: FontWeight.bold,color: Colors.purple),
                              ),
                            ],
                          ),
                          if (studentData['minFees'] != null &&
                            studentData['maxFees'] != null)
                          Row(
                            children: [
                              Text(
                                'Fees Range: ',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              Text(
                                  '₹${studentData['minFees']} - ₹${studentData['maxFees']}',
                                  style: TextStyle(fontWeight: FontWeight.bold,color: Colors.purple))
                            ],
                          ),
                        if (studentData['studentSubjects'] != null &&
                            (studentData['studentSubjects'] as List).isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Subjects to study :',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              ...List.generate(
                                (studentData['studentSubjects'] as List).length,
                                (i) {
                                  final subj =
                                      studentData['studentSubjects'][i];
                                  return Text(
                                    '${subj['name']}',
                                    style: TextStyle(fontWeight: FontWeight.bold,color: Colors.purple),
                                  );
                                },
                              ),
                            ],
                          ),
                        
                          
                        SizedBox(
                          height: 20,
                        ),
                        if (studentData['resultDocUrl'] != null)
                          ElevatedButton.icon(
                            icon: const Icon(
                              Icons.picture_as_pdf,
                              color: Colors.white,
                            ),
                            label: const Text('View Last Class Result'),
                            onPressed: () {
                              launchUrl(Uri.parse(studentData['resultDocUrl']));
                            },
                          ),
                        const Divider(),
                      ],
                      ElevatedButton.icon(
                        icon: const Icon(
                          Icons.edit,
                          color: Colors.white,
                        ),
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
                                      return Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Stack(
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(52),
                                              child: Image.network(
                                                // or use Image.asset for local images
                                                'https://static.vecteezy.com/system/resources/previews/046/386/166/non_2x/abstract-blue-and-pink-glowing-lines-curved-overlapping-background-template-premium-award-design-vector.jpg',
                                                height: 60,
                                                width: double.infinity,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                            Container(
                                              height: 60,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(52),
                                                // color: Colors.black.withOpacity(
                                                //     0.1), // dark overlay for contrast
                                              ),
                                            ),
                                            Positioned.fill(
                                                child: Card(
                                              color: Colors.transparent,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(52)),
                                              child: Center(
                                                child: ListTile(
                                                  title: Text(
                                                    data['name'] ?? '',
                                                    style: TextStyle(
                                                        color: Colors.white),
                                                  ),
                                                  // subtitle:
                                                  //     Text('Code: ${data['code']}'),
                                                  trailing: IconButton(
                                                    icon: const Icon(
                                                        Icons.exit_to_app,
                                                        color: Colors.white),
                                                    tooltip: 'Leave Class',
                                                    onPressed: () async {
                                                      final user = FirebaseAuth
                                                          .instance.currentUser;
                                                      if (user == null) return;
                                                      // Remove class from student's joinedClasses
                                                      await FirebaseFirestore
                                                          .instance
                                                          .collection('users')
                                                          .doc(user.uid)
                                                          .update({
                                                        'joinedClasses':
                                                            FieldValue
                                                                .arrayRemove([
                                                          docs[i].id
                                                        ])
                                                      });
                                                      // Remove student from class's joinedStudents and blockedStudents
                                                      await FirebaseFirestore
                                                          .instance
                                                          .collection('classes')
                                                          .doc(docs[i].id)
                                                          .update({
                                                        'joinedStudents':
                                                            FieldValue
                                                                .arrayRemove(
                                                                    [user.uid]),
                                                        'blockedStudents':
                                                            FieldValue
                                                                .arrayRemove(
                                                                    [user.uid]),
                                                      });
                                                      if (context.mounted) {
                                                        ScaffoldMessenger.of(
                                                                context)
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
                                                        await FirebaseFirestore
                                                            .instance
                                                            .collection(
                                                                'classes')
                                                            .doc(docs[i].id)
                                                            .get();
                                                    final classData =
                                                        classDoc.data() ?? {};
                                                    final joined = (classData[
                                                                    'joinedStudents']
                                                                as List<
                                                                    dynamic>? ??
                                                            [])
                                                        .cast<String>();
                                                    final blocked = (classData[
                                                                    'blockedStudents']
                                                                as List<
                                                                    dynamic>? ??
                                                            [])
                                                        .cast<String>();
                                                    if (blocked
                                                        .contains(user.uid)) {
                                                      if (context.mounted) {
                                                        ScaffoldMessenger.of(
                                                                context)
                                                            .showSnackBar(
                                                          const SnackBar(
                                                              content: Text(
                                                                  'You have been blocked from this class by the teacher.')),
                                                        );
                                                      }
                                                      return;
                                                    }
                                                    if (!joined
                                                        .contains(user.uid)) {
                                                      if (context.mounted) {
                                                        ScaffoldMessenger.of(
                                                                context)
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
                                                          className:
                                                              data['name'] ??
                                                                  '',
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ))
                                          ],
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
