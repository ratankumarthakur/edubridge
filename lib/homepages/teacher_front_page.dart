import 'package:chat/homepages/TeacherQualificationsPage.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
//import 'teacher_class_actions_page.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:url_launcher/url_launcher.dart';

class TeacherFrontPage extends StatefulWidget {
  const TeacherFrontPage({super.key});

  @override
  State<TeacherFrontPage> createState() => _TeacherFrontPageState();
}

class _TeacherFrontPageState extends State<TeacherFrontPage> {
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
        title: Text('teacher_profile'.tr()),
        actions: [
          PopupMenuButton<Locale>(
            icon: const Icon(Icons.language),
            onSelected: (locale) {
              context.setLocale(locale);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: Locale('en'),
                child: Text('English'),
              ),
              const PopupMenuItem(
                value: Locale('hi'),
                child: Text('हिन्दी'),
              ),
            ],
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
      body: teacherUid == null
          ? const Center(child: Text('Not logged in'))
          : FutureBuilder<Map<String, dynamic>?>(
              future: getTeacherData(),
              builder: (context, snapshot) {
                final data = snapshot.data;
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
                            backgroundImage: data?['photoUrl'] != null
                                ? NetworkImage(data!['photoUrl'])
                                : null,
                            child: data?['photoUrl'] == null
                                ? const Icon(Icons.person, size: 40)
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data?['name'] ?? 'Teacher Name',
                                  style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  user?.email ?? 'Teacher',
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
                      if (data != null) ...[
                        if (data['description'] != null &&
                            data['description'].toString().isNotEmpty)
                          Text('${'description'.tr()}:${data['description']}'),
                        if (data['state'] != null &&
                            data['state'].toString().isNotEmpty)
                          Text('${'state'.tr()}: ${data['state']}'),
                        if (data['college'] != null &&
                            data['college'].toString().isNotEmpty)
                          Text('${'college'.tr()}: ${data['college']}'),
                        if (data['qualifications'] != null &&
                            data['qualifications'].toString().isNotEmpty)
                          Text(
                              '${'qualifications'.tr()}: ${data['qualifications']}'),
                        if (data['docUrl'] != null)
                          TextButton.icon(
                            icon: const Icon(Icons.picture_as_pdf),
                            label: const Text('View Document'),
                            onPressed: () {
                              launchUrl(Uri.parse(data['docUrl']));
                            },
                          ),
                        if (data['subjects'] != null &&
                            (data['subjects'] as List).isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${'subjects_fees'.tr()}:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              ...List.generate(
                                (data['subjects'] as List).length,
                                (i) {
                                  final subj = data['subjects'][i];
                                  return Text(
                                      '${subj['name']} - ₹${subj['fees']}');
                                },
                              ),
                            ],
                          ),
                        if (data['classes'] != null &&
                            (data['classes'] as List).isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${'classes_fees'.tr()}:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              ...List.generate(
                                (data['classes'] as List).length,
                                (i) {
                                  final cls = data['classes'][i];
                                  return Text(
                                      '${cls['name']} - ₹${cls['fees']}');
                                },
                              ),
                            ],
                          ),
                        const Divider(),
                      ],
                      ElevatedButton.icon(
                        icon: const Icon(Icons.school),
                        label: Text('${'update'.tr()}:'),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TeacherQualificationsPage(
                                  teacherUid: teacherUid),
                            ),
                          );
                          // Refresh the profile page after returning
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
