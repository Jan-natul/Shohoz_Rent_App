import 'package:app/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String _error = '';

  Future<void> _register() async {
    if (_username.text.isEmpty || _email.text.isEmpty || _password.text.isEmpty || _phone.text.isEmpty) {
      setState(() => _error = "Please fill all fields");
      return;
    }

    setState(() { _loading = true; _error = ''; });

    try {
      UserCredential cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text.trim(),
      );

      await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
        'name': _username.text.trim(),
        'email': _email.text.trim(),
        'phone': _phone.text.trim(),
        'isAdmin': false,
        'profilePic': null,
        'createdAt': DateTime.now(),
      });

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        ),
            (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? "Signup failed");
    } catch (e) {
      setState(() => _error = "An error occurred. Try again.");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: Container(
        width: double.infinity, height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(image: AssetImage('assets/homepage.jpg'), fit: BoxFit.cover, colorFilter: ColorFilter.mode(Colors.black87, BlendMode.darken)),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                const Text('Create Account', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: Column(children: [
                    if (_error.isNotEmpty) Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(_error, style: const TextStyle(color: Colors.redAccent))),
                    _inputField('Full Name', _username, Icons.person_outline),
                    const SizedBox(height: 15),
                    _inputField('Email Address', _email, Icons.email_outlined),
                    const SizedBox(height: 15),
                    _inputField('Phone Number', _phone, Icons.phone_outlined),
                    const SizedBox(height: 15),
                    _inputField('Password', _password, Icons.lock_outline, obscure: true),
                    const SizedBox(height: 25),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _register,
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: _loading ? const CircularProgressIndicator(color: Colors.black) : const Text('Sign Up', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Text("Already have an account? ", style: TextStyle(color: Colors.white70)),
                      GestureDetector(onTap: () => Navigator.pushNamed(context, '/login'), child: const Text('Login', style: TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold))),
                    ]),
                  ]),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputField(String label, TextEditingController ctrl, IconData icon, {bool obscure = false}) {
    return TextField(
      controller: ctrl, obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label, labelStyle: const TextStyle(color: Colors.white60, fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.white60),
        filled: true, fillColor: Colors.white.withValues(alpha: 0.05),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFF59E0B))),
      ),
    );
  }
}