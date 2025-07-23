import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});
  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  String role = 'student';
  bool loading = false;

  Future<void> googleSignup() async {
    setState(() => loading = true);
    try {
      UserCredential userCredential;
      if (kIsWeb) {
        // Web: use signInWithPopup
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        userCredential = await FirebaseAuth.instance.signInWithPopup(googleProvider);
      } else {
        // Mobile: use google_sign_in
        final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) {
          setState(() => loading = false);
          return; // User cancelled
        }
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      }

      // Check if user doc exists
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      String? userRole;
      if (!userDoc.exists) {
        // Prompt for role if new user
        userRole = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Select Role'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('Teacher'),
                  onTap: () => Navigator.pop(context, 'teacher'),
                ),
                ListTile(
                  title: const Text('Student'),
                  onTap: () => Navigator.pop(context, 'student'),
                ),
              ],
            ),
          ),
        );
        if (userRole == null) {
          await FirebaseAuth.instance.signOut();
          setState(() => loading = false);
          return;
        }
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'name': userCredential.user!.displayName ?? '',
          'email': userCredential.user!.email ?? '',
          'role': userRole,
          'createdAt': FieldValue.serverTimestamp()
        });
      } else {
        userRole = userDoc['role'];
      }

      if (!mounted) return;
      if (userRole == 'teacher') {
        Navigator.pushReplacementNamed(context, '/t_home');
      } else {
        Navigator.pushReplacementNamed(context, '/studentProfile');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google sign-in failed: $e')),
      );
    }
    setState(() => loading = false);
  }

  Future<void> signup() async {
    if (nameCtrl.text.trim().isEmpty ||
        emailCtrl.text.trim().isEmpty ||
        passCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }
    if (passCtrl.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return;
    }
    setState(() => loading = true);
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailCtrl.text.trim(),
        password: passCtrl.text,
      );
      await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .set({
        'name': nameCtrl.text.trim(),
        'email': emailCtrl.text.trim(),
        'role': role,
        'createdAt': FieldValue.serverTimestamp()
      });

      if (!mounted) return;
      if (role == 'teacher') {
        Navigator.pushReplacementNamed(context, '/t_home');
      } else {
        Navigator.pushReplacementNamed(context, '/studentProfile');
      }
    } catch (e) {
      final errorMsg = e.toString().replaceAll(RegExp(r'\[.*?\]'), '').trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Signup failed: $errorMsg')),
      );
    }
    setState(() => loading = false);
  }

  bool _obscure = true;
  @override
  Widget build(BuildContext context) {
    final grey800 = Colors.grey.shade100;
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/register.png'),
          fit: BoxFit.fill,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Stack(
          children: [
            Container(
              padding: const EdgeInsets.only(left: 35, top: 10),
              child: Text(
                'Create\nAccount',
                style: TextStyle(color: Colors.white, fontSize: 33),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                child: Container(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).size.height * 0.28,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 400,
                        margin: const EdgeInsets.only(left: 35, right: 35),
                        child: Column(
                          children: [
                            TextField(
                              controller: nameCtrl,
                              style: TextStyle(color: grey800),
                              decoration: InputDecoration(
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: grey800,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: grey800,
                                  ),
                                ),
                                hintText: "Name",
                                hintStyle: TextStyle(color: grey800),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                            const SizedBox(height: 30),
                            TextField(
                              controller: emailCtrl,
                              style: TextStyle(color: grey800),
                              decoration: InputDecoration(
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: grey800,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: grey800,
                                  ),
                                ),
                                hintText: "Email",
                                hintStyle: TextStyle(color: grey800),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                            const SizedBox(height: 30),
                            TextField(
                              controller: passCtrl,
                              style: TextStyle(color: grey800),
                              obscureText: _obscure,
                              decoration: InputDecoration(
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscure
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscure = !_obscure;
                                    });
                                  },
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: grey800,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: grey800,
                                  ),
                                ),
                                hintText: "Password",
                                hintStyle: TextStyle(color: grey800),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Radio<String>(
                                  value: 'teacher',
                                  groupValue: role,
                                  onChanged: (v) => setState(() => role = v!),
                                  activeColor: grey800,
                                  fillColor: MaterialStateProperty.all(grey800),
                                ),
                                Text('Teacher', style: TextStyle(color: grey800)),
                                Radio<String>(
                                  value: 'student',
                                  groupValue: role,
                                  onChanged: (v) => setState(() => role = v!),
                                  activeColor: grey800,
                                  fillColor: MaterialStateProperty.all(grey800),
                                ),
                                Text('Student', style: TextStyle(color: grey800)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Sign Up',
                                  style: TextStyle(
                                    color: grey800,
                                    fontSize: 27,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                CircleAvatar(
                                  radius: 30,
                                  backgroundColor: Colors.grey.shade800,
                                  child: loading
                                      ? CircularProgressIndicator(
                                          color: Colors.white)
                                      : IconButton(
                                          color: Colors.white,
                                          onPressed: signup,
                                          icon: const Icon(Icons.arrow_forward),
                                        ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pushNamed(context, '/login');
                                  },
                                  style: ButtonStyle(
                                    overlayColor: MaterialStateProperty.all(
                                        grey800.withOpacity(0.1)),
                                  ),
                                  child: Text(
                                    'Sign In',
                                    textAlign: TextAlign.left,
                                    style: TextStyle(
                                      //decoration: TextDecoration.underline,
                                      color: Colors.green,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 20,),
                            ElevatedButton(
                              onPressed: googleSignup,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 50, vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Image.asset(
                                          'assets/google_logo.png',
                                          height: 24,
                                        ),
                                        const SizedBox(width: 10),
                                        const Text(
                                          'Sign up with Google',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                            
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
