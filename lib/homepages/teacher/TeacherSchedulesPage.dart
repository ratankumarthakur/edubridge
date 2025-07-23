import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class TeacherSchedulesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return Scaffold(
        body: Center(child: Text('User not signed in')),
      );
    }

    final scheduleStream = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('schedules')
        .orderBy('dateTime')
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: Text('My Schedules')),
      body: StreamBuilder<QuerySnapshot>(
        stream: scheduleStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(child: Text('No schedules found.'));
          }

          return ListView.builder(
            
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final timestamp = data['dateTime'] as Timestamp?;
              final dateTime = timestamp?.toDate();

              final formattedTime = dateTime != null
                  ? DateFormat('dd-MM-yy  HH:mm').format(dateTime)
                  : 'Not set';

              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network( // or use Image.asset for local images
                        'https://static.vecteezy.com/system/resources/previews/046/386/166/non_2x/abstract-blue-and-pink-glowing-lines-curved-overlapping-background-template-premium-award-design-vector.jpg',
                        height: 100,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Container(
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.black.withOpacity(0.1), // dark overlay for contrast
                      ),
                    ),
                    Positioned.fill(
                      child: Card(
                        color: Colors.transparent,
                        elevation: 6,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Center(
                          child: ListTile(
                            title: Text(
                              data['class_name'] ?? 'Unnamed Class',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 10,),
                                          Text(
                                            'Description: ${data['description'] ?? 'N/A'}',
                                            style: const TextStyle(fontSize: 13,color: Colors.white70),
                                          ),
                                          Text(
                                            'Scheduled at: $formattedTime',
                                            style: const TextStyle(fontSize: 13,color: Colors.white),
                                          ),
                              ],
                            ),
                          ),
                        ),
                      ),
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
