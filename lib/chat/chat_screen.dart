// ---------------- CHAT SCREEN ----------------

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatScreen extends StatefulWidget {
  final String groupId;
  final String groupName;
  ChatScreen({super.key, required this.groupId, required this.groupName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController msgCtrl = TextEditingController();

  void sendMessage() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .collection('messages')
        .add({
      'text': msgCtrl.text.trim(),
      'senderId': uid,
      'timestamp': FieldValue.serverTimestamp(),
    });
    msgCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final messages = FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupName),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: Icon(Icons.group),
              onPressed: () {
                Scaffold.of(context).openEndDrawer();
              },
            ),
          )
        ],
      ),
      endDrawer: MembersDrawer(groupId: widget.groupId), // <-- Add this
      body: Column(
        children: [
          Expanded(
              child: StreamBuilder(
            stream: messages,
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data!.docs;
              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (_, i) {
                  final msg = docs[i];
                  final isMe =
                      msg['senderId'] == FirebaseAuth.instance.currentUser!.uid;
                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(msg['senderId'])
                        .get(),
                    builder: (context, userSnap) {
                      String senderName = "";
                      if (userSnap.hasData && userSnap.data!.exists) {
                        senderName = userSnap.data!.get('name') ?? "Unknown";
                      }
                      return Align(
                        alignment:
                            isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width *
                                0.75, // max 75% of screen
                            minWidth:
                                60, // optional: minimum width for very short messages
                          ),
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 8),
                            padding: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 12),
                            decoration: BoxDecoration(
                              color:
                                  isMe ? const Color(0xFFDCF8C6) : Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: isMe
                                    ? const Radius.circular(16)
                                    : const Radius.circular(0),
                                bottomRight: isMe
                                    ? const Radius.circular(0)
                                    : const Radius.circular(16),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(2, 2),
                                ),
                              ],
                              border: Border.all(
                                color: Colors.grey.withOpacity(0.15),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: isMe
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                Text(
                                  senderName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Color(0xFF075E54),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  msg['text'],
                                  style: const TextStyle(fontSize: 15),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          )),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(2, 2),
                        ),
                      ],
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    ),
                    child: TextField(
                      controller: msgCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Message',
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.teal,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.teal.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(2, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: sendMessage,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

// Drawer widget to show group members
class MembersDrawer extends StatelessWidget {
  final String groupId;
  const MembersDrawer({super.key, required this.groupId});

  Future<void> exitGroup(BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.collection('groups').doc(groupId).update({
      'members': FieldValue.arrayRemove([uid])
    });
    Navigator.pop(context); // Close the drawer
    Navigator.pop(context); // Go back to group list
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("You exited the group")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            const ListTile(
              leading: Icon(Icons.group),
              title: Text("Group Members"),
            ),
            Expanded(
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('groups')
                    .doc(groupId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const Center(child: CircularProgressIndicator());

                  final members = snapshot.data!['members'] as List<dynamic>;
                  final creatorUid = snapshot.data!['creator'];

                  return ListView.builder(
                    itemCount: members.length,
                    itemBuilder: (context, index) {
                      final uid = members[index];
                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(uid)
                            .get(),
                        builder: (context, userSnap) {
                          if (!userSnap.hasData)
                            return ListTile(title: Text(uid));
                          final userName =
                              userSnap.data!.get('name') ?? 'No name';
                          final userEmail =
                              userSnap.data!.get('email') ?? 'No email';
                          final isCurrentUserCreator =
                              FirebaseAuth.instance.currentUser!.uid ==
                                  creatorUid;
                          final isSelf =
                              FirebaseAuth.instance.currentUser!.uid == uid;

                          return ListTile(
                            leading: const Icon(Icons.person),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    userName,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (uid == creatorUid)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 6),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.teal[100],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        "admin",
                                        style: TextStyle(
                                          color: Colors.teal,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Text(
                              userEmail,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: isCurrentUserCreator && !isSelf
                                ? IconButton(
                                    icon: const Icon(Icons.remove_circle,
                                        color: Colors.red),
                                    tooltip: "Remove from group",
                                    onPressed: () async {
                                      await FirebaseFirestore.instance
                                          .collection('groups')
                                          .doc(groupId)
                                          .update({
                                        'members': FieldValue.arrayRemove([uid])
                                      });
                                      // Optionally, force a UI update
                                      (context as Element).markNeedsBuild();
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                "Removed $userName from group")),
                                      );
                                    },
                                  )
                                : null,
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(40),
                ),
                icon: const Icon(Icons.exit_to_app),
                label: const Text("Exit Group"),
                onPressed: () => exitGroup(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
