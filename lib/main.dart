import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rbl_admin/USER%20ID/userId.dart';
import 'package:rbl_admin/BottomTab.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await Supabase.initialize(
    url: 'https://qyvladzxxzhsacvdmyft.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF5dmxhZHp4eHpoc2FjdmRteWZ0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzUwMDkzMjIsImV4cCI6MjA1MDU4NTMyMn0.4OGks2Ch2eWSpx5r0D5Gl4mWO4fHKuJIw9boog4TQEo',
  );
  bool? isLoggedIn = await AccountId.getUserLogInStatus();
  await AccountId.initUserId();
  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  MyApp({required this.isLoggedIn});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: isLoggedIn ? BottomTabView() : AuthScreen(),
    );
  }
}

class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final SupabaseClient supabase = Supabase.instance.client;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true; // true: Login, false: SignUp
  String _statusMessage = '';

  Future<void> _submit() async {
  String email = _emailController.text.trim();
  String password = _passwordController.text.trim();

  try {
    if (_isLogin) {
      // Firebase Login
      await _auth.signInWithEmailAndPassword(email: email, password: password);

       final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      print('User signed in: ${response.user}');

      setState(() {
        _statusMessage = 'Login successful!';
      });

      // Change shared preference state
      AccountId.setLoginStatusToSignedIn();
      await AccountId.initUserId();
      await AccountId.createUser();

      // Navigate to home screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => BottomTabView()),
      );
    } else {
      // Firebase Sign-Up
      await _auth.createUserWithEmailAndPassword(email: email, password: password);

      // Supabase Sign-Up
      await supabase.auth.signUp(email: email, password: password);
      

      setState(() {
        _statusMessage = 'Sign up successful!';
      });

      AccountId.setLoginStatusToSignedIn();
      await AccountId.initUserId();
      await AccountId.createUser();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => BottomTabView()),
      );
    }
  } catch (e) {
    setState(() {
      _statusMessage = 'Error: $e';
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? 'Log In' : 'Sign Up'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email Address'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submit,
              child: Text(_isLogin ? 'Login' : 'Sign Up'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _isLogin = !_isLogin;
                });
              },
              child: Text(_isLogin
                  ? "Don't have an account? Sign Up"
                  : 'Already have an account? Log In'),
            ),
            if (_statusMessage.isNotEmpty)
              Text(
                _statusMessage,
                style: TextStyle(color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }
}
