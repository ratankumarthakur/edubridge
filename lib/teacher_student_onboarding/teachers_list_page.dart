import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'teacher_profile_view_page.dart';

class TeachersListPage extends StatefulWidget {
  const TeachersListPage({super.key});

  @override
  State<TeachersListPage> createState() => _TeachersListPageState();
}

class _TeachersListPageState extends State<TeachersListPage> {
  String searchText = '';
  String searchType = 'name'; // or 'email'
  String sortType = 'latest'; // or 'alphabetical'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Teachers')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: searchType == 'name'
                          ? 'Search by Name'
                          : 'Search by Email',
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (val) =>
                        setState(() => searchText = val.trim().toLowerCase()),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: searchType,
                  items: const [
                    DropdownMenuItem(value: 'name', child: Text('Name')),
                    
                    DropdownMenuItem(value: 'email', child: Text('Email')),
                  ],
                  onChanged: (val) => setState(() => searchType = val!),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: sortType,
                  items: const [
                    DropdownMenuItem(
                        value: 'latest', child: Text('Latest Joined')),
                    DropdownMenuItem(value: 'earliest', child: Text('Earliest Joined')), // <-- add this
                    DropdownMenuItem(value: 'alphabetical', child: Text('A-Z')),
                  ],
                  onChanged: (val) => setState(() => sortType = val!),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'teacher')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                List docs = snapshot.data?.docs ?? [];
                // Filter
                if (searchText.isNotEmpty) {
                  docs = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final value =
                        (data[searchType] ?? '').toString().toLowerCase();
                    return value.contains(searchText);
                  }).toList();
                }
                // Sort
                if (sortType == 'alphabetical') {
                  docs.sort((a, b) {
                    final aname =
                        (a.data() as Map<String, dynamic>)['name'] ?? '';
                    final bname =
                        (b.data() as Map<String, dynamic>)['name'] ?? '';
                    return aname
                        .toString()
                        .toLowerCase()
                        .compareTo(bname.toString().toLowerCase());
                  });
                } else if (sortType == 'earliest') {
                  docs.sort((a, b) {
                    final atime =
                        (a.data() as Map<String, dynamic>)['createdAt'];
                    final btime =
                        (b.data() as Map<String, dynamic>)['createdAt'];
                    if (atime == null || btime == null) return 0;
                    return (atime as Timestamp)
                        .compareTo(btime as Timestamp); // ascending
                  });
                } else {
                  docs.sort((a, b) {
                    final atime =
                        (a.data() as Map<String, dynamic>)['createdAt'];
                    final btime =
                        (b.data() as Map<String, dynamic>)['createdAt'];
                    if (atime == null || btime == null) return 0;
                    return (btime as Timestamp).compareTo(atime as Timestamp);
                  });
                }
                if (docs.isEmpty) {
                  return const Center(child: Text('No teachers found.'));
                }
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    return ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(data['name'] ?? 'No Name'),
                      subtitle: Text(data['email'] ?? ''),
                      trailing: data['createdAt'] != null
                          ? Text(
                              'Teaching since - ${_formatDate(data['createdAt'])}',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            )
                          : const SizedBox(),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                TeacherProfileViewPage(teacherUid: docs[i].id),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),

        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/student_list_page');
        },
        child: const Icon(Icons.people),
        tooltip: 'View All Students',
        backgroundColor: Colors.teal,
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    final date = (timestamp as Timestamp).toDate();
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day-$month-$year';
  }
}
