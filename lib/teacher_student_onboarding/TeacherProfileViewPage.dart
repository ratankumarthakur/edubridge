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
      appBar: AppBar(
        title: const Text('Teacher Details'),
      ),
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
                            data['name'] ?? 'Teacher Name',
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

              // Description, state, college, etc.
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (data['description']?.toString().isNotEmpty ?? false)
                        Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(
                                text: '📝 Description: ',
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text: data['description'],
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      //if (data['state']?.toString().isNotEmpty ?? false)
                      const SizedBox(height: 8),
                      if (data['state']?.toString().isNotEmpty ?? false)
                        Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(
                                text: '📍 State: ',
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text: data['state'],
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),

                      //if (data['college']?.toString().isNotEmpty ?? false)
                      const SizedBox(height: 8),
                      if (data['college']?.toString().isNotEmpty ?? false)
                        Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(
                                text: '🏫 College: ',
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text: data['college'],
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),

                      // if (data['qualifications']?.toString().isNotEmpty ??
                      //    false)
                      const SizedBox(height: 8),
                      if (data['qualifications']?.toString().isNotEmpty ??
                          false)
                        Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(
                                text: '🎓 Qualifications: ',
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text: data['qualifications'],
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Subjects & Classes
              if (data['subjects'] != null &&
                  (data['subjects'] as List).isNotEmpty)
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
                        const Text('📚 Subjects & Fees:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ...List.generate(
                          (data['subjects'] as List).length,
                          (i) {
                            final subj = data['subjects'][i];
                            return Text('• ${subj['name']} – ₹${subj['fees']}');
                          },
                        ),
                      ],
                    ),
                  ),
                ),

              if (data['classes'] != null &&
                  (data['classes'] as List).isNotEmpty)
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
                        const Text('🎒 Classes & Fees:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ...List.generate(
                          (data['classes'] as List).length,
                          (i) {
                            final cls = data['classes'][i];
                            return Text('• ${cls['name']} – ₹${cls['fees']}');
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              // Document Button
              if (data['docUrl'] != null)
                Row(mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(
                        Icons.picture_as_pdf,
                        color: Colors.white,
                      ),
                      label: const Text('View Documents'),
                      onPressed: () {
                        launchUrl(Uri.parse(data['docUrl']));
                      },
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
