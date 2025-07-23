import 'package:avatar_glow/avatar_glow.dart';
import 'package:chat/quiz/teacher_quiz.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

// class quizlist extends StatefulWidget {
//   final String classid;
//    final String classname;
//    quizlist({required this .classname,required this.classid,super.key});

//   @override
//   State<quizlist> createState() => _quizlistState();
// }

// class _quizlistState extends State<quizlist> {
//   User? get user => FirebaseAuth.instance.currentUser;

//   @override
//   Widget build(BuildContext context) {
//     final teacherUid = user?.uid;
//     return Scaffold(
//         appBar: AppBar(
//           leading: IconButton(
//             icon: const Icon(Icons.arrow_back),
//             onPressed: () => Navigator.pop(context),
//           ),
//           title: const Text('Your quizzes:',
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

//         ),
//         body: Column(children: [
//           ElevatedButton.icon(
//             icon: const Icon(Icons.add),
//             label: const Text('Create New quiz'),
//             onPressed:(){ CreateQuizScreen(classname: widget.classname,clas: widget.classid,);}
//           ),
//           SizedBox(height: 24),

//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Row(mainAxisAlignment:MainAxisAlignment.end ,children: [Text("Swipe to delete a quiz",style: TextStyle(color: Colors.red),)],),
//           ),
//           Expanded(
//             child: StreamBuilder<QuerySnapshot>(
//               stream: FirebaseFirestore.instance
//                   .collection('classes')
//                   .where('teacherUid', isEqualTo: teacherUid)
//                   .collection('quizzes')
//                   .snapshots(),
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }
//                 if (snapshot.hasError) {
//                   return Center(child: Text('Error: ${snapshot.error}'));
//                 }
//                 final docs = snapshot.data?.docs ?? [];
//                 // docs.sort((a, b) {
//                 //   final aTime = (a['createdAt'] as Timestamp?)?.toDate() ??
//                 //       DateTime(1970);
//                 //   final bTime = (b['createdAt'] as Timestamp?)?.toDate() ??
//                 //       DateTime(1970);
//                 //   return bTime.compareTo(aTime); // descending
//                 // });
//                 if (docs.isEmpty) {
//                   return const Center(child: Text('No quizzes created yet.'));
//                 }
//                 return ListView.builder(
//   itemCount: docs.length,
//   itemBuilder: (context, i) {
//     final data = docs[i].data() as Map<String, dynamic>;
//     final docId = docs[i].id;

//     return Dismissible(
//       key: Key(docId),
//       direction: DismissDirection.endToStart, // swipe left to delete
//       background: Container(
//         color: Colors.red,
//         alignment: Alignment.centerRight,
//         padding: EdgeInsets.symmetric(horizontal: 20),
//         child: Icon(Icons.delete, color: Colors.white),
//       ),
//       confirmDismiss: (direction) async {
//         return await showDialog(
//           context: context,
//           builder: (_) => AlertDialog(
//             title: Text('Delete Quiz'),
//             content: Text('Are you sure you want to delete "${data['title']}"?'),
//             actions: [
//               TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text('Cancel')),
//               TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text('Delete')),
//             ],
//           ),
//         );
//       },
//       onDismissed: (direction) async {
//         await FirebaseFirestore.instance.collection('classes').doc(docId).delete();
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Class "${data['name']}" deleted')),
//         );
//       },
//       child: Card(
//         child: ListTile(
//           title: Text(data['name'] ?? ''),
//           subtitle: Text('Code: ${data['code']}'),
//           trailing: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             crossAxisAlignment: CrossAxisAlignment.end,
//             children: [
//               Text(
//                 'Created on: ${data['createdAt'] != null
//                   ? (data['createdAt'] as Timestamp).toDate().toLocal().toString().split(' ')[0]
//                   : 'Unknown'}',
//                 style: TextStyle(fontSize: 12),
//               ),
//               Text(
//                 'Joined: ${(data['joinedStudents'] as List?)?.length ?? 0}',
//                 style: TextStyle(fontSize: 12),
//               ),
//             ],
//           ),
//           onTap: () {
//             Navigator.push(
//               context,
//               MaterialPageRoute(
//                 builder: (_) => CreateQuizScreen(
//                   classname: widget.classname,
//                   clas: widget.classid,

