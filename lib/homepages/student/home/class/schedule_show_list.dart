import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduleShowListPage extends StatefulWidget {
  final String classId;
  final String className;
  const ScheduleShowListPage({super.key, required this.classId, required this.className});

  @override
  State<ScheduleShowListPage> createState() => _ScheduleShowListPageState();
}

class _ScheduleShowListPageState extends State<ScheduleShowListPage> {
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
                  await FirebaseFirestore.instance
                      .collection('classes')
                      .doc(widget.classId)
                      .collection('schedules')
                      .add({
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
      appBar: AppBar(title: Text('${widget.className}\nSchedules ')),
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
                  subtitle: SelectableText(data['description'] ?? ''),
                ),
              );
            },
          );
        },
      ),
      // bottomNavigationBar: Padding(
      //   padding: const EdgeInsets.all(16),
      //   child: ElevatedButton.icon(
      //     icon: const Icon(Icons.add),
      //     label: const Text('Add New Schedule'),
      //     onPressed: _addSchedule,
      //   ),
      // ),
    );
  }
}