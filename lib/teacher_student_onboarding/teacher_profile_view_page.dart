import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class TeacherProfileViewPage extends StatelessWidget {
  final String teacherUid;
  const TeacherProfileViewPage({super.key, required this.teacherUid});

  Future<Map<String, dynamic>?> getTeacherData() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(teacherUid)
        .get();
    return doc.data();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Teacher Details')),
      body: FutureBuilder<Map<String, dynamic>?>(
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
                Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundImage: data['photoUrl'] != null
                          ? NetworkImage(data['photoUrl'])
                          : null,
                      child: data['photoUrl'] == null
                          ? const Icon(Icons.person, size: 40)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['name'] ?? 'Teacher Name',
                            style: const TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            data['email'] ?? '',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (data['description'] != null && data['description'].toString().isNotEmpty)
                  Text('Description: ${data['description']}'),
                if (data['state'] != null && data['state'].toString().isNotEmpty)
                  Text('State: ${data['state']}'),
                if (data['college'] != null && data['college'].toString().isNotEmpty)
                  Text('College: ${data['college']}'),
                if (data['qualifications'] != null && data['qualifications'].toString().isNotEmpty)
                  Text('Qualifications: ${data['qualifications']}'),
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
                      const Text(
                        'Subjects & Fees:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      ...List.generate(
                        (data['subjects'] as List).length,
                        (i) {
                          final subj = data['subjects'][i];
                          return Text('${subj['name']} - ₹${subj['fees']}');
                        },
                      ),
                    ],
                  ),
                if (data['classes'] != null &&
                    (data['classes'] as List).isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Classes & Fees:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      ...List.generate(
                        (data['classes'] as List).length,
                        (i) {
                          final cls = data['classes'][i];
                          return Text('${cls['name']} - ₹${cls['fees']}');
                        },
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}