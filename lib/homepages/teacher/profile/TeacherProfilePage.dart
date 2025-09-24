import 'package:chat/homepages/teacher/profile/TeacherQualificationsPage.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class TeacherProfilePage extends StatefulWidget {
   TeacherProfilePage({super.key});

  @override
  State<TeacherProfilePage> createState() => _TeacherProfilePageState();
}

class _TeacherProfilePageState extends State<TeacherProfilePage> {
  User? get user => FirebaseAuth.instance.currentUser;

  Future<Map<String, dynamic>?> getTeacherData() async {
    if (user == null) return null;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();
    return doc.data();
  }

  @override
  Widget build(BuildContext context) {
    final teacherUid = user?.uid;
    return Scaffold(
        appBar: AppBar(
          title: Text('My profile'),
         // title: Text('teacher_profile'.tr()),
        ),
        body: teacherUid == null
            ? const Center(child: Text('Not logged in'))
            : FutureBuilder<Map<String, dynamic>?>(
                future: getTeacherData(),
                builder: (context, snapshot) {
                  final data = snapshot.data;

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (data == null) {
                    return const Center(child: Text('No data found.'));
                  }

                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: ListView(
                      children: [
                        // Profile Card
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(200),
                                  border: Border.all(
                                      color: Colors.purple.shade100, width: 2)),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: CircleAvatar(
                                  radius: 52,
                                  backgroundImage: data['photoUrl'] != null
                                      ? NetworkImage(data['photoUrl'])
                                      : null,
                                  child: data['photoUrl'] == null
                                      ? const Icon(Icons.person, size: 40)
                                      : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 5,
                        ),
                        Align(
                          alignment: Alignment.center,
                          child: Text(
                            data['name'] ?? 'Teacher Name',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.center,
                          child: Text(
                            user?.email ?? 'Teacher',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Divider(
                          height: 5,
                        ),
                        const SizedBox(height: 10),

                        // Details Section
                        if (data['description']?.toString().isNotEmpty ?? false)
                          buildInfoTile(
                              Colors.green,
                              const Color.fromARGB(255, 204, 245, 205),
                              'description'.tr(),
                              data['description']),
                        if (data['state']?.toString().isNotEmpty ?? false)
                          buildInfoTile(
                              Colors.blue,
                              const Color.fromARGB(255, 197, 220, 238),
                              'State',
                              data['state']),
                        if (data['college']?.toString().isNotEmpty ?? false)
                          buildInfoTile(
                              Colors.red,
                              const Color.fromARGB(255, 233, 199, 197),
                              'College',
                              data['college']),
                        if (data['qualifications']?.toString().isNotEmpty ??
                            false)
                          buildInfoTile(
                              Colors.yellow,
                              const Color.fromARGB(255, 238, 233, 191),
                              'Qualifications',
                              data['qualifications']),

                        Divider(
                          height: 5,
                        ),

                        if (data['subjects'] != null &&
                            (data['subjects'] as List).isNotEmpty)
                          buildListSection(
                              Colors.purple,
                              const Color.fromARGB(255, 231, 169, 241),
                              'Subjects & Fees',
                              data['subjects']),

                        if (data['classes'] != null &&
                            (data['classes'] as List).isNotEmpty)
                          buildListSection(
                              Colors.purple,
                              const Color.fromARGB(255, 229, 173, 239),
                              'Classes & Fees',
                              data['classes']),

                        const SizedBox(height: 20),
                        const Divider(),

                        if (data['docUrl'] != null)
                          Row(mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                icon: const Icon(Icons.picture_as_pdf,
                                    color: Colors.white),
                                label: const Text(
                                  'View Uploaded Documents',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600),
                                ),
                                onPressed: () =>
                                    launchUrl(Uri.parse(data['docUrl'])),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16, horizontal: 24),
                                ),
                              ),
                            ],
                          ),
                        SizedBox(
                          height: 10,
                        ),
                        // Update Button
                        Row(mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              icon: const Icon(Icons.edit, color: Colors.white),
                              label: const Text(
                                'Update Profile',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => TeacherQualificationsPage(
                                        teacherUid: teacherUid),
                                  ),
                                );
                                setState(() {}); // Refresh on return
                              },
                            ),
                          ],
                        )
                      ],
                    ),
                  );
                },
              ));
  }
}



/// Helper for simple info tiles
Widget buildInfoTile(Color x, Color y, String label, String value) {
  return Padding(
    padding:  EdgeInsets.all(12.0),
    child: Card(
      elevation: 5,
      color: Colors.purple.shade50,
      shadowColor: Colors.purple,
      
      child: Padding(
        padding: EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$label: ',
                style:
                     TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Expanded(
                child: Text(
              value,
              style: TextStyle(color: Colors.purple),
            )),
          ],
        ),
      ),
    ),
  );
}

/// Helper for displaying subject/class with fees
Widget buildListSection(Color x, Color y, String title, List items) {
  return Padding(
    padding: EdgeInsets.all(10),
    child: Card(
      elevation: 5,
      shadowColor: Colors.purple,
      color: Colors.purple.shade50,
      
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                // decoration: TextDecoration.underline,
              ),
            ),
            const SizedBox(height: 6),
            ...items.map((item) => Text(
                  '${item['name']} - ₹${item['fees']}',
                  style: TextStyle(color: Colors.purple),
                )),
          ],
        ),
      ),
    ),
  );
}
