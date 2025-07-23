import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'TeacherProfileViewPage.dart';

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
      appBar: AppBar(
  flexibleSpace: Stack(
    fit: StackFit.expand,
    children: [
      
    ],
  ),
  
  elevation: 0,
  leading: IconButton(
    onPressed: () => Navigator.pop(context),
    icon: const Icon(Icons.arrow_back),
   
  ),
  title: const Text(
    'List of Teachers',
    
  ),
),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
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
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  "Filter by",
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(
                  width: 10,
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 173, 5, 245)
                        .withValues(alpha: 0.1), // light background hint
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(
                        color: const Color.fromARGB(255, 169, 5, 245),
                        width: 2),
                  ),
                  child: DropdownButton<String>(
                    focusColor: Colors.transparent,
                    value: sortType,
                    items: const [
                      DropdownMenuItem(
                          value: 'latest', child: Text('Latest Joined')),
                      DropdownMenuItem(
                          value: 'earliest',
                          child: Text('Earliest Joined')), // <-- add this
                      DropdownMenuItem(
                          value: 'alphabetical', child: Text('A-Z')),
                    ],
                    onChanged: (val) => setState(() => sortType = val!),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Divider(
              indent: 2,
              color: Colors.purple,
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
                  return Center(
                      child: SizedBox(
                        height: 40,
                        width: 40,
                        child: ShaderMask(
                          shaderCallback: (bounds) => SweepGradient(
                            colors: [
                              Colors.purple,
                              Colors.pink,
                             // Colors.lightGreen
                            ],
                            startAngle: 0.0,
                            endAngle: 3.14 * 2,
                          ).createShader(bounds),
                          child:
                              const CircularProgressIndicator(strokeWidth: 4),
                        ),
                      ),
                      );
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

                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset( 'assets/background.jpg',height: 100,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Container(
                            height: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.black.withValues(alpha: 0.1)// dark overlay for contrast
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
                                      style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Text(
                                      data['email'] ?? '',
                                      style: TextStyle(
                                          fontSize: 10, color: Colors.white),
                                    ),
                                    trailing: data['createdAt'] != null
                                        ? Text(
                                            'Teaching since - ${_formatDate(data['createdAt'])}',
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.white),
                                          )
                                        : const SizedBox(),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => TeacherProfileViewPage(
                                              teacherUid: docs[i].id),
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
              Navigator.pushNamed(context, '/student_list_page');
            },
            child: Padding(
                padding: const EdgeInsets.all(8.0), child: Icon(Icons.group))),
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
