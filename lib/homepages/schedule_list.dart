import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .collection('schedules')
                      .add({
                    //'class_name': widget.className,
                    'dateTime': dt,
                    'description': descCtrl.text,
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
      appBar: AppBar(title: Text('${widget.className} Schedules')),
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
              final data = futureDocs[i].data() as Map<String, dynamic>;
              final dt = (data['dateTime'] as Timestamp).toDate();
              return Card(
                child: ListTile(
                  title: Text(
                    '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
                    '${TimeOfDay.fromDateTime(dt).format(context)}',
                  ),
                  subtitle: Text(data['description'] ?? ''),
                  // trailing: Text(data['class_name'] ?? ''),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(data['class_name'] ?? ''),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          await futureDocs[i].reference.delete();
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Add New Schedule'),
          onPressed: _addSchedule,
        ),
      ),
    );
  }
}
