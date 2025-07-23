import 'package:chat/chat/login_screen.dart';
import 'package:chat/homepages/student/home/students_profile.dart';
import 'package:chat/homepages/teacher/class/TClass.dart';
import 'package:chat/homepages/teacher/THome.dart';
import 'package:chat/homepages/teacher/profile/TeacherProfilePage.dart';
import 'package:chat/homepages/teacher/TeacherSchedulesPage.dart';
import 'package:chat/quiz/student_quiz.dart';
import 'package:chat/teacher_student_onboarding/StudentsListPage.dart';
import 'package:chat/teacher_student_onboarding/TeachersListPage.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:chat/authentication/LoginPage.dart';
import 'package:chat/authentication/SignupPage.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyArwn6dKr7ppJkjOE45VfQ9OCRih9nClag",
      appId: "1:61768828498:android:b76f9de2883171f460018b",
      storageBucket: "sems-4c37f.appspot.com",
      authDomain: "sems-4c37f.firebaseapp.com",
      messagingSenderId: "61768828498",
      projectId: "sems-4c37f",
    ),
  );

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('hi')],
      path: 'assets/langs',
      fallbackLocale: const Locale('en'),
      child: const ChatApp(),
    ),
  );
}

class ChatApp extends StatelessWidget {
  const ChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      title: 'Edubridge',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.purple.shade100, // or use Colors.purple
            elevation: 4,
            iconTheme: IconThemeData(color: Colors.purple),
            titleTextStyle: TextStyle(
              color: Colors.purple,
              fontWeight: FontWeight.bold,
              fontSize: 20,
              fontFamily: 'nunito',
            ),
          ),
          scaffoldBackgroundColor: Colors.purple.shade50,
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple, // default button color
              foregroundColor: Colors.white, // text/icon color
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(29),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                fontFamily: 'nunito',
              ),
            ),
          ),
          primarySwatch: Colors.purple),
      routes: {
        '/login': (_) => const LoginPage(),
        '/signup': (_) => const SignupPage(),
        '/t_home': (_) => const THome(),
        '/teacherProfilePage': (_) => const TeacherProfilePage(),
        '/t_class': (_) => const TClass(),
        '/teacher_schedule_page': (_) => TeacherSchedulesPage(),
        '/teacher_list_page': (_) => TeachersListPage(),
        '/student_list_page': (_) => const StudentsListPage(),
        '/studentProfile': (_) => const StudentProfilePage(),
        '/availablequizesscreen': (_) =>  AvailableQuizzesScreen(),
      },
      home: LoginPage(),
    );
  }
}
