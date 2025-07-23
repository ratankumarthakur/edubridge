import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'StudentProfileViewPage.dart'; // <-- Make sure this exists

class StudentsListPage extends StatefulWidget {
  const StudentsListPage({super.key});

  @override
  State<StudentsListPage> createState() => _StudentsListPageState();
}

class _StudentsListPageState extends State<StudentsListPage> {
  String searchText = '';
  String searchType = 'name';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('List of Students')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(flex: 2,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(color: Colors.green, width: 2),
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: searchType == 'name'
                            ? 'Search by Name'
                            : 'Search by Email',
                        hintStyle: const TextStyle(
                            fontSize: 14, color: Colors.black54),
                        border: InputBorder.none,
                        icon: const Icon(Icons.search, color: Colors.green),
                      ),
                      style: const TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      onChanged: (value) {
                        setState(() => searchText = value.trim());
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(flex: 1,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
                    decoration: BoxDecoration(
                      color:
                          Colors.green.withValues(alpha: 0.1), // light background hint
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(color: Colors.green, width: 2),
                    ),
                    child: Center(
                      child: DropdownButton<String>(
                        underline: null,
                        focusColor: Colors.transparent,
                        value: searchType,
                        items: const [
                          DropdownMenuItem(value: 'name', child: Text('Name')),
                          DropdownMenuItem(value: 'email', child: Text('Email')),
                        ],
                        onChanged: (val) => setState(() => searchType = val!),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'student')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                List docs = snapshot.data?.docs ?? [];
                // Filter by search
                if (searchText.isNotEmpty) {
                  docs = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final value =
                        (data[searchType] ?? '').toString().toLowerCase();
                    return value.contains(searchText);
                  }).toList();
                }
                if (docs.isEmpty) {
                  return const Center(child: Text('No students found.'));
                }
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final data = docs[i].data() as Map<String, dynamic>;

                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: 
                              // or use Image.asset for local images
                              Image.asset( 'assets/background.jpg',
                              height: 100,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Container(
                            height: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.black.withValues(alpha: 0.1) // dark overlay for contrast
                            ),
                          ),
                          Positioned.fill(
                            child: Card(
                                color: Colors.transparent,
                                elevation: 6,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                child: Center(
                                  child: ListTile(
                                    leading: const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                    ),
                                    title: Text(
                                      data['name'] ?? 'No Name',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Text(
                                      data['email'] ?? '',
                                      style: TextStyle(
                                          fontSize: 15, color: Colors.white),
                                    ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              StudentProfileViewPage(
                                                  studentUid: docs[i].id),
                                        ),
                                      );
                                    },
                                  ),
                                )),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: AvatarGlow(
        glowColor: Colors.purple,
        duration: Duration(milliseconds: 2000),
        repeat: true,
        child: FloatingActionButton(
            backgroundColor: Colors.white,
            shape: CircleBorder(),
            onPressed: () {
              Navigator.pushNamed(context, '/teacher_list_page');
            },
            child: Padding(
                padding: const EdgeInsets.all(8.0), child: Icon(Icons.group))),
      ),
    );
  }
}
