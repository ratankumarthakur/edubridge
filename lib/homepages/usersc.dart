import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';


class UserSchedulesPage extends StatelessWidget {
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



              return Card(
                child: ListTile(
                  title: Text(data['class_name'] ?? 'Unnamed Class'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Description: ${data['description'] ?? 'N/A'}'),
                      // Text('Date: ${data['dateTime'] != null 
                      //   ? (data['dateTime'] as Timestamp).toDate().toLocal().toString().split(' ')[0] 
                      //   : 'Not set'}'),
                      Text('Scheduled at: $formattedTime')
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}