import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ClassChatPage extends StatefulWidget {
  final String classId;
  //final String userId;

  const ClassChatPage({
    super.key,
    required this.classId,
    //required this.userId,
  });

  @override
  State<ClassChatPage> createState() => _ClassChatPageState();
}

class _ClassChatPageState extends State<ClassChatPage> {
  final _controller = TextEditingController();
  final _user = FirebaseAuth.instance.currentUser;
  final Map<String, String> _usernamesCache = {};
  String? _adminUid;

  Future<Widget> _buildSenderName(String senderUid) async {
    if (_usernamesCache.containsKey(senderUid)) {
      return Text(
        _usernamesCache[senderUid]!,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: isAdmin(senderUid) ? Colors.deepPurple : Colors.grey[800],
        ),
      );
    }
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(senderUid)
        .get();
    final name = doc.exists ? (doc.data()?['name'] ?? 'User') : 'User';
    _usernamesCache[senderUid] = name;
    return Text(
      name,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 14,
        color: isAdmin(senderUid) ? Colors.deepPurple : Colors.grey[800],
      ),
    );
  }

  FutureBuilder<Widget> senderNameWidget(String senderUid) {
    return FutureBuilder<Widget>(
      future: _buildSenderName(senderUid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          return snapshot.data!;
        } else {
          return const SizedBox(
              height: 16,
              width: 80,
              child: LinearProgressIndicator(minHeight: 2));
        }
      },
    );
  }

  Future<void> createChatRoomIfNeeded() async {
    final chatRoomRef =
        FirebaseFirestore.instance.collection('chatRooms').doc(widget.classId);
    final chatRoomDoc = await chatRoomRef.get();

    if (!chatRoomDoc.exists) {
      final classDoc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .get();
      final data = classDoc.data();
      if (data == null) return;

      final teacherUid = data['teacherUid'];
      final studentUids = List<String>.from(data['joinedStudents'] ?? []);
      final allMembers = [teacherUid, ...studentUids];

      await chatRoomRef.set({
        'name': 'Class Chat',
        'adminUid': teacherUid,
        'members': allMembers,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || _user == null) return;
    final message = {
      'senderUid': _user.uid,
      'text': text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
    };
    await FirebaseFirestore.instance
        .collection('chatRooms')
        .doc(widget.classId)
        .collection('messages')
        .add(message);
    _controller.clear();
  }

  Stream<QuerySnapshot> messageStream() {
    return FirebaseFirestore.instance
        .collection('chatRooms')
        .doc(widget.classId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots();
  }

// String? username; // No longer needed
  @override
  void initState() {
    super.initState();
    createChatRoomIfNeeded().then((_) => _fetchAdminUid());
    // createChatRoomIfNeeded();
    // _fetchAdminUid();
  }

  Future<void> _fetchAdminUid() async {
    final doc = await FirebaseFirestore.instance
        .collection('chatRooms')
        .doc(widget.classId)
        .get();
    if (doc.exists) {
      final data = doc.data();
      setState(() {
        _adminUid = data?['adminUid'];
      });
    }
  }

  String? username;
  Future<void> fetchusername() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.uid)
        .get();

    if (doc.exists) {
      final data = doc.data();
      username = data?['name'];
      setState(() {
        username = data?['name'];
      });
    }
  }

  Future<String?> getAdminUid(String chatRoomId) async {
    final doc = await FirebaseFirestore.instance
        .collection('chatRooms')
        .doc(chatRoomId)
        .get();

    if (doc.exists) {
      final data = doc.data();
      return data?['adminUid'] as String?;
    }
    return null;
  }

  bool isAdmin(String uid) {
    print("Comparing adminUid: $_adminUid with $uid");

    return uid == _adminUid;
  }

  String formatTimestamp(dynamic ts) {
    if (ts == null) return '';
    if (ts is Timestamp) {
      final dt = ts.toDate();
      return '${dt.hour}:${dt.minute.toString().padLeft(2, '0')} ${dt.day}/${dt.month}/${dt.year}';
    }
    return '';
  }

  Future<Map<String, String>> fetchUserNames(List<String> uids) async {
    final users = await FirebaseFirestore.instance
        .collection('users')
        .where(FieldPath.documentId, whereIn: uids)
        .get();

    return {
      for (var doc in users.docs) doc.id: doc['name'] ?? 'User',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Class Chat')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: messageStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  fetchusername();
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                return ListView.builder(
                  reverse: true,
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[docs.length - 1 - index].data()
                        as Map<String, dynamic>;
                    final isMe = data['senderUid'] == _user?.uid;
                    final isAdminSender = isAdmin(data['senderUid']);
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 4),
                      child: Align(
                        alignment:
                            isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: isMe
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            // Chat bubble
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 14),
                              constraints: const BoxConstraints(maxWidth: 280),
                              decoration: BoxDecoration(
                                color: isAdminSender
                                    ? Colors.purple.shade400
                                    : isMe
                                        ? Colors.green.shade500
                                        : Colors.purple.shade200,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: Radius.circular(isMe ? 16 : 0),
                                  bottomRight: Radius.circular(isMe ? 0 : 16),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 6,
                                    offset: const Offset(2, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                spacing: 1,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      senderNameWidget(data['senderUid']),
                                      if (isAdminSender) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color:  Colors.purple,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: const Text(
                                            'ADMIN',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        )
                                      ],
                                    ],
                                  ),
                                  Text(
                                    data['text'] ?? '',
                                    style: TextStyle(
                                      color: isMe || isAdminSender
                                          ? Colors.white
                                          : Colors.black87,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    data['timestamp'] != null
                                        ? formatTimestamp(data['timestamp'])
                                        : '',
                                    style: TextStyle(
                                        fontSize: 9,
                                        color: Colors.grey.shade100),
                                  ),
                                ],
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
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(31)
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration:  InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(21)
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(
                    Icons.send,
                    color: Colors.purple,
                  ),
                  onPressed: () => sendMessage(_controller.text),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
