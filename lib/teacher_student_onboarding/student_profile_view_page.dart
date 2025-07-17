import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class StudentProfileViewPage extends StatelessWidget {
  final String studentUid;
  const StudentProfileViewPage({super.key, required this.studentUid});

  Future<Map<String, dynamic>?> getStudentData() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(studentUid)
        .get();
    return doc.data();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Details')),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: getStudentData(),
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
                            data['name'] ?? 'Student Name',
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
                if (data['studentClass'] != null && data['studentClass'].toString().isNotEmpty)
                  Text('Class: ${data['studentClass']}'),
                if (data['studentSubjects'] != null &&
                    (data['studentSubjects'] as List).isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Subjects:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      ...List.generate(
                        (data['studentSubjects'] as List).length,
                        (i) {
                          final subj = data['studentSubjects'][i];
                          return Text('${subj['name']}');
                        },
                      ),
                    ],
                  ),
                if (data['minFees'] != null && data['maxFees'] != null)
                  Text('Fees Range: ₹${data['minFees']} - ₹${data['maxFees']}'),
                if (data['resultDocUrl'] != null)
                  TextButton.icon(
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('View Last Class Result'),
                    onPressed: () {
                      launchUrl(Uri.parse(data['resultDocUrl']));
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