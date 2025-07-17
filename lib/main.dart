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
      //sems
      apiKey: "",
      appId: "",
      storageBucket: "",
      authDomain: "",
      messagingSenderId: "",
      projectId: "",
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
