import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class teacherside extends StatefulWidget {
  final String classId;
  final String className;
  const teacherside(
      {super.key, required this.classId, required this.className});
  @override
  State<teacherside> createState() => _ScheduleListPageState();
}

class _ScheduleListPageState extends State<teacherside> {
  

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.purple.shade100,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          Text(widget.className,style: TextStyle(fontSize: 18),),
          Text("Schedules",style: TextStyle(color: Colors.purple,fontSize: 16))
        ],
      )),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('classes')
            .doc(widget.classId)
            .collection('schedules')
            .orderBy('dateTime')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final docs = snapshot.data?.docs ?? [];
          final user = FirebaseAuth.instance.currentUser;

          final futureDocs = docs.where((doc) {
            final dt = (doc['dateTime'] as Timestamp?)?.toDate();
            return dt != null && dt.isAfter(now);
          }).toList();
          if (futureDocs.isEmpty) {
            return const Center(child: Text('No future schedules.'));
          }
          return ListView.builder(
            itemCount: futureDocs.length,
            itemBuilder: (context, i) {
              final docRef = futureDocs[i].reference;
              final data = futureDocs[i].data() as Map<String, dynamic>;
              final dt = (data['dateTime'] as Timestamp).toDate();
              final isLink = data['isLink'] == true;
              final description = data['description'] ?? '';
          
              return Dismissible(
                key: ValueKey(docRef.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  color: Colors.red,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete Schedule?'),
                      content: const Text('Are you sure you want to delete this schedule?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                        ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete')),
                      ],
                    ),
                  );
                },
                onDismissed: (direction) async {
                  await docRef.delete();
                  final userDocRef = await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user!.uid)
                      .collection('schedules')
                      .where('class_name', isEqualTo: data['class_name'])
                      .where('dateTime', isEqualTo: data['dateTime'])
                      .limit(1)
                      .get();
                  if (userDocRef.docs.isNotEmpty) {
                    await userDocRef.docs.first.reference.delete();
                  }
                },
                child: 
                (isLink==false)?SizedBox():
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
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
                          color: Colors.black.withOpacity(0.1),
                        ),
                      ),
                      Positioned.fill(
                        child: Card(
                          color: Colors.transparent,
                          child: Center(
                            child: ListTile(
                              title: Row(
                                children: [
                                  Text("Live class of ",style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),)
                                  ,Text(
                                    data['class_name'] ?? '',
                                    style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              subtitle: Row(
                                children: [
                                  Text("Start", style: TextStyle(color: Colors.white)),
                                  if (isLink)
                                    IconButton(
                                      icon: const Icon(Icons.send, color: Colors.white),
                                      onPressed: () async {
                                        if (Uri.tryParse(description)?.hasAbsolutePath ?? false) {
                                          // ignore: deprecated_member_use
                                          await launchUrl(Uri.parse(description));
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Invalid URL')),
                                          );
                                        }
                                      },
                                    ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Scheduled at:\n'
                                    '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
                                    '${TimeOfDay.fromDateTime(dt).format(context)}',
                                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                  
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
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
