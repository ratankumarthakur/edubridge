// // import 'package:chat/chat/group_list_screen.dart';
// // import 'package:chat/chat/login_screen.dart';
// // import 'package:chat/test/teacher.dart';
// // import 'package:flutter/material.dart';
// // import 'package:firebase_core/firebase_core.dart';
// // import 'package:firebase_auth/firebase_auth.dart';
// // void main() async {
// //   WidgetsFlutterBinding.ensureInitialized();
// //   await Firebase.initializeApp(
// //       //name: "e_commerce",                      // use // for chrome
// //       options: const FirebaseOptions(
// //           apiKey: "AIzaSyDOYTB5MCy_VKeDlzcS8DThcMk7eYfSl6I",
// //           appId: "1:39721889660:android:f1ec6aed7b8c87075f7ef9",
// //           storageBucket:"ecommerce-eb54d.appspot.com",
// //           messagingSenderId: "39721889660",
// //           projectId: "ecommerce-eb54d"))
// //       // // name: "gpg_mine",
// //       // options: const FirebaseOptions(
// //       //     apiKey: "AIzaSyCsLkA2-oUJFaCW7kA5tkMuqemDPfS9INw",
// //       //     //authDomain: "alumnidekho-2fd65.firebaseapp.com",
// //       //     //databaseURL: "https://alumnidekho-2fd65-default-rtdb.asia-southeast1.firebasedatabase.app",
// //       //     projectId: "alumnidekho-2fd65",
// //       //     storageBucket: "alumnidekho-2fd65.appspot.com",
// //       //     messagingSenderId: "816540763282",
// //       //     appId: "1:816540763282:web:d4cb4af56673332e22d24b",
// //       //     //measurementId: "G-WSWB08XKQV"
// //       //     ));;
// //       ;
// //   runApp(ChatApp());
// // }

// // class ChatApp extends StatelessWidget {
// //   const ChatApp({super.key});

// //   @override
// //   Widget build(BuildContext context) {
// //     return MaterialApp(
// //       title: 'Group Chat',
// //       debugShowCheckedModeBanner: false,
// //       theme: ThemeData(primarySwatch: Colors.teal),
// //       home: CreateTestPage()
// //       // FirebaseAuth.instance.currentUser == null
// //       //     ? LoginScreen()
// //       //     : GroupListScreen(),
// //     );
// //   }
// // }



// import 'package:chat/test/teacher.dart';
// import 'package:chat/test/student.dart';
// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp(
//     options: const FirebaseOptions(
//       apiKey: "AIzaSyDOYTB5MCy_VKeDlzcS8DThcMk7eYfSl6I",
//       appId: "1:39721889660:android:f1ec6aed7b8c87075f7ef9",
//       storageBucket: "ecommerce-eb54d.appspot.com",
//       messagingSenderId: "39721889660",
//       projectId: "ecommerce-eb54d",
//     ),
//   );
//   runApp(const ChatApp());
// }

// class ChatApp extends StatelessWidget {
//   const ChatApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       routes: {
//     '/teacherHome': (_) => TeacherHomePage(),
//     '/studentHome': (_) => StudentHomePage(),
//     // Add other routes as needed
//   },
//       title: 'Test App',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(primarySwatch: Colors.teal),
//       home: Scaffold(
//         appBar: AppBar(title: const Text('Test App')),
//         body: Builder(
//           builder: (context) => Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 ElevatedButton(
//                   child: const Text('Teacher Page'),
//                   onPressed: () => Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (_) => TeacherHomePage()),
//                   ),
//                 ),
//                 ElevatedButton(
//                   child: const Text('Student Page'),
//                   onPressed: () => Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (_) => StudentHomePage()),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }


import 'package:chat/homepages/students_profile.dart';
import 'package:chat/homepages/t_class.dart';
import 'package:chat/homepages/t_home.dart';
import 'package:chat/homepages/teacher_class_actions_page.dart';
import 'package:chat/homepages/teacher_front_page.dart';
import 'package:chat/homepages/teachers_profile.dart';
import 'package:chat/quiz/teacher_quiz.dart';
import 'package:chat/teacher_student_onboarding/student_list_page.dart';
import 'package:chat/teacher_student_onboarding/teachers_list_page.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:chat/authentication/login.dart';
import 'package:chat/authentication/signup.dart';
import 'package:chat/test/teacher_test.dart';
import 'package:chat/test/student_test.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      // apiKey: "AIzaSyDOYTB5MCy_VKeDlzcS8DThcMk7eYfSl6I",
      // appId: "1:39721889660:android:f1ec6aed7b8c87075f7ef9",
      // storageBucket: "ecommerce-eb54d.appspot.com",
      // messagingSenderId: "39721889660",
      // projectId: "ecommerce-eb54d",
      apiKey: "AIzaSyArwn6dKr7ppJkjOE45VfQ9OCRih9nClag",
      appId: "1:61768828498:android:b76f9de2883171f460018b",
      storageBucket: "sems-4c37f.appspot.com",
      authDomain: "sems-4c37f.firebaseapp.com",
      messagingSenderId: "61768828498",
      projectId: "sems-4c37f",
    ),
  );
  
  runApp(EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('hi')],
      path: 'assets/langs',
      fallbackLocale: const Locale('en'),
      child: const ChatApp(),
    ),);
}

class ChatApp extends StatelessWidget {
  const ChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      title: 'Authentication Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.teal),
      routes: {
        '/login': (_) => const LoginPage(),
        '/signup': (_) => const SignupPage(),
        
        '/teacherProfile': (_) => const TeacherProfilePage(),
        //'/teacherClassActions': (_) => const TeacherClassActionsPage(),
        '/teacherFrontPage': (_) => const TeacherFrontPage(),
        '/t_home': (_) => const THome(),
        '/t_class': (_) => const TClass(),
        '/teacher_list_page':(_)=> TeachersListPage(),
        '/student_list_page': (_) => const StudentsListPage(),
        '/studentProfile': (_) => const StudentProfilePage(),
      },
      home:  LoginPage(),
    );
  }
}

class AuthHomePage extends StatelessWidget {
  const AuthHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Welcome')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: const Text('Login'),
              onPressed: () => Navigator.pushNamed(context, '/login'),
            ),
            ElevatedButton(
              child: const Text('Sign Up'),
              onPressed: () => Navigator.pushNamed(context, '/signup'),
            ),
          ],
        ),
      ),
    );
  }
}