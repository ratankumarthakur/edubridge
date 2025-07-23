import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'teacher_class_actions_page.dart';

class TClass extends StatefulWidget {
  const TClass({super.key});

  @override
  State<TClass> createState() => _TClassState();
}

class _TClassState extends State<TClass> {
  User? get user => FirebaseAuth.instance.currentUser;

  Future<Map<String, dynamic>?> getTeacherData() async {
    if (user == null) return null;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();
    return doc.data();
  }

  Future<void> _showCreateClassDialog() async {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Class'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Class Name'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Enter class name' : null,
              ),
              TextFormField(
                controller: codeCtrl,
                decoration:
                    const InputDecoration(labelText: 'Unique Class Code'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Enter unique code' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                // Check if code is unique
                final codeSnap = await FirebaseFirestore.instance
                    .collection('classes')
                    .where('name', isEqualTo: nameCtrl.text.trim())
                    .get();
                if (codeSnap.docs.isNotEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'This class name already exists! Choose another.')),
                  );
                  return;
                }
                Navigator.pop(context, true);
                // Save class
                await FirebaseFirestore.instance.collection('classes').add({
                  'name': nameCtrl.text.trim(),
                  'code': codeCtrl.text.trim(),
                  'teacherUid': user?.uid,
                  'createdAt': FieldValue.serverTimestamp(),
                });
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Class created!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final teacherUid = user?.uid;
    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Your Classes:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          
        ),
        body: Column(children: [
          // ElevatedButton.icon(
          //   icon: const Icon(Icons.add),
          //   label: const Text('Create New Class'),
          //   onPressed: _showCreateClassDialog,
          // ),
          // SizedBox(height: 24),
          
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(mainAxisAlignment:MainAxisAlignment.end ,children: [Text("Swipe to delete a class",style: TextStyle(color: Colors.red),)],),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('classes')
                  .where('teacherUid', isEqualTo: teacherUid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final docs = snapshot.data?.docs ?? [];
                docs.sort((a, b) {
                  final aTime = (a['createdAt'] as Timestamp?)?.toDate() ??
                      DateTime(1970);
                  final bTime = (b['createdAt'] as Timestamp?)?.toDate() ??
                      DateTime(1970);
                  return bTime.compareTo(aTime); // descending
                });
                if (docs.isEmpty) {
                  return const Center(child: Text('No classes created yet.'));
                }
                return ListView.builder(
  itemCount: docs.length,
  itemBuilder: (context, i) {
    final data = docs[i].data() as Map<String, dynamic>;
    final docId = docs[i].id;

    return Dismissible(
      key: Key(docId),
      direction: DismissDirection.endToStart, // swipe left to delete
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('Delete Class'),
            content: Text('Are you sure you want to delete "${data['name']}"?'),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text('Cancel')),
              TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text('Delete')),
            ],
          ),
        );
      },
      onDismissed: (direction) async {
        await FirebaseFirestore.instance.collection('classes').doc(docId).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Class "${data['name']}" deleted')),
        );
      },
      child: Padding(
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
                          color: Colors.black.withOpacity(0.1), // dark overlay for contrast
                        ),
                      ),
                      Positioned.fill(
                        child: Card(
                          color: Colors.transparent,
          child: Center(
            child: ListTile(
              title: Text(data['name'] ?? '',style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),),
              //subtitle: Text('Code: ${data['code']}',style: TextStyle(color: Colors.white)),
              trailing: Column(
                spacing: 5,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Created on: ${data['createdAt'] != null 
                      ? (data['createdAt'] as Timestamp).toDate().toLocal().toString().split(' ')[0] 
                      : 'Unknown'}',
                      style: TextStyle(fontSize: 12,fontWeight: FontWeight.w800,color: Colors.white)
                    
                  ),
                  Text(
                    'Joined: ${(data['joinedStudents'] as List?)?.length ?? 0}',
                    style: TextStyle(fontSize: 12,color: Colors.white),
                  ),
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TeacherClassActionsPage(
                      classId: docId,
                      className: data['name'] ?? '',
                    ),
                  ),
                );
              },
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
          ),
        ]),
        floatingActionButton: AvatarGlow(
        glowColor: Colors.purple,
        // endRadius: 60.0,
        duration: Duration(milliseconds: 2000),
        repeat: true,
        child: FloatingActionButton(
            backgroundColor: Colors.white,
            shape: CircleBorder(),
            onPressed:(){_showCreateClassDialog();},
           // onPressed: () => Navigator.pushNamed(context, '/teacher_list_page'),
            child: Icon(Icons.add)),
      ),
        );
  }
}
