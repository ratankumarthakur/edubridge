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

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Gradient header with avatar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [Colors.deepPurple, Colors.purpleAccent],
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: data['photoUrl'] != null
                          ? NetworkImage(data['photoUrl'])
                          : null,
                      child: data['photoUrl'] == null
                          ? const Icon(Icons.person,
                              size: 40, color: Colors.white)
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
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            data['email'] ?? '',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (data['studentClass']?.toString().isNotEmpty ?? false)
                        Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(
                                text: '🏷 Class: ',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text: data['studentClass'],
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      if (data['minFees'] != null && data['maxFees'] != null)
                        const SizedBox(height: 8),
                      if (data['minFees'] != null && data['maxFees'] != null)
                        Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(
                                text: '💸 Fees Range: ',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text:
                                    '₹${data['minFees']} - ₹${data['maxFees']}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              if (data['studentSubjects'] != null &&
                  (data['studentSubjects'] as List).isNotEmpty)
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('📚 Subjects:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ...List.generate(
                          (data['studentSubjects'] as List).length,
                          (i) {
                            final subj = data['studentSubjects'][i];
                            return Text('• ${subj['name']}');
                          },
                        ),
                      ],
                    ),
                  ),
                ),

              if (data['resultDocUrl'] != null)
                Row(mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: ElevatedButton.icon(
                        icon: const Icon(
                          Icons.picture_as_pdf,
                          color: Colors.white,
                        ),
                        label: const Text('View Last Class Result'),
                        onPressed: () {
                          //print(data['resultDocUrl']);
                          launchUrl(Uri.parse(data['resultDocUrl']));
                        },
                      ),
                    ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}