//                 ),
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   },
// );
//               },
//             ),
//           ),
//         ]));
//   }
// }
Future<List<Map<String, dynamic>>> fetchTeacherQuizzes(
    String teacherUid) async {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final List<Map<String, dynamic>> quizzesList = [];

  final classesSnapshot = await firestore
      .collection('classes')
      .where('teacherUid', isEqualTo: teacherUid)
      //.orderBy('createdAt', descending: false)
      .get();

  for (final classDoc in classesSnapshot.docs) {
    final quizzesSnapshot = await classDoc.reference
        .collection('quizzes')
        .orderBy('createdAt', descending: true)
        .get();
    for (final quizDoc in quizzesSnapshot.docs) {
      quizzesList.add({
        'quizId': quizDoc.id,
        'classId': classDoc.id,
        ...quizDoc.data(),
      });
    }
  }

  return quizzesList;
}

class TeacherQuizzesPage extends StatefulWidget {
  final String classid;
  final String classname;
  const TeacherQuizzesPage({
    required this.classname,
    required this.classid,
    super.key,
  });

  @override
  State<TeacherQuizzesPage> createState() => _TeacherQuizzesPageState();
}

class _TeacherQuizzesPageState extends State<TeacherQuizzesPage> {
  late Future<List<Map<String, dynamic>>> quizzesFuture;
  User? get user => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    quizzesFuture = fetchTeacherQuizzes(user!.uid);
  }

  Future<void> deleteQuiz(String classId, String quizId) async {
    await FirebaseFirestore.instance
        .collection('classes')
        .doc(classId)
        .collection('quizzes')
        .doc(quizId)
        .delete();
    setState(() {
      quizzesFuture = fetchTeacherQuizzes(user!.uid); // Refresh list
    });
  }
  Future<void> deleteQuiz2( String quizId) async {
    await FirebaseFirestore.instance
        
        .collection('quizzes')
        .doc(quizId)
        .delete();
    setState(() {
      quizzesFuture = fetchTeacherQuizzes(user!.uid); // Refresh list
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: AvatarGlow(
        glowColor: Colors.purple,
        // endRadius: 60.0,
        duration: Duration(milliseconds: 2000),
        repeat: true,
        child: FloatingActionButton(
            backgroundColor: Colors.white,
            shape: CircleBorder(),
            onPressed:(){Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateQuizScreen(
                      classname: widget.classname,
                      clas: widget.classid,
                    ),
                  ),
                );},
           // onPressed: () => Navigator.pushNamed(context, '/teacher_list_page'),
            child: Icon(Icons.add)),
      ),
      appBar: AppBar(title: const Text('My Quizzes')),
      body: Column(
        children: [
          
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: quizzesFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final quizzes = snapshot.data!;
                if (quizzes.isEmpty) {
                  return const Center(child: Text('No quizzes found.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: quizzes.length,
                  itemBuilder: (context, index) {
                    final quiz = quizzes[index];
                    final Timestamp timestamp = quiz['createdAt'];
                    final DateTime date = timestamp.toDate();
                    final formatted =
                        DateFormat('MMM d, yyyy – hh:mm a').format(date);
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              // or use Image.asset for local images
                              'https://static.vecteezy.com/system/resources/previews/046/386/166/non_2x/abstract-blue-and-pink-glowing-lines-curved-overlapping-background-template-premium-award-design-vector.jpg',
                              height: 120,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Container(
                            height: 120,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.black.withOpacity(
                                  0.1), // dark overlay for contrast
                            ),
                          ),
                          Positioned.fill(
                            child: Dismissible(
                      key: Key(quiz['quizId']),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: Colors.redAccent,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (_) async {
                        return await showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Delete Quiz'),
                            content: const Text(
                                'Are you sure you want to delete this quiz?'),
                            actions: [
                              TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancel')),
                              TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Delete')),
                            ],
                          ),
                        );
                      },
                      //onDismissed: (_) => deleteQuiz(quiz['classId'], quiz['quizId']),
                      onDismissed: (_) async {
                        await deleteQuiz(quiz['classId'], quiz['quizId']);
                        setState(() {
                          quizzes.removeAt(index); // ⬅️ Remove from local list
                        });
                         await deleteQuiz2( quiz['quizId']);
                        setState(() {
                          quizzes.removeAt(index); // ⬅️ Remove from local list
                        });
                      },
                      child: Card(   
                        color: Colors.transparent,       
                          
                                   
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                            title: Text(
                              quiz['title'] ?? 'Untitled Quiz',
                              style:
                                  const TextStyle(fontSize: 15,fontWeight: FontWeight.bold,color: Colors.white),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${quiz['class name']}',style:
                                  const TextStyle(fontSize: 13,color: Colors.white),
                            ),
                                
                              ],
                            ),
                            trailing: Text('Created at:\n$formatted\nNumber of questions: ${quiz['questions'].length}',style:
                              const TextStyle(fontSize: 12,color: Colors.white),
                                                        ) ),
                      ),
                    )
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
    );
  }
}
