
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class JoinClassPage extends StatefulWidget {
  const JoinClassPage({super.key});

  @override
  State<JoinClassPage> createState() => _JoinClassPageState();
}

class _JoinClassPageState extends State<JoinClassPage> {
  final TextEditingController searchCtrl = TextEditingController();
  String searchText = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join a Class')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: Expanded(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(color: Colors.purple, width: 2),
                    ),
                    child: TextField(
                      controller: searchCtrl,
                      decoration: InputDecoration(
                        hintText: 
                            'Search by class name'
                            ,
                        hintStyle: const TextStyle(
                            fontSize: 14, color: Colors.black54),
                        border: InputBorder.none,
                        icon: const Icon(Icons.search, color: Colors.purple),
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
            
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('classes').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final docs = snapshot.data?.docs ?? [];
                final filtered = docs.where((doc) {
                  final name = (doc['name'] ?? '').toString().toLowerCase();
                  return name.contains(searchText.toLowerCase());
                }).toList();
                if (filtered.isEmpty) {
                  return const Center(child: Text('No classes found.'));
                }
                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final data = filtered[i].data() as Map<String, dynamic>;
                    return 
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Stack(
                        children: [
                           ClipRRect(
                              borderRadius: BorderRadius.circular(52),
                              child: Image.network(
                                // or use Image.asset for local images
                                'https://static.vecteezy.com/system/resources/previews/046/386/166/non_2x/abstract-blue-and-pink-glowing-lines-curved-overlapping-background-template-premium-award-design-vector.jpg',
                                height: 60,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Container(
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(52),
                                // dark overlay for contrast
                              ),
                            ),
                          Positioned.fill(
                      
                            child: Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(52)
                              ),
                              color: Colors.transparent,
                              child: Center(
                                child: ListTile(
                                  title: Text(data['name'] ?? '',style: TextStyle(color: Colors.white),),
                                  trailing: Icon(Icons.arrow_forward,color: Colors.white,),
                                  //subtitle: Text(data['code']),
                                  //subtitle: Text('Teacher : ${data['created_by']}',style: TextStyle(color: Colors.white)),
                                  onTap: () async {
                                    final code = await showDialog<String>(
                                      context: context,
                                      builder: (context) {
                                        final codeCtrl = TextEditingController();
                                        return AlertDialog(
                                          title: Text('Enter code for "${data['name']}"'),
                                          content: TextField(
                                            controller: codeCtrl,
                                            decoration: const InputDecoration(
                                              labelText: 'Class Code',
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: const Text('Cancel'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () {
                                                Navigator.pop(
                                                    context, codeCtrl.text.trim());
                                              },
                                              child: const Text('Join'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                    if (code == null || code.isEmpty) return;
                                    // Check code
                                    if (code == data['code']) {
                                      final user = FirebaseAuth.instance.currentUser;
                                      if (user != null) {
                                        await FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(user.uid)
                                            .update({
                                          'joinedClasses':
                                              FieldValue.arrayUnion([filtered[i].id])
                                        });
                                        await FirebaseFirestore.instance
                                            .collection('classes')
                                            .doc(filtered[i].id)
                                            .set({
                                          'joinedStudents':
                                              FieldValue.arrayUnion([user.uid])
                                        }, SetOptions(merge: true));
                                      }
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Class joined!')),
                                        );
                                        Navigator.pop(context, true);
                                      }
                                    } else {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                              content: Text('Incorrect code!')),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ),
                            ),
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
