import 'package:avatar_glow/avatar_glow.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class ScheduleListPage extends StatefulWidget {
  final String classId;
  final String className;
  const ScheduleListPage(
      {super.key, required this.classId, required this.className});

  @override
  State<ScheduleListPage> createState() => _ScheduleListPageState();
}

class _ScheduleListPageState extends State<ScheduleListPage> {
  Future<void> _addSchedule() async {
    DateTime? pickedDate;
    TimeOfDay? pickedTime;
    String description = '';
    bool isLink = false;
    await showDialog(
      context: context,
      builder: (context) {
        final descCtrl = TextEditingController();
        return StatefulBuilder(
          builder: (context, setStateDialog) => AlertDialog(
            title: const Text('Add Schedule'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text(pickedDate == null
                      ? 'Pick Date'
                      : '${pickedDate!.year}-${pickedDate!.month.toString().padLeft(2, '0')}-${pickedDate!.day.toString().padLeft(2, '0')}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final now = DateTime.now();
                    final date = await showDatePicker(
                      context: context,
                      initialDate: now,
                      firstDate: now,
                      lastDate: DateTime(now.year + 5),
                    );
                    if (date != null) setStateDialog(() => pickedDate = date);
                  },
                ),
                ListTile(
                  title: Text(pickedTime == null
                      ? 'Pick Time'
                      : pickedTime!.format(context)),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (time != null) setStateDialog(() => pickedTime = time);
                  },
                ),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Description'),
                  onChanged: (val) => description = val,
                ),
                Row(
                  children: [
                    const Text('Is Link?'),
                    Switch(
                      value: isLink,
                      onChanged: (val) {
                        setStateDialog(() => isLink = val);
                      },
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (pickedDate == null || pickedTime == null) return;
                  final dt = DateTime(
                    pickedDate!.year,
                    pickedDate!.month,
                    pickedDate!.day,
                    pickedTime!.hour,
                    pickedTime!.minute,
                  );
                  final userId = FirebaseAuth.instance.currentUser?.uid;

                  await FirebaseFirestore.instance
                      .collection('classes')
                      .doc(widget.classId)
                      .collection('schedules')
                      .add({
                    'class_name': widget.className,
                    'dateTime': dt,
                    'description': descCtrl.text,
                    'isLink': isLink,
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .collection('schedules')
                      .add({
                    'class_name': widget.className,
                    'dateTime': dt,
                    'description': descCtrl.text,
                    'isLink': isLink,
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );
  }

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
                child: Padding(
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
                              title: Text(
                                data['class_name'] ?? '',
                                style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                              subtitle: Row(
                                children: [
                                  Text(description, style: TextStyle(color: Colors.white70)),
                                  if (isLink)
                                    IconButton(
                                      icon: const Icon(Icons.link, color: Colors.white),
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
      
      floatingActionButton: AvatarGlow(
        glowColor: Colors.purple,
        duration: Duration(milliseconds: 2000),
        repeat: true,
        child: FloatingActionButton(
            backgroundColor: Colors.white,
            shape: CircleBorder(),
            onPressed:_addSchedule,
            child: Padding(
                padding: const EdgeInsets.all(8.0), child: Icon(Icons.add))),
      ),
    );
  }
}
