import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;


  Future<void> register(String username, String email, String password) async {
    UserCredential res = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);

    await _db.collection('users').doc(res.user!.uid).set({
      'uid': res.user!.uid,
      'username': username,
      'email': email,
      'isAdmin': false,
      'createdAt': DateTime.now(),
    });
  }

  Future<Map<String, dynamic>> login(String email, String password) async {

    UserCredential res = await _auth.signInWithEmailAndPassword(
        email: email, password: password);

    DocumentSnapshot userDoc = await _db.collection('users').doc(res.user!.uid).get();
    Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', res.user!.uid);
    await prefs.setBool('isAdmin', userData['isAdmin'] ?? false);

    return userData;
  }
}