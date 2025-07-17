// ---------------- GROUP LIST SCREEN ----------------

import 'package:chat/chat/chat_screen.dart';
import 'package:chat/chat/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GroupListScreen extends StatelessWidget {
  final TextEditingController groupCtrl = TextEditingController();
  final uid = FirebaseAuth.instance.currentUser!.uid;

  GroupListScreen({super.key});

  Future<void> createGroup(BuildContext context, String groupCode) async {
    final groupRef = FirebaseFirestore.instance.collection('groups').doc();

    // Optionally, check if code is unique
    final existing = await FirebaseFirestore.instance
        .collection('groups')
        .where('code', isEqualTo: groupCode)
        .get();
    if (existing.docs.isNotEmpty) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Group code already exists. Choose another.")),
      );
      return;
    }

    await groupRef.set({
      'name': groupCtrl.text.trim(),
      'members': [uid],
      'code': groupCode,
      'creator': uid,
    });

    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Group Created"),
        content: Text("Share this group code: $groupCode"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text("OK")),
        ],
      ),
    );
  }

  Future<void> joinGroupByCode(BuildContext context) async {
    final joinCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Enter Group Code"),
        content: TextField(
            controller: joinCtrl,
            decoration: const InputDecoration(hintText: "e.g. a1b2c3")),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              final code = joinCtrl.text.trim();
              final query = await FirebaseFirestore.instance
                  .collection('groups')
                  .where('code', isEqualTo: code)
                  .get();

              if (query.docs.isNotEmpty) {
                final doc = query.docs.first;
                final groupId = doc.id;

                await FirebaseFirestore.instance
                    .collection('groups')
                    .doc(groupId)
                    .update({
                  'members': FieldValue.arrayUnion([uid])
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Joined group ${doc['name']}")));
              } else {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Group not found")));
              }
            },
            child: const Text("Join"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupsStream = FirebaseFirestore.instance
        .collection('groups')
        .where('members', arrayContains: uid)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Groups"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (_) => LoginScreen()));
            },
          )
        ],
      ),
      body: StreamBuilder(
        stream: groupsStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final groups = snapshot.data!.docs;
          return ListView.builder(
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              return ListTile(
                title: Text(group['name']),
                subtitle: Text("Code: ${group['code']}"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => ChatScreen(
                            groupId: group.id, groupName: group['name'])),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: "create",
            onPressed: () => showDialog(
              context: context,
              builder: (_) {
                final codeCtrl = TextEditingController();
                return AlertDialog(
                  title: const Text("Create Group"),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: groupCtrl,
                        decoration:
                            const InputDecoration(hintText: "Group name"),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: codeCtrl,
                        decoration: const InputDecoration(
                            hintText: "Group code (e.g. mygroup123)"),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel")),
                    TextButton(
                      onPressed: () =>
                          createGroup(context, codeCtrl.text.trim()),
                      child: const Text("Create"),
                    ),
                  ],
                );
              },
            ),
            label: const Text("Create"),
            icon: const Icon(Icons.add),
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: "join",
            onPressed: () => joinGroupByCode(context),
            label: const Text("Join"),
            icon: const Icon(Icons.group_add),
          ),
        ],
      ),
    );
  }
}