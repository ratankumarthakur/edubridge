import 'package:avatar_glow/avatar_glow.dart';
import 'package:chat/homepages/teacher/payment_page.dart';
import 'package:chat/homepages/teacher/profile/TeacherProfilePage.dart';
import 'package:chat/homepages/teacher/profile/TeacherQualificationsPage.dart';
import 'package:chat/teacher_student_onboarding/TeachersListPage.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
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
                                        //color: Colors.black,
                                        fontSize: 20,
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
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon:Icon(Icons.logout,color: Colors.purple,),
              onPressed: () async {
                Navigator.pop(context);
                await FirebaseAuth.instance.signOut();
                await GoogleSignIn().signOut();
                if (context.mounted) {
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              },
            ),
          ),
          SizedBox(width: 16),
        ],
      ),
      endDrawer: Drawer(
        backgroundColor: Colors.purple.shade100,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
                child: Column(
                  children: [
                    SizedBox(height: 20,),
                    Icon(
                                  Icons.settings,
                                  size: 77,
                                  color: Colors.purple,
                                ),
                                Text("Settings",style: TextStyle(color: Colors.purple))
                  ],

                )
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Divider(height: 2,color: Colors.purple,),
                ),
            ListTile(
              leading: const Icon(Icons.language,color: Colors.purple,),
              title: const Text('Change Language',style: TextStyle(color: Colors.purple),),
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
              leading: const Icon(Icons.brightness_6,color: Colors.purple,),
              title: const Text('Change Theme',style: TextStyle(color: Colors.purple)),
              onTap: () {
                // Implement your theme change logic here
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Theme change not implemented!')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout,color: Colors.purple,),
              title: const Text('Logout',style: TextStyle(color: Colors.purple)),
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
        
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                GestureDetector(
                  onTap: (){
                    Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => TeacherProfilePage(),
                                    ),
                                  );
                  },
                  //onTap: () => Navigator.pushNamed(context, '/teacherProfilePage'),
                  child: GradientNavCard(
                    title: 'Profile',
                    gradientColors: [
                      Colors.blue,
                      const Color.fromARGB(255, 160, 201, 220)
                    ],
                    icon: Icons.person,
                  ),
                ),
                GestureDetector(
                  onTap: (){
                    Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PaymentPage(),
                                    ),
                                  );
                  },
                  //onTap: () => Navigator.pushNamed(context, '/teacherProfilePage'),
                  child: GradientNavCard(
                    title: 'Platform fee',
                    gradientColors: [
                      Colors.blue,
                      const Color.fromARGB(255, 160, 201, 220)
                    ],
                    icon: Icons.search,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/t_class'),
                  child: GradientNavCard(
                    title: 'Classes',
                    gradientColors: [
                      const Color.fromARGB(255, 243, 33, 135),
                      const Color.fromARGB(255, 241, 174, 227)
                    ],
                    icon: Icons.class_outlined,
                  ),
                ),
                GestureDetector(
                  onTap: () =>
                      Navigator.pushNamed(context, '/teacher_schedule_page'),
                  child: GradientNavCard(
                    title: 'Schedule',
                    gradientColors: [
                      Colors.green,
                      const Color.fromARGB(255, 148, 225, 166)
                    ],
                    icon: Icons.schedule,
                  ),
                ),
                //SizedBox(height: 60,),
                Image.asset('assets/classroom.webp',
                height:MediaQuery.of(context).size.height/2,
                width: MediaQuery.of(context).size.height/2 ,),
                //Image.network('https://static.vecteezy.com/system/resources/previews/060/421/689/non_2x/inclusive-classroom-scene-with-teacher-instructing-children-fostering-teamwork-creativity-and-interactive-learning-methods-free-png.png')
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: AvatarGlow(
        glowColor: Colors.purple,
        // endRadius: 60.0,
        duration: Duration(milliseconds: 2000),
        repeat: true,
        child: FloatingActionButton(
            backgroundColor: Colors.white,
            shape: CircleBorder(),
            onPressed:(){ Get.to(()=>TeachersListPage(),transition: Transition.downToUp,
            duration: Duration(seconds: 2));},
           // onPressed: () => Navigator.pushNamed(context, '/teacher_list_page'),
            child: Icon(Icons.search)),
      ),
      
      //floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

class GradientNavCard extends StatelessWidget {
  final String title;
  final List<Color> gradientColors;

  final IconData icon;

  const GradientNavCard({
    Key? key,
    required this.title,
    required this.gradientColors,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(62),
                        child: Image.asset( 'assets/background.jpg',// or use Image.asset for local images
                          height: 80,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Container(
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(62),
                          color: Colors.black.withOpacity(0.1), // dark overlay for contrast
                        ),
                      ),
                      Positioned.fill(
                        child: Container(
        height: 80,
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          
          borderRadius: BorderRadius.circular(62),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(width: 20),
            Text(
              title,
              style: const TextStyle(fontSize: 20, color: Colors.white),
            ),
          ],
        ),
      )
                      ),
                    ],
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
                color: glow
                    ? const Color(0xFF1DE782).withOpacity(0.5)
                    : Colors.black26,
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
