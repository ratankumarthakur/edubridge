import 'package:chat/homepages/usersc.dart';
import 'package:chat/test/student_test.dart';
import 'package:chat/test/teacher_test.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
//import 'teacher_class_actions_page.dart';
import 'package:google_sign_in/google_sign_in.dart';

class THome extends StatefulWidget {
  const THome({super.key});

  @override
  State<THome> createState() => _THomeState();
}

class _THomeState extends State<THome> {
  User? get user => FirebaseAuth.instance.currentUser;
  
  Future<Map<String, dynamic>?> getTeacherData() async {
    if (user == null) return null;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();
    return doc.data();
  }
  
  @override
  Widget build(BuildContext context) {
    final teacherUid = user?.uid;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF10151A),
        leadingWidth: 0,
        leading: SizedBox(
          width: 0,
          height: 0,
        ),
        title: teacherUid == null
          ? const Center(child: Text('Not logged in'))
          : FutureBuilder<Map<String, dynamic>?>(
              future: getTeacherData(),
              builder: (context, snapshot) {
                final data = snapshot.data;
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Info
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundImage: data?['photoUrl'] != null
                                ? NetworkImage(data!['photoUrl'])
                                : null,
                            child: data?['photoUrl'] == null
                                ? const Icon(Icons.person, size: 40)
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data?['name'] ?? 'Teacher Name',
                                  style: const TextStyle(
                                    color:  Color(0xFF1DE782),
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold),
                                ),
                              
                              ],
                            ),
                          ),
                        ],
                      ),
                      
               
                    ],
                  ),
                );
              },
            ),
        actions:[ 
          Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Scaffold.of(context).openEndDrawer(),
          ),
        ),
        SizedBox(width: 16),
        ],
      ),
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              child: Icon(
                Icons.settings,
                 size: 64, 
                 color: Colors.grey[700],)
                 ),
            ListTile(
              leading: const Icon(Icons.language),
              title: const Text('Change Language'),
              onTap: () async {
                Navigator.pop(context);
                await showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Select Language'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          title: const Text('English'),
                          onTap: () {
                            context.setLocale(const Locale('en'));
                            Navigator.pop(context);
                          },
                        ),
                        ListTile(
                          title: const Text('हिन्दी'),
                          onTap: () {
                            context.setLocale(const Locale('hi'));
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.brightness_6),
              title: const Text('Change Theme'),
              onTap: () {
                // Implement your theme change logic here
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Theme change not implemented!')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                Navigator.pop(context);
                await FirebaseAuth.instance.signOut();
                await GoogleSignIn().signOut();
                if (context.mounted) {
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              },
            ),
          ],
        ),
      ),
      body: Container(
  decoration: const BoxDecoration(
    gradient: LinearGradient(
      colors: [Color(0xFF10151A), Color(0xFF1A222D)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  child: Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      children: [
        
        Expanded(
          child: GridView.count(
            crossAxisCount: 3,
            crossAxisSpacing: 18,
            mainAxisSpacing: 18,
            childAspectRatio: 0.95,
            children: [
              _GridItem(
                icon: Icons.person,
                label: 'Profile',
                color: const Color(0xFF18222F),
                glow: true,
                onTap: () => Navigator.pushNamed(context, '/teacherFrontPage'),
              ),
              _GridItem(
                icon: Icons.class_,
                label: 'Classes',
                color: const Color(0xFF18222F),
                onTap: () => Navigator.pushNamed(context, '/t_class'),
              ),
              _GridItem(
                icon: Icons.school,
                label: 'Live Class',
                glow: true,
                color: const Color(0xFF18222F),
                onTap: () {
                  if (teacherUid != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>UserSchedulesPage(),
          //builder: (_) => StudentTestPage(),
        ),
      );
                };}
              ),
              _GridItem(
                icon: Icons.settings,
                label: 'Study Material',
                color: const Color(0xFF18222F),
                onTap: () {},
              ),
              _GridItem(
                icon: Icons.language,
                label: 'Tests',
                glow: true,
                color: const Color(0xFF18222F),
                onTap: () {
                  if (teacherUid != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TeacherTestPage(teacherUid: teacherUid),
          //builder: (_) => StudentTestPage(),
        ),
      );
    }
                  //Navigator.pushNamed(context, '/teacherTest');
                },
              ),
              _GridItem(
                icon: Icons.info,
                label: 'Chat',
                color: const Color(0xFF18222F),
                onTap: () {},
              ),
              _GridItem(
                icon: Icons.help,
                label: 'Quiz',
                glow: true,
                color: const Color(0xFF18222F),
                onTap: () {},
              ),
              _GridItem(
                icon: Icons.logout,
                label: 'Attendance',
                color: const Color(0xFF18222F),
                onTap: () {},
              ),
              _GridItem(
                icon: Icons.star,
                label: 'Fees',
                glow: true,
                color: const Color(0xFF18222F),
                onTap: () {},
              ),
              _GridItem(
                icon: Icons.star,
                label: 'Student-teacher',
                glow: true,
                color: const Color(0xFF18222F),
                onTap: () {

                  Navigator.pushNamed(context, '/teacher_list_page');

                },
              ),
            ],
          ),
        ),
      ],
    ),
  ),
),
      
    );
  }
}
class _GridItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  final bool glow;
  const _GridItem({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
    this.glow = true,
    //super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        splashColor: const Color(0xFF1DE782).withOpacity(0.2),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: glow ? const Color(0xFF1DE782).withOpacity(0.5) : Colors.black26,
                blurRadius: glow ? 18 : 8,
                spreadRadius: glow ? 0 : 0,
                offset: const Offset(0, 0),
              ),
            ],
            gradient: glow
                ? const LinearGradient(
                    colors: [Color(0xFF1DE782), Color(0xFF10151A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 36,
                color: glow ? Colors.black : const Color(0xFF1DE782),
                shadows: glow
                    ? [
                        Shadow(
                          color: const Color(0xFF1DE782),
                          blurRadius: 18,
                        ),
                      ]
                    : [],
              ),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: glow ? Colors.black : Colors.white,
                  shadows: glow
                      ? [
                          const Shadow(
                            color: Color(0xFF1DE782),
                            blurRadius: 8,
                          ),
                        ]
                      : [],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}